module Bindings (T : Ctypes.TYPE) = struct
  open T

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

  type span_t = BEGIN | END | NONE [@@deriving show { with_path = false }]

  let begin' = constant "BEGIN" int64_t
  and end' = constant "END" int64_t

  let span_t =
    enum ~typedef:true "span_t"
      ~unexpected:(fun _ -> NONE)
      [ (BEGIN, begin'); (END, end') ]

  let task_comm_len = constant "TASK_COMM_LEN" int
end
