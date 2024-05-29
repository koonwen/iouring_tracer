module Bindings (T : Ctypes.TYPE) = struct
  open T

  let task_comm_len = constant "TASK_COMM_LEN" int
  let max_op_str_len = constant "MAX_OP_STR_LEN" int

  let io_uring_create = constant "IO_URING_CREATE" int64_t
  and io_uring_submit_sqe = constant "IO_URING_SUBMIT_SQE" int64_t
  and io_uring_queue_async_work = constant "IO_URING_QUEUE_ASYNC_WORK" int64_t
  and io_uring_complete = constant "IO_URING_COMPLETE" int64_t
  and sys_enter_io_uring_enter = constant "SYS_ENTER_IO_URING_ENTER" int64_t
  and sys_exit_io_uring_enter = constant "SYS_EXIT_IO_URING_ENTER" int64_t

  type tracepoint_t =
    | IO_URING_CREATE
    | IO_URING_SUBMIT_SQE
    | IO_URING_QUEUE_ASYNC_WORK
    | IO_URING_COMPLETE
    | SYS_ENTER_IO_URING_ENTER
    | SYS_EXIT_IO_URING_ENTER

  let enum_tracepoint_t =
    enum "tracepoint_t"
      [
        (IO_URING_CREATE, io_uring_create);
        (IO_URING_SUBMIT_SQE, io_uring_submit_sqe);
        (IO_URING_QUEUE_ASYNC_WORK, io_uring_queue_async_work);
        (IO_URING_COMPLETE, io_uring_complete);
        (SYS_ENTER_IO_URING_ENTER, sys_enter_io_uring_enter);
        (SYS_EXIT_IO_URING_ENTER, sys_exit_io_uring_enter);
      ]
end
