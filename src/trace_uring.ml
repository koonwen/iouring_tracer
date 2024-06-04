open Driver

(* Describe event handler *)
let handle_event (writer : RW.t) _ctx data _size =
  let open Ctypes in
  let module Event = B.Struct_event in
  let event = !@(from_voidp Event.t data) in
  let pid = getf event Event.pid |> Int64.of_int in
  let tid = getf event Event.tid |> Int64.of_int in
  let comm = getf event Event.comm |> B.char_array_as_string in
  let ts = getf event Event.ts |> Unsigned.UInt64.to_int64 in
  (match getf event Event.ty with
  | ( B.SYS_ENTER_IO_URING_ENTER | B.SYS_ENTER_IO_URING_REGISTER
    | B.SYS_ENTER_IO_URING_SETUP ) as ev ->
      W.duration_begin writer.fxt ~name:(B.show_tracepoint_t ev)
        ~thread:W.{ pid; tid }
        ~category:"syscalls" ~ts
  | ( B.SYS_EXIT_IO_URING_ENTER | B.SYS_EXIT_IO_URING_REGISTER
    | B.SYS_EXIT_IO_URING_SETUP ) as ev ->
      W.duration_end writer.fxt ~name:(B.show_tracepoint_t ev)
        ~thread:W.{ pid; tid }
        ~category:"syscalls" ~ts
  (* Tracepoints *)
  | B.IO_URING_CREATE ->
      let t = getf event Event.io_uring_create |> B.unload_create in
      Driver.RW.create_event writer ~pid ~ring_fd:t.fd ~ring_ctx:t.ctx_ptr ~tid
        ~name:"io_uring_create" ~comm ~ts
  | B.IO_URING_SUBMIT_SQE ->
      let t = getf event Event.io_uring_submit_sqe |> B.unload_submit_sqe in
      let req_ptr = t.req_ptr |> Int64.of_nativeint in
      RW.submission_event writer ~pid ~ring_ctx:t.ctx_ptr ~tid
        ~name:"io_uring_submit" ~comm ~ts ~correlation_id:req_ptr
        ~args:
          [
            ("ring_ctx", `Pointer (Int64.of_nativeint t.ctx_ptr));
            ("req", `Pointer req_ptr);
            ("op_str", `String t.op_str);
            ("opcode", `Int64 (Int64.of_int t.opcode));
            ("flags", `Int64 (Int64.of_int t.flags));
            ("force_nonblock", `String (Bool.to_string t.force_nonblock));
            ("sq_thread", `String (Bool.to_string t.sq_thread));
          ]
  | B.IO_URING_QUEUE_ASYNC_WORK ->
      let t =
        getf event Event.io_uring_queue_async_work |> B.unload_queue_async_work
      in
      let req_ptr = t.req_ptr |> Int64.of_nativeint in
      RW.async_work_event writer ~pid ~ring_ctx:t.ctx_ptr ~tid
        ~name:"io_uring_queue_async_work" ~comm ~ts ~correlation_id:req_ptr
        ~args:
          [
            ("ring_ctx", `Pointer (Int64.of_nativeint t.ctx_ptr));
            ("req", `Pointer req_ptr);
            ("opcode", `Int64 (Int64.of_int t.opcode));
            ("flags", `Int64 (Int64.of_int32 t.flags));
            ("work_ptr", `Pointer t.work_ptr);
            ("op_str", `String t.op_str);
          ]
  | B.IO_URING_COMPLETE ->
      let t = getf event Event.io_uring_complete |> B.unload_complete in
      let req_ptr = t.req_ptr |> Int64.of_nativeint in
      RW.completion_event writer ~pid ~ring_ctx:t.ctx_ptr ~tid
        ~name:"io_uring_complete" ~comm ~ts ~correlation_id:req_ptr
        ~args:
          [
            ("ring_ctx", `Pointer (Int64.of_nativeint t.ctx_ptr));
            ("req", `Pointer req_ptr);
            ("res", `Int64 (Int64.of_int t.res));
            ("cflags", `Int64 (Int64.of_int t.cflags));
          ]
  | B.IO_URING_CQRING_WAIT ->
      let t = getf event Event.io_uring_cqring_wait |> B.unload_cqring_wait in
      W.instant_event writer.fxt ~name:"io_uring_cqring_wait"
        ~thread:W.{ pid; tid }
        ~category:"uring" ~ts
        ~args:
          [
            ("ring_ctx", `Pointer (Int64.of_nativeint t.ctx_ptr));
            ("min_events", `Int64 (Int64.of_int t.min_events));
          ]
  | _ -> ());
  0

let () =
  run ~bpf_object_path:"uring.bpf.o"
    ~bpf_program_names:
      [
        "handle_create";
        "handle_register";
        "handle_file_get";
        "handle_submit_sqe";
        "handle_queue_async_work";
        "handle_poll_arm";
        "handle_task_add";
        "handle_task_work_run";
        "handle_short_write";
        "handle_local_work_run";
        "handle_defer";
        "handle_link";
        "handle_fail_link";
        "handle_cqring_wait";
        "handle_req_failed";
        "handle_cqe_overflow";
        "handle_complete";
        "handle_sys_enter_io_uring_setup";
        "handle_sys_exit_io_uring_setup";
        "handle_sys_enter_io_uring_register";
        "handle_sys_exit_io_uring_register";
        "handle_sys_enter_io_uring_enter";
        "handle_sys_exit_io_uring_enter";
      ]
    [ handle_event ]
