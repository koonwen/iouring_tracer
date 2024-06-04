open Ocaml_libbpf
module F = Primative.Functions
module T = Primative.Types
module W = Fxt.Write
module B = Bindings
module RW = Ring_writer

module CInt : Conv with type t = int = struct
  type t = int

  let c_type = Ctypes.int
  let empty = 0
end

module CLong : Conv with type t = Signed.Long.t = struct
  type t = Signed.Long.t

  let c_type = Ctypes.long
  let empty = Signed.Long.zero
end

module M = Bpf_maps.Make (CInt) (CLong)

type poll_behaviour = Poll of int | Busywait

exception Exit of int

type handler =
  Ring_writer.t -> unit Ctypes.ptr -> unit Ctypes.ptr -> Unsigned.size_t -> int

let pipeline (handlers : handler list) writer ctx data size_t =
  List.iter
    (fun handler ->
      match handler writer ctx data size_t with
      | 0 -> () (* result ok *)
      | e -> raise (Exit e))
    handlers;
  (* Return 0 *)
  0

let load_run ~poll_behaviour ~bpf_object_path ~bpf_program_names
    ~(writer : Ring_writer.t) handlers =
  (* Implicitly bump RLIMIT_MEMLOCK to create BPF maps *)
  F.libbpf_set_strict_mode T.LIBBPF_STRICT_AUTO_RLIMIT_MEMLOCK;

  (* Set signal handlers *)
  let exitting = ref true in
  let sig_handler = Sys.Signal_handle (fun _ -> exitting := false) in
  Sys.(set_signal sigint sig_handler);
  Sys.(set_signal sigterm sig_handler);

  (* Read BPF object *)
  let obj =
    match F.bpf_object__open bpf_object_path with
    | None ->
        Printf.eprintf "Failed to open BPF object\n";
        raise (Exit 1)
    | Some obj -> obj
  in

  at_exit (fun () -> F.bpf_object__close obj);

  (* Load BPF object *)
  if F.bpf_object__load obj = 1 then (
    Printf.eprintf "Failed to load BPF object\n";
    raise (Exit 1));

  (* Init global maps *)
  let globals =
    match bpf_object_find_map_by_name obj "globals" with
    | None ->
        Printf.eprintf "Failed to find globals map";
        raise (Exit 1)
    | Some map -> map
  in

  (* Find program by name *)
  let progs =
    let find_exn name =
      match F.bpf_object__find_program_by_name obj name with
      | None ->
          Printf.eprintf "Failed to find bpf program: %s\n" name;
          raise (Exit 1)
      | Some p -> p
    in
    List.map find_exn bpf_program_names
  in

  (* Attach tracepoint *)
  let links =
    let attach_exn prog =
      let link = F.bpf_program__attach prog in
      if F.libbpf_get_error (Ctypes.to_voidp link) <> Signed.Long.zero then (
        Printf.eprintf "Failed to attach BPF program\n";
        raise (Exit 1));
      link
    in
    List.map attach_exn progs
  in

  at_exit (fun () ->
      List.iter (fun link -> F.bpf_link__destroy link |> ignore) links);

  (* Load maps *)
  let map =
    match F.bpf_object__find_map_by_name obj "rb" with
    | None ->
        Printf.eprintf "Failed to find map";
        raise (Exit 1)
    | Some m -> m
  in
  let rb_fd = F.bpf_map__fd map in

  at_exit (fun () ->
      let total = M.bpf_map_lookup_value_op globals 1 |> Result.get_ok in
      let dropped = M.bpf_map_lookup_value_op globals 2 |> Result.get_ok in
      let unrelated = M.bpf_map_lookup_value_op globals 3 |> Result.get_ok in
      let skipped = M.bpf_map_lookup_value_op globals 4 |> Result.get_ok in
      let str_of_long clong =
        Ctypes_value_printing.string_of Ctypes.long clong
      in
      Printf.printf
        "Total events %s, Dropped events %s, Unrelated events %s, Skipped \
         events %s\n"
        (str_of_long total) (str_of_long dropped) (str_of_long skipped)
        (str_of_long unrelated));

  let handle_event_coerce =
    let open Ctypes in
    let handler = pipeline handlers in
    coerce
      (Foreign.funptr ~runtime_lock:true ~check_errno:true
         (ptr void @-> ptr void @-> size_t @-> returning int))
      T.ring_buffer_sample_fn (handler writer)
  in

  (* Set up ring buffer polling *)
  let rb =
    match
      F.ring_buffer__new rb_fd handle_event_coerce Ctypes.null
        Ctypes.(from_voidp T.ring_buffer_opts null)
    with
    | None ->
        Printf.eprintf "Failed to create ring buffer\n";
        raise (Exit 1)
    | Some rb -> rb
  in

  let cb = ref 0 in

  at_exit (fun () ->
      F.ring_buffer__free rb;
      Printf.printf "Consumed %d events\n%!" !cb);

  (* Something weird is happening, not sure why the events don't tally
     up *)
  let index i = Ctypes.allocate Ctypes.int i in
  let zero = Ctypes.allocate Ctypes.long Signed.Long.zero in
  let initialize_idx i =
    assert(F.Bpf.bpf_map_update_elem globals.fd
      (index i |> Ctypes.to_voidp)
      (Ctypes.to_voidp zero) Unsigned.UInt64.zero = 0)
  in
  (* Set all globals to zero, need to do this because we might
     encounter events before the ring buffer can be submitted to *)
  List.iter initialize_idx [0;1;2;3;4];


  (match poll_behaviour with
  | Poll timeout ->
      while !exitting do
        let err = F.ring_buffer__poll rb timeout in
        match err with
        | e when e = Sys.sighup -> raise (Exit 0)
        | e when e < 0 ->
            Printf.eprintf "Error polling ring buffer, %d\n" e;
            raise (Exit 1)
        | i -> cb := !cb + i
      done
  | Busywait -> (
      match F.ring_buffer__consume rb with
      | i when i >= 0 -> cb := !cb + i
      | e when e = Sys.sighup -> raise (Exit 0)
      | e ->
          Printf.eprintf "Error polling ring buffer, %d\n" e;
          raise (Exit 1)));
  raise (Exit 0)

let run ?(tracefile = "trace.fxt") ?(poll_behaviour = Poll 100) ~bpf_object_path
    ~bpf_program_names handlers =
  Eio_linux.run @@ fun env ->
  Eio.Switch.run (fun sw ->
      let output_file = Eio.Path.( / ) (Eio.Stdenv.cwd env) tracefile in
      let out =
        Eio.Path.open_out ~sw ~create:(`Or_truncate 0o644) output_file
      in
      Eio.Buf_write.with_flow out (fun w ->
          let writer = Ring_writer.make (W.of_writer w) in
          try
            load_run ~poll_behaviour ~bpf_object_path ~bpf_program_names ~writer
              handlers
          with Exit i -> Printf.eprintf "exit %d\n" i))
