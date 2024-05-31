open Ocaml_libbpf
module F = Libbpf.Functions
module T = Libbpf.Types
module W = Fxt.Write
module B = Bindings

type poll_behaviour = Poll of int | Busywait

exception Exit of int

type handler = unit Ctypes.ptr -> unit Ctypes.ptr -> Unsigned.size_t -> int

let pipeline (handlers : handler list) ctx data size_t =
  List.iter
    (fun handler ->
      match handler ctx data size_t with
      | 0 -> () (* result ok *)
      | e -> raise (Exit e))
    handlers;
  (* Return 0 *)
  0

let load_run ~poll_behaviour ~bpf_object_path ~bpf_program_names handlers =
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
      match F.bpf_object__find_map_by_name obj "globals" with
      | None -> Printf.eprintf "Failed to find globals map"
      | Some counter -> (
          let open Ctypes in
          let sz_key = Ctypes.(sizeof int |> Unsigned.Size_t.of_int) in
          let sz_value = Ctypes.(sizeof long |> Unsigned.Size_t.of_int) in
          let key = Ctypes.(allocate int 0) in
          let value_cnt = Ctypes.(allocate long Signed.Long.zero) in
          let flags = Unsigned.UInt64.zero in
          let counter =
            F.bpf_map__lookup_elem counter (to_voidp key) sz_key
              (to_voidp value_cnt) sz_value flags
          in
          if counter <> 0 then
            Printf.eprintf "Failed to lookup element got %d\n" counter
          else
            match !@value_cnt with
            | i when i = Signed.Long.zero -> ()
            | i ->
                Printf.eprintf
                  "Failed to reserve space in Ringbuf, Dropped events %s\n"
                  (Ctypes_value_printing.string_of long i)));

  let handle_event_coerce =
    let open Ctypes in
    let handler = pipeline handlers in
    coerce
      (Foreign.funptr ~runtime_lock:true ~check_errno:true
         (ptr void @-> ptr void @-> size_t @-> returning int))
      T.ring_buffer_sample_fn handler
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
      Printf.printf "Consumed %d events\n" !cb);

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
          let _fxt = W.of_writer w in
          try
            load_run ~poll_behaviour ~bpf_object_path ~bpf_program_names
              handlers
          with Exit i -> Printf.eprintf "exit %d%!" i))
