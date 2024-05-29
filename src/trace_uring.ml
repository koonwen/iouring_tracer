open Ocaml_libbpf
module F = Libbpf.Functions
module T = Libbpf.Types
module W = Fxt.Write
module D = Definitions

exception Exit of int

(* Describe event handler *)
let handle_event (rw : Ring_writer.t) _ctx data _size =
  let open Ctypes in
  let event = !@(from_voidp D.struct_event data) in
  let pid = getf event D.pid |> Int64.of_int in
  let tid = getf event D.tid |> Int64.of_int in
  let comm = getf event D.comm |> D.char_array_as_string in
  let ts = getf event D.ts |> Unsigned.UInt64.to_int64 in
  let u = getf event D.ufield in
  (match getf event D.t with
  | D.SYS_ENTER_IO_URING_ENTER ->
      Ring_writer.sys_enter_start_event rw ~pid ~tid ~name:"IO_URING_ENTER"
        ~comm ~ts
  | D.SYS_EXIT_IO_URING_ENTER ->
      Ring_writer.sys_enter_end_event rw ~pid ~tid ~name:"IO_URING_EXIT" ~comm
        ~ts
  (* Tracepoints *)
  | D.IO_URING_CREATE -> ()
  | D.IO_URING_SUBMIT_SQE ->
      let t =
        getf u D.io_uring_submit_sqe |> D.Struct_io_uring_submit_sqe.unload
      in
      Ring_writer.submission_event rw ~pid ~tid ~name:t.op_str ~comm ~ts
        ~correlation_id:t.req_ptr
        ~args:
          [
            ("req", `Pointer t.req_ptr);
            ("opcode", `Int64 (Int64.of_int t.opcode));
            ("flags", `Int64 (Int64.of_int t.flags));
            ("force_nonblock", `String (Bool.to_string t.force_nonblock));
            ("sq_thread", `String (Bool.to_string t.sq_thread));
          ]
  | D.IO_URING_QUEUE_ASYNC_WORK ->
      let t =
        getf u D.io_uring_queue_async_work
        |> D.Struct_io_uring_queue_async_work.unload
      in
      Ring_writer.async_work_event rw ~pid ~tid ~name:"queue_async_work" ~comm
        ~ts ~correlation_id:t.req_ptr
        ~args:
          [
            ("opcode", `Int64 (Int64.of_int t.opcode));
            ("flags", `Int64 (Int64.of_int32 t.flags));
            ("work_ptr", `Pointer t.work_ptr);
            ("op_str", `String t.op_str);
          ]
  | D.IO_URING_COMPLETE ->
      let t = getf u D.io_uring_complete |> D.Struct_io_uring_complete.unload in
      Ring_writer.completion_event rw ~pid ~tid ~name:"complete" ~comm ~ts
        ~correlation_id:t.req_ptr
        ~args:
          [
            ("req", `Pointer t.req_ptr);
            ("res", `Int64 (Int64.of_int t.res));
            ("cflags", `Int64 (Int64.of_int32 t.cflags));
          ]);
  0

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
    match F.bpf_object__open "uring.bpf.o" with
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
      "handle_create";
      "handle_submit";
      "handle_queue_async_work";
      "handle_complete";
      "handle_sys_enter_io_uring_enter";
      "handle_sys_exit_io_uring_enter";
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

  let handle_event =
    Ctypes.(
      coerce
        (Foreign.funptr ~runtime_lock:true ~check_errno:true
           (ptr void @-> ptr void @-> size_t @-> returning int))
        T.ring_buffer_sample_fn handle_event)
  in

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

  let cb = ref 0 in

  at_exit (fun () -> Printf.printf "Consumed %d events\n" !cb);

  while !exitting do
    let err = F.ring_buffer__poll rb 100 in
    match err with
    | e when e = Sys.sighup -> raise (Exit 0)
    | e when e < 0 ->
        Printf.eprintf "Error polling ring buffer, %d\n" e;
        raise (Exit 1)
    | i -> cb := !cb + i
    (* match F.ring_buffer__consume rb with *)
    (* | i when i >= 0 -> cb := !cb + i *)
    (* | e when e = Sys.sighup -> raise (Exit 0) *)
    (* | e -> *)
    (*     Printf.eprintf "Error polling ring buffer, %d\n" e; *)
    (*     raise (Exit 1) *)
  done;

  raise (Exit 0)

let () =
  Eio_linux.run @@ fun env ->
  Eio.Switch.run (fun sw ->
      let tracefile = Eio.Path.( / ) (Eio.Stdenv.cwd env) "trace.fxt" in
      let out = Eio.Path.open_out ~sw ~create:(`Or_truncate 0o644) tracefile in
      Eio.Buf_write.with_flow out (fun w ->
          let fxt = W.of_writer w in
          let t = Ring_writer.make fxt in
          try run (handle_event t)
          with Exit i -> Printf.printf "Exit %d\n%!" i))
