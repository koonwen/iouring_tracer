open Ocaml_libbpf
module F = Libbpf.Functions
module T = Libbpf.Types
module W = Fxt.Write
module D = Definitions

exception Exit of int

type handler =
  unit Ctypes_static.ptr ->
  unit Ctypes_static.ptr ->
  Unsigned.size_t ->
  W.t ->
  int

let pipeline fxt (handlers : handler list) ctx data size_t =
  List.iter
    (fun handler ->
      match handler ctx data size_t fxt with
      | 0 -> () (* result ok *)
      | e -> raise (Exit e))
    handlers;
  (* Return 0 *)
  0

let event_loop ~bpf_object_path ~program_names handlers fxt =
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
    List.map find_exn program_names
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

  let handle_event_coerce =
    let open Ctypes in
    let handler = pipeline fxt handlers in
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

  at_exit (fun () -> F.ring_buffer__free rb);

  while !exitting do
    let err = F.ring_buffer__poll rb 100 in
    match err with
    | e when e = Sys.sighup -> raise (Exit 0)
    | e when e < 0 ->
        Printf.eprintf "Error polling ring buffer, %d\n" e;
        raise (Exit 1)
    | _ -> ()
  done

let event_loop_run ?(tracefile="trace.fxt") ~bpf_object_path ~program_names handlers =
  Eio_linux.run @@ fun env ->
  Eio.Switch.run (fun sw ->
      let output_file = Eio.Path.( / ) (Eio.Stdenv.cwd env) tracefile in
      let out = Eio.Path.open_out ~sw ~create:(`Or_truncate 0o644) output_file in
      Eio.Buf_write.with_flow out (fun w ->
          let fxt = W.of_writer w in
          try event_loop ~bpf_object_path ~program_names handlers fxt
          with Exit i -> Printf.eprintf "exit %d%!" i))
