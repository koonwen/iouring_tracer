open Driver

(* TODO:
   - Pointers don't appear in the arguments as they should
   - Add better views to flags
   - Add rest of the tracepoints
*)

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
  | B.IO_URING_REGISTER ->
      let t = getf event Event.io_uring_register |> B.unload_register in
      W.instant_event writer.fxt ~name:"io_uring_register"
        ~thread:W.{ pid; tid }
        ~category:"uring" ~ts
        ~args:
          [
            ("ring_ctx", `Pointer (Int64.of_nativeint t.ctx));
            ("opcode", `Int64 (Int64.of_int32 t.opcode));
            ("nr_files", `Int64 (Int64.of_int32 t.nr_files));
            ("nr_bufs", `Int64 (Int64.of_int32 t.nr_bufs));
            ("ret", `Int64 t.ret);
          ]
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
      RW.flow_event writer ~pid ~ring_ctx:t.ctx_ptr ~tid
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
  | B.IO_URING_TASK_ADD ->
      let t = getf event Event.io_uring_task_add |> B.unload_task_add in
      let req_ptr = t.req_ptr |> Int64.of_nativeint in
      RW.flow_event writer ~pid ~ring_ctx:t.ctx_ptr ~tid
        ~name:"io_uring_task_add" ~comm ~ts ~correlation_id:req_ptr
        ~args:
          [
            ("ring_ctx", `Pointer (Int64.of_nativeint t.ctx_ptr));
            ("req", `Pointer req_ptr);
            ("opcode", `Int64 (Int64.of_int t.opcode));
            ("mask", `Int64 (Int64.of_int t.mask));
            ("op_str", `String t.op_str);
          ]
  | B.IO_URING_POLL_ARM ->
      let t = getf event Event.io_uring_poll_arm |> B.unload_poll_arm in
      let req_ptr = t.req_ptr |> Int64.of_nativeint in
      RW.flow_event writer ~pid ~ring_ctx:t.ctx_ptr ~tid
        ~name:"io_uring_poll_arm" ~comm ~ts ~correlation_id:req_ptr
        ~args:
          [
            ("ring_ctx", `Pointer (Int64.of_nativeint t.ctx_ptr));
            ("req", `Pointer req_ptr);
            ("opcode", `Int64 (Int64.of_int t.opcode));
            ("mask", `Int64 (Int64.of_int t.mask));
            ("events", `Int64 (Int64.of_int t.events));
            ("op_str", `String t.op_str);
          ]
  | B.IO_URING_FILE_GET ->
      let t = getf event Event.io_uring_file_get |> B.unload_file_get in
      let req_ptr = t.req_ptr |> Int64.of_nativeint in
      RW.flow_event writer ~pid ~ring_ctx:t.ctx_ptr ~tid
        ~name:"io_uring_file_get" ~comm ~ts ~correlation_id:req_ptr
        ~args:
          [
            ("ring_ctx", `Pointer (Int64.of_nativeint t.ctx_ptr));
            ("req", `Pointer req_ptr);
            ("fd", `Int64 (Int64.of_int t.fd));
          ]
  | B.IO_URING_DEFER ->
      let t = getf event Event.io_uring_defer |> B.unload_defer in
      let req_ptr = t.req_ptr |> Int64.of_nativeint in
      RW.flow_event writer ~pid ~ring_ctx:t.ctx_ptr ~tid ~name:"io_uring_defer"
        ~comm ~ts ~correlation_id:req_ptr
        ~args:
          [
            ("ring_ctx", `Pointer (Int64.of_nativeint t.ctx_ptr));
            ("req", `Pointer (Int64.of_nativeint t.req_ptr));
            ("opcode", `Int64 (Int64.of_int t.opcode));
            ("op_str", `String t.op_str);
          ]
  | B.IO_URING_FAIL_LINK ->
      let t = getf event Event.io_uring_fail_link |> B.unload_fail_link in
      let req_ptr = t.req_ptr |> Int64.of_nativeint in
      RW.flow_event writer ~pid ~ring_ctx:t.ctx_ptr ~tid
        ~name:"io_uring_fail_link" ~comm ~ts ~correlation_id:req_ptr
        ~args:
          [
            ("ring_ctx", `Pointer (Int64.of_nativeint t.ctx_ptr));
            ("req", `Pointer (Int64.of_nativeint t.req_ptr));
            ("link_ptr", `Pointer (Int64.of_nativeint t.link_ptr));
            ("opcode", `Int64 (Int64.of_int t.opcode));
            ("op_str", `String t.op_str);
          ]
  | B.IO_URING_LINK ->
      let t = getf event Event.io_uring_link |> B.unload_link in
      let req_ptr = t.req_ptr |> Int64.of_nativeint in
      RW.flow_event writer ~pid ~ring_ctx:t.ctx_ptr ~tid ~name:"io_uring_link"
        ~comm ~ts ~correlation_id:req_ptr
        ~args:
          [
            ("ring_ctx", `Pointer (Int64.of_nativeint t.ctx_ptr));
            ("req", `Pointer (Int64.of_nativeint t.req_ptr));
            ("target_req", `Pointer (Int64.of_nativeint t.target_req_ptr));
          ]
  | B.IO_URING_REQ_FAILED ->
      let t = getf event Event.io_uring_req_failed |> B.unload_req_failed in
      let req_ptr = t.req_ptr |> Int64.of_nativeint in
      RW.flow_event writer ~pid ~ring_ctx:t.ctx_ptr ~tid
        ~name:"io_uring_req_failed" ~comm ~ts ~correlation_id:req_ptr
        ~args:
          [
            ("ring_ctx", `Pointer (Int64.of_nativeint t.ctx_ptr));
            ("req", `Pointer (Int64.of_nativeint t.req_ptr));
            ("opcode", `Int64 (Int64.of_int t.opcode));
            ("flags", `Int64 (Int64.of_int t.flags));
            ("ioprio", `Int64 (Int64.of_int t.ioprio));
            ("off", `Int64 t.off);
            ("addr", `Pointer t.addr);
            ("len", `Int64 (Int64.of_int t.len));
            ("op_flags", `Int64 (Int64.of_int t.op_flags));
            ("buf_index", `Int64 (Int64.of_int t.buf_index));
            ("personality", `Int64 (Int64.of_int t.personality));
            ("file_index", `Int64 (Int64.of_int t.file_index));
            ("pad1", `Int64 t.pad1);
            ("addr3", `Pointer t.addr3);
            ("error", `Int64 (Int64.of_int t.error));
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
  | B.IO_URING_SHORT_WRITE ->
      let t = getf event Event.io_uring_short_write |> B.unload_short_write in
      W.instant_event writer.fxt ~name:"io_uring_short_write"
        ~thread:W.{ pid; tid }
        ~category:"uring" ~ts
        ~args:
          [
            ("ring_ctx", `Pointer (Int64.of_nativeint t.ctx_ptr));
            ("fpos", `Int64 t.fpos);
            ("wanted", `Int64 t.wanted);
            ("got", `Int64 t.got);
          ]
  | B.IO_URING_TASK_WORK_RUN ->
      let t =
        getf event Event.io_uring_task_work_run |> B.unload_task_work_run
      in
      W.instant_event writer.fxt ~name:"io_uring_task_work_run"
        ~thread:W.{ pid; tid }
        ~category:"uring" ~ts
        ~args:
          [
            ("tctx", `Pointer (Int64.of_nativeint t.tctx_ptr));
            ("count", `Int64 (Int64.of_int t.count));
            ("loops", `Int64 (Int64.of_int t.loops));
          ]
  | B.IO_URING_LOCAL_WORK_RUN ->
      let t =
        getf event Event.io_uring_local_work_run |> B.unload_local_work_run
      in
      W.instant_event writer.fxt ~name:"io_uring_task_work_run"
        ~thread:W.{ pid; tid }
        ~category:"uring" ~ts
        ~args:
          [
            ("ring_ctx", `Pointer (Int64.of_nativeint t.ctx_ptr));
            ("count", `Int64 (Int64.of_int t.count));
            ("loops", `Int64 (Int64.of_int t.loops));
          ]
  | B.IO_URING_CQE_OVERFLOW ->
      let t = getf event Event.io_uring_cqe_overflow |> B.unload_cqe_overflow in
      W.instant_event writer.fxt ~name:"io_uring_cqe_overflow"
        ~thread:W.{ pid; tid }
        ~category:"uring" ~ts
        ~args:
          [
            ("ring_ctx", `Pointer (Int64.of_nativeint t.ctx_ptr));
            ("user_data", `Pointer t.user_data);
            ("res", `Int64 (Int64.of_int t.res));
            ("cflags", `Int64 (Int64.of_int t.cflags));
            ("ocqe_ptr", `Pointer (Int64.of_nativeint t.ocqe_ptr));
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
          ]);
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
    handle_event
