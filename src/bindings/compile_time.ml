(* Add some views for flags to display nicely? *)
module Bindings (T : Cstubs_structs.TYPE) = struct
  open T

  (* Since we can't get the definitions prior to using them in
     structs, we will have to manually write them and assert they are
     the same after they are generated *)
  module Defines = struct
    let task_comm_len = 16
    let max_op_str_len = 127
  end

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
  and sys_enter_io_uring_setup = constant "SYS_ENTER_IO_URING_SETUP" int64_t
  and sys_exit_io_uring_setup = constant "SYS_EXIT_IO_URING_SETUP" int64_t

  and sys_enter_io_uring_register =
    constant "SYS_ENTER_IO_URING_REGISTER" int64_t

  and sys_exit_io_uring_register = constant "SYS_EXIT_IO_URING_REGISTER" int64_t
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
    | SYS_ENTER_IO_URING_SETUP
    | SYS_EXIT_IO_URING_SETUP
    | SYS_ENTER_IO_URING_REGISTER
    | SYS_EXIT_IO_URING_REGISTER
    | SYS_ENTER_IO_URING_ENTER
    | SYS_EXIT_IO_URING_ENTER
  [@@deriving show { with_path = false }]

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
        (SYS_ENTER_IO_URING_SETUP, sys_enter_io_uring_setup);
        (SYS_EXIT_IO_URING_SETUP, sys_exit_io_uring_setup);
        (SYS_ENTER_IO_URING_REGISTER, sys_enter_io_uring_register);
        (SYS_EXIT_IO_URING_REGISTER, sys_exit_io_uring_register);
        (SYS_ENTER_IO_URING_ENTER, sys_enter_io_uring_enter);
        (SYS_EXIT_IO_URING_ENTER, sys_exit_io_uring_enter);
      ]

  module Struct_io_uring_create = struct
    type t = {
      fd : int;
      ctx_ptr : nativeint;
      sq_entries : int32;
      cq_entries : int32;
      flags : int32;
    }

    let t = structure "io_uring_create"
    let ( -: ) ty label = field t label ty
    let fd = int -: "fd"
    let ctx = ptr void -: "ctx"
    let sq_entries = uint32_t -: "sq_entries"
    let cq_entries = uint32_t -: "cq_entries"
    let flags = uint32_t -: "flags"
    let _ = seal (t : t Ctypes.structure typ)
  end

  module Struct_io_uring_register = struct
    type t = {
      ctx : nativeint;
      opcode : int32;
      nr_files : int32;
      nr_bufs : int32;
      ret : int64;
    }

    let t = structure "io_uring_register"
    let ( -: ) ty label = field t label ty
    let ctx = ptr void -: "ctx"
    let opcode = uint32_t -: "opcode"
    let nr_files = uint32_t -: "nr_files"
    let nr_bufs = uint32_t -: "nr_bufs"
    let ret = int64_t -: "ret"
    let _ = seal (t : t Ctypes.structure typ)
  end

  module Struct_io_uring_file_get = struct
    type t = { ctx_ptr : nativeint; req_ptr : nativeint; fd : int }

    let t = structure "io_uring_file_get"
    let ( -: ) ty label = field t label ty
    let ctx = ptr void -: "ctx"
    let req = ptr void -: "req"
    let fd = int -: "fd"
    let _ = seal (t : t Ctypes.structure typ)
  end

  module Struct_io_uring_submit_sqe = struct
    type t = {
      ctx_ptr : nativeint;
      req_ptr : nativeint;
      opcode : int;
      flags : int;
      force_nonblock : bool;
      sq_thread : bool;
      op_str : string;
    }

    let t = structure "io_uring_submit_sqe"
    let ( -: ) ty label = field t label ty
    let ctx = ptr void -: "ctx"
    let req = ptr void -: "req"
    let opcode = uchar -: "opcode"
    let flags = ulong -: "flags"
    let force_nonblock = bool -: "force_nonblock"
    let sq_thread = bool -: "sq_thread"
    let op_str = array Defines.max_op_str_len char -: "op_str"
    let _ = seal (t : t Ctypes.structure typ)
  end

  module Struct_io_uring_queue_async_work = struct
    type t = {
      ctx_ptr : nativeint;
      req_ptr : nativeint;
      opcode : int;
      flags : int32;
      work_ptr : int64;
      op_str : string;
    }

    let t = structure "io_uring_queue_async_work"
    let ( -: ) ty label = field t label ty
    let ctx = ptr void -: "ctx"
    let req = ptr void -: "req"
    let opcode = uchar -: "opcode"
    let flags = uint32_t -: "flags"
    let work = ptr void -: "work"
    let op_str = array Defines.max_op_str_len char -: "op_str"
    let _ = seal (t : t Ctypes.structure typ)
  end

  module Struct_io_uring_poll_arm = struct
    type t = {
      ctx_ptr : nativeint;
      req_ptr : nativeint;
      opcode : int;
      mask : int;
      events : int;
      op_str : string;
    }

    let t = structure "io_uring_poll_arm"
    let ( -: ) ty label = field t label ty
    let ctx = ptr void -: "ctx"
    let req = ptr void -: "req"
    let opcode = uchar -: "opcode"
    let mask = int -: "mask"
    let events = int -: "events"
    let op_str = array Defines.max_op_str_len char -: "op_str"
    let _ = seal (t : t Ctypes.structure typ)
  end

  module Struct_io_uring_task_add = struct
    type t = {
      ctx_ptr : nativeint;
      req_ptr : nativeint;
      opcode : int;
      mask : int;
      op_str : string;
    }

    let t = structure "io_uring_task_add"
    let ( -: ) ty label = field t label ty
    let ctx = ptr void -: "ctx"
    let req = ptr void -: "req"
    let opcode = uchar -: "opcode"
    let mask = int -: "mask"
    let op_str = array Defines.max_op_str_len char -: "op_str"
    let _ = seal (t : t Ctypes.structure typ)
  end

  module Struct_io_uring_task_work_run = struct
    type t = { tctx_ptr : nativeint; count : int; loops : int }

    let t = structure "io_uring_task_work_run"
    let ( -: ) ty label = field t label ty
    let tctx = ptr void -: "tctx"
    let count = uint32_t -: "count"
    let loops = uint32_t -: "loops"
    let _ = seal (t : t Ctypes.structure typ)
  end

  module Struct_io_uring_short_write = struct
    type t = { ctx_ptr : nativeint; fpos : int64; wanted : int64; got : int64 }

    let t = structure "io_uring_short_write"
    let ( -: ) ty label = field t label ty
    let ctx = ptr void -: "ctx"
    let fpos = uint64_t -: "fpos"
    let wanted = uint64_t -: "wanted"
    let got = uint64_t -: "got"
    let _ = seal (t : t Ctypes.structure typ)
  end

  module Struct_io_uring_local_work_run = struct
    type t = { ctx_ptr : nativeint; count : int; loops : int }

    let t = structure "io_uring_local_work_run"
    let ( -: ) ty label = field t label ty
    let ctx = ptr void -: "ctx"
    let count = int -: "count"
    let loops = uint32_t -: "loops"
    let _ = seal (t : t Ctypes.structure typ)
  end

  module Struct_io_uring_defer = struct
    type t = {
      ctx_ptr : nativeint;
      req_ptr : nativeint;
      opcode : int;
      op_str : string;
    }

    let t = structure "io_uring_defer"
    let ( -: ) ty label = field t label ty
    let ctx = ptr void -: "ctx"
    let req = ptr void -: "req"
    let opcode = uchar -: "opcode"
    let op_str = array Defines.max_op_str_len char -: "op_str"
    let _ = seal (t : t Ctypes.structure typ)
  end

  module Struct_io_uring_link = struct
    type t = {
      ctx_ptr : nativeint;
      req_ptr : nativeint;
      target_req_ptr : nativeint;
    }

    let t = structure "io_uring_link"
    let ( -: ) ty label = field t label ty
    let ctx = ptr void -: "ctx"
    let req = ptr void -: "req"
    let target_req = ptr void -: "target_req"
    let _ = seal (t : t Ctypes.structure typ)
  end

  module Struct_io_uring_fail_link = struct
    type t = {
      ctx_ptr : nativeint;
      req_ptr : nativeint;
      opcode : int;
      link_ptr : nativeint;
      op_str : string;
    }

    let t = structure "io_uring_fail_link"
    let ( -: ) ty label = field t label ty
    let ctx = ptr void -: "ctx"
    let req = ptr void -: "req"
    let opcode = uchar -: "opcode"
    let link = ptr void -: "link"
    let op_str = array Defines.max_op_str_len char -: "op_str"
    let _ = seal (t : t Ctypes.structure typ)
  end

  module Struct_io_uring_cqring_wait = struct
    type t = { ctx_ptr : nativeint; min_events : int }

    let t = structure "io_uring_cqring_wait"
    let ( -: ) ty label = field t label ty
    let ctx = ptr void -: "ctx"
    let min_events = int -: "min_events"
    let _ = seal (t : t Ctypes.structure typ)
  end

  module Struct_io_uring_req_failed = struct
    type t = {
      ctx_ptr : nativeint;
      req_ptr : nativeint;
      opcode : int;
      flags : int;
      ioprio : int;
      off : int64;
      addr : int64;
      len : int;
      op_flags : int;
      buf_index : int;
      personality : int;
      file_index : int;
      pad1 : int64;
      addr3 : int64;
      error : int;
      op_str : string;
    }

    let t = structure "io_uring_req_failed"
    let ( -: ) ty label = field t label ty
    let ctx = ptr void -: "ctx"
    let req = ptr void -: "req"
    let opcode = uchar -: "opcode"
    let flags = uchar -: "flags"
    let ioprio = uchar -: "ioprio"
    let off = ullong -: "off"
    let addr = ullong -: "addr"
    let len = ulong -: "len"
    let op_flags = ulong -: "op_flags"
    let buf_index = uint -: "buf_index"
    let personality = uint -: "personality"
    let file_index = ulong -: "file_index"
    let pad1 = ullong -: "pad1"
    let addr3 = ullong -: "addr3"
    let error = int -: "error"
    let op_str = array Defines.max_op_str_len char -: "op_str"
    let _ = seal (t : t Ctypes.structure typ)
  end

  module Struct_io_uring_cqe_overflow = struct
    type t = {
      ctx_ptr : nativeint;
      user_data : int64;
      res : int;
      cflags : int;
      ocqe_ptr : nativeint;
    }

    let t = structure "io_uring_cqe_overflow"
    let ( -: ) ty label = field t label ty
    let ctx = ptr void -: "ctx"
    let user_data = ullong -: "user_data"
    let res = int -: "res"
    let cflags = ulong -: "cflags"
    let ocqe = ptr void -: "ocqe"
    let _ = seal (t : t Ctypes.structure typ)
  end

  module Struct_io_uring_complete = struct
    type t = {
      req_ptr : nativeint;
      ctx_ptr : nativeint;
      res : int;
      cflags : int;
    }

    let t = structure "io_uring_complete"
    let ( -: ) ty label = field t label ty
    let ctx = ptr void -: "ctx"
    let req = ptr void -: "req"
    let res = int -: "res"
    let cflags = uint -: "cflags"
    let _ = seal (t : t Ctypes.structure typ)
  end

  module Struct_event = struct
    type t

    let t = structure "event"
    let ( -: ) ty label = field t label ty
    let ty = enum_tracepoint_t -: "ty"
    let pid = int -: "pid"
    let tid = int -: "tid"
    let ts = uint64_t -: "ts"
    let comm = array Defines.task_comm_len char -: "comm"

    (* When using stub gen interface, we can just define the union type
       directly since it uses offsets to calculat the position of the
       union members. See:
       https://github.com/yallop/ocaml-ctypes/issues/593 *)
    let io_uring_create = Struct_io_uring_create.t -: "io_uring_create"
    let io_uring_register = Struct_io_uring_register.t -: "io_uring_register"
    let io_uring_file_get = Struct_io_uring_file_get.t -: "io_uring_file_get"

    let io_uring_submit_sqe =
      Struct_io_uring_submit_sqe.t -: "io_uring_submit_sqe"

    let io_uring_queue_async_work =
      Struct_io_uring_queue_async_work.t -: "io_uring_queue_async_work"

    let io_uring_poll_arm = Struct_io_uring_poll_arm.t -: "io_uring_poll_arm"
    let io_uring_task_add = Struct_io_uring_task_add.t -: "io_uring_task_add"

    let io_uring_task_work_run =
      Struct_io_uring_task_work_run.t -: "io_uring_task_work_run"

    let io_uring_short_write =
      Struct_io_uring_short_write.t -: "io_uring_short_write"

    let io_uring_local_work_run =
      Struct_io_uring_local_work_run.t -: "io_uring_local_work_run"

    let io_uring_defer = Struct_io_uring_defer.t -: "io_uring_defer"
    let io_uring_link = Struct_io_uring_link.t -: "io_uring_link"
    let io_uring_fail_link = Struct_io_uring_fail_link.t -: "io_uring_fail_link"

    let io_uring_cqring_wait =
      Struct_io_uring_cqring_wait.t -: "io_uring_cqring_wait"

    let io_uring_req_failed =
      Struct_io_uring_req_failed.t -: "io_uring_req_failed"

    let io_uring_cqe_overflow =
      Struct_io_uring_cqe_overflow.t -: "io_uring_cqe_overflow"

    let io_uring_complete = Struct_io_uring_complete.t -: "io_uring_complete"
    let _ = seal (t : t Ctypes.structure typ)
  end

  (* ================================================================================ *)
end
