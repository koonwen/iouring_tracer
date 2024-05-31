(* Add some views for flags to display nicely? *)
module Bindings (T : Ctypes.TYPE) = struct
  open T

  let task_comm_len = constant "TASK_COMM_LEN" int
  let max_op_str_len = constant "MAX_OP_STR_LEN" int

  let io_uring_create = constant "IO_URING_CREATE" int64_t
  and io_uring_register = constant "IO_URING_REGISTER" int64_t
  and io_uring_file_get = constant "IO_URING_FILE_GET" int64_t
  and io_uring_submit_sqe = constant "IO_URING_SUBMIT_SQE" int64_t
  and io_uring_queue_async_work = constant "IO_URING_QUEUE_ASYNC_WORK" int64_t
  and io_uring_poll_arm = constant "IO_URING_POLL_ARM" int64_t
  and io_uring_task_add = constant "IO_URING_TASK_ADD" int64_t
  and io_uring_task_work_run = constant "IO_URING_TASK_WORK_RUN" int64_t
  and io_uring_short_write = constant "IO_URING_SHORT_WRITE" int64_t
  and io_uring_local_work_run = constant "IO_URING_LOCAL_WORK_RUN" int64_t
  and io_uring_defer = constant "IO_URING_DEFER" int64_t
  and io_uring_link = constant "IO_URING_LINK" int64_t
  and io_uring_fail_link = constant "IO_URING_FAIL_LINK" int64_t
  and io_uring_cqring_wait = constant "IO_URING_CQRING_WAIT" int64_t
  and io_uring_req_failed = constant "IO_URING_REQ_FAILED" int64_t
  and io_uring_cqe_overflow = constant "IO_URING_CQE_OVERFLOW" int64_t
  and io_uring_complete = constant "IO_URING_COMPLETE" int64_t
  and sys_enter_io_uring_enter = constant "SYS_ENTER_IO_URING_ENTER" int64_t
  and sys_exit_io_uring_enter = constant "SYS_EXIT_IO_URING_ENTER" int64_t

  type tracepoint_t =
    | IO_URING_CREATE
    | IO_URING_REGISTER
    | IO_URING_FILE_GET
    | IO_URING_SUBMIT_SQE
    | IO_URING_QUEUE_ASYNC_WORK
    | IO_URING_POLL_ARM
    | IO_URING_TASK_ADD
    | IO_URING_TASK_WORK_RUN
    | IO_URING_SHORT_WRITE
    | IO_URING_LOCAL_WORK_RUN
    | IO_URING_DEFER
    | IO_URING_LINK
    | IO_URING_FAIL_LINK
    | IO_URING_CQRING_WAIT
    | IO_URING_REQ_FAILED
    | IO_URING_CQE_OVERFLOW
    | IO_URING_COMPLETE
    | SYS_ENTER_IO_URING_ENTER
    | SYS_EXIT_IO_URING_ENTER

  let enum_tracepoint_t =
    enum "tracepoint_t"
      [
        (IO_URING_CREATE, io_uring_create);
        (IO_URING_REGISTER, io_uring_register);
        (IO_URING_FILE_GET, io_uring_file_get);
        (IO_URING_SUBMIT_SQE, io_uring_submit_sqe);
        (IO_URING_QUEUE_ASYNC_WORK, io_uring_queue_async_work);
        (IO_URING_POLL_ARM, io_uring_poll_arm);
        (IO_URING_TASK_ADD, io_uring_task_add);
        (IO_URING_TASK_WORK_RUN, io_uring_task_work_run);
        (IO_URING_SHORT_WRITE, io_uring_short_write);
        (IO_URING_LOCAL_WORK_RUN, io_uring_local_work_run);
        (IO_URING_DEFER, io_uring_defer);
        (IO_URING_LINK, io_uring_link);
        (IO_URING_FAIL_LINK, io_uring_fail_link);
        (IO_URING_CQRING_WAIT, io_uring_cqring_wait);
        (IO_URING_REQ_FAILED, io_uring_req_failed);
        (IO_URING_CQE_OVERFLOW, io_uring_cqe_overflow);
        (IO_URING_COMPLETE, io_uring_complete);
        (SYS_ENTER_IO_URING_ENTER, sys_enter_io_uring_enter);
        (SYS_EXIT_IO_URING_ENTER, sys_exit_io_uring_enter);
      ]
end
