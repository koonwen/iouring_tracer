module Bindings (T : Ctypes.TYPE) = struct
  open T

  type probe_t = TRACEPOINT | SYSCALL

  let tracepoint = constant "TRACEPOINT" int64_t
  and syscall = constant "SYSCALL" int64_t

  let probe_t =
    enum ~typedef:true "probe_t"
      [ (TRACEPOINT, tracepoint); (SYSCALL, syscall) ]

  type tracepoints_t =
    | IO_URING_COMPLETE
    | IO_URING_CQE_OVERFLOW
    | IO_URING_CQRING_WAIT
    | IO_URING_CREATE
    | IO_URING_DEFER
    | IO_URING_FAIL_LINK
    | IO_URING_FILE_GET
    | IO_URING_LINK
    | IO_URING_LOCAL_WORK_RUN
    | IO_URING_POLL_ARM
    | IO_URING_QUEUE_ASYNC_WORK
    | IO_URING_REGISTER
    | IO_URING_REQ_FAILED
    | IO_URING_SHORT_WRITE
    | IO_URING_SUBMIT_SQE
    | IO_URING_TASK_ADD
    | IO_URING_TASK_WORK_RUN
  [@@deriving show { with_path = false }, enum]

  let io_uring_complete = constant "IO_URING_COMPLETE" int64_t
  and io_uring_cqe_overflow = constant "IO_URING_CQE_OVERFLOW" int64_t
  and io_uring_cqring_wait = constant "IO_URING_CQRING_WAIT" int64_t
  and io_uring_create = constant "IO_URING_CREATE" int64_t
  and io_uring_defer = constant "IO_URING_DEFER" int64_t
  and io_uring_fail_link = constant "IO_URING_FAIL_LINK" int64_t
  and io_uring_file_get = constant "IO_URING_FILE_GET" int64_t
  and io_uring_link = constant "IO_URING_LINK" int64_t
  and io_uring_local_work_run = constant "IO_URING_LOCAL_WORK_RUN" int64_t
  and io_uring_poll_arm = constant "IO_URING_POLL_ARM" int64_t
  and io_uring_queue_async_work = constant "IO_URING_QUEUE_ASYNC_WORK" int64_t
  and io_uring_register = constant "IO_URING_REGISTER" int64_t
  and io_uring_req_failed = constant "IO_URING_REQ_FAILED" int64_t
  and io_uring_short_write = constant "IO_URING_SHORT_WRITE" int64_t
  and io_uring_submit_sqe = constant "IO_URING_SUBMIT_SQE" int64_t
  and io_uring_task_add = constant "IO_URING_TASK_ADD" int64_t
  and io_uring_task_work_run = constant "IO_URING_TASK_WORK_RUN" int64_t

  let tracepoints_t =
    enum ~typedef:true "tracepoint_t"
      [
        (IO_URING_COMPLETE, io_uring_complete);
        (IO_URING_CQE_OVERFLOW, io_uring_cqe_overflow);
        (IO_URING_CQRING_WAIT, io_uring_cqring_wait);
        (IO_URING_CREATE, io_uring_create);
        (IO_URING_DEFER, io_uring_defer);
        (IO_URING_FAIL_LINK, io_uring_fail_link);
        (IO_URING_FILE_GET, io_uring_file_get);
        (IO_URING_LINK, io_uring_link);
        (IO_URING_LOCAL_WORK_RUN, io_uring_local_work_run);
        (IO_URING_POLL_ARM, io_uring_poll_arm);
        (IO_URING_QUEUE_ASYNC_WORK, io_uring_queue_async_work);
        (IO_URING_REGISTER, io_uring_register);
        (IO_URING_REQ_FAILED, io_uring_req_failed);
        (IO_URING_SHORT_WRITE, io_uring_short_write);
        (IO_URING_SUBMIT_SQE, io_uring_submit_sqe);
        (IO_URING_TASK_ADD, io_uring_task_add);
        (IO_URING_TASK_WORK_RUN, io_uring_task_work_run);
      ]

  type syscalls_t =
    | SYS_IO_URING_SETUP
    | SYS_IO_URING_REGISTER
    | SYS_IO_URING_ENTER
  [@@deriving show { with_path = false }, enum]

  let sys_io_uring_setup = constant "SYS_IO_URING_SETUP" int64_t
  and sys_io_uring_register = constant "SYS_IO_URING_REGISTER" int64_t
  and sys_io_uring_enter = constant "SYS_IO_URING_ENTER" int64_t

  let syscalls_t =
    enum ~typedef:true "syscalls_t"
      [
        (SYS_IO_URING_SETUP, sys_io_uring_setup);
        (SYS_IO_URING_REGISTER, sys_io_uring_register);
        (SYS_IO_URING_ENTER, sys_io_uring_enter);
      ]

  type span_t = BEGIN | END | NONE

  let begin' = constant "BEGIN" int64_t
  and end' = constant "END" int64_t

  let span_t =
    enum ~typedef:true "span_t" ~unexpected:(fun _ -> NONE)
      [ (BEGIN, begin'); (END, end') ]

  let task_comm_len = constant "TASK_COMM_LEN" int
end
