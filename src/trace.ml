open Ocaml_libbpf
module F = Libbpf.Functions
module T = Libbpf.Types
module W = Fxt.Write
module D = Definitions

exception Exit of int

(* Describe event handler *)
let handle_event fxt =
  let open Ctypes in
  let _handle_event _ctx data _sz =
    let event = !@(from_voidp D.struct_event data) in
    let pid = getf event D.pid |> Int64.of_int in
    let probe_t = getf event D.probe in
    let probe_id = getf event D.probe_id in
    let span = getf event D.span in
    let ts = getf event D.ktime_ns |> Signed.Long.to_int64 in
    let comm = getf event D.comm |> D.char_array_as_string in
    let thread =
      { Fxt.Write.pid; tid = Thread.self () |> Thread.id |> Int64.of_int }
    in
    (match probe_t with
    | D.TRACEPOINT ->
        let name =
          D.show_tracepoints_t (D.tracepoints_t_of_enum probe_id |> Option.get)
        in
        W.instant_event fxt ~name ~category:"bpf" ~thread ~ts
    | D.SYSCALL -> (
        let name =
          D.show_syscalls_t (D.syscalls_t_of_enum probe_id |> Option.get)
        in
        match span with
        | D.BEGIN -> W.duration_begin fxt ~name ~category:"bpf" ~thread ~ts
        | D.END -> W.duration_end fxt ~name ~category:"bpf" ~thread ~ts
        | D.NONE -> failwith "Unexpected value of span enum"));
    Printf.printf "Handle_event called from %s\n%!" comm;
    0
  in
  coerce
    (Foreign.funptr ~runtime_lock:true ~check_errno:true
       (ptr void @-> ptr void @-> size_t @-> returning int))
    T.ring_buffer_sample_fn _handle_event

let run handle_event =
  (* Implicitly bump RLIMIT_MEMLOCK to create BPF maps *)
  F.libbpf_set_strict_mode T.LIBBPF_STRICT_AUTO_RLIMIT_MEMLOCK;

  (* Set signal handlers *)
  let exitting = ref true in
  let sig_handler = Sys.Signal_handle (fun _ -> exitting := false) in
  Sys.(set_signal sigint sig_handler);
  Sys.(set_signal sigterm sig_handler);

  (* Read BPF object *)
  let obj =
    match F.bpf_object__open "trace_uring.bpf.o" with
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

  let program_names =
    [
      "handle_complete";
      "handle_cqe_overflow";
      "handle_fail_link";
      "handle_file_get";
      "handle_link";
      "handle_local_work_run";
      "handle_poll_arm";
      "handle_queue_async_work";
      "handle_register";
      "handle_req_failed";
      "handle_short_write";
      "handle_submit_sqe";
      "handle_task_add";
      "handle_task_work_run";
      "handle_sys_exit_io_uring_register";
      "handle_sys_enter_io_uring_register";
      "handle_sys_exit_io_uring_setup";
      "handle_sys_enter_io_uring_setup";
      "handle_sys_exit_io_uring_enter";
      "handle_sys_enter_io_uring_enter";
    ]
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

  (* Set up ring buffer polling *)
  let rb =
    match
      F.ring_buffer__new rb_fd handle_event Ctypes.null
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

let () =
  Eio_linux.run @@ fun env ->
  Eio.Switch.run (fun sw ->
      let tracefile = Eio.Path.( / ) (Eio.Stdenv.cwd env) "trace.fxt" in
      let out = Eio.Path.open_out ~sw ~create:(`Or_truncate 0o644) tracefile in
      Eio.Buf_write.with_flow out (fun w ->
          let fxt = W.of_writer w in
          try run (handle_event fxt)
          with Exit i -> Printf.eprintf "exit %d%!" i))
