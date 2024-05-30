open Ctypes

let char_array_as_string a =
  let len = CArray.length a in
  let b = Buffer.create len in
  try
    for i = 0 to len - 1 do
      let c = CArray.get a i in
      if c = '\x00' then raise Exit else Buffer.add_char b c
    done;
    Buffer.contents b
  with Exit -> Buffer.contents b

include Defs.Uring.Bindings (Uring_generated)

module Struct_io_uring_create = struct
  type t = {
    fd : int;
    ctx_ptr : nativeint;
    sq_entries : int32;
    cq_entries : int32;
    flags : int32;
  }

  let t : t structure typ = structure "io_uring_create"
  let ( -: ) ty label = field t label ty
  let fd = int -: "fd"
  let ctx = ptr void -: "ctx"
  let sq_entries = uint32_t -: "sq_entries"
  let cq_entries = uint32_t -: "cq_entries"
  let flags = uint32_t -: "flags"
  let _ = seal t

  let unload (t : t structure) =
    let fd = getf t fd in
    let ctx_ptr = getf t ctx |> raw_address_of_ptr in
    let cq_entries = getf t cq_entries |> Unsigned.UInt32.to_int32 in
    let sq_entries = getf t sq_entries |> Unsigned.UInt32.to_int32 in
    let flags = getf t flags |> Unsigned.UInt32.to_int32 in
    { fd; ctx_ptr; sq_entries; cq_entries; flags }
end

module Struct_io_uring_register = struct
  type t = {
    ctx : nativeint;
    opcode : int32;
    nr_files : int32;
    nr_bufs : int32;
    ret : int64;
  }

  let t : t structure typ = structure "io_uring_register"
  let ( -: ) ty label = field t label ty
  let ctx = ptr void -: "ctx"
  let opcode = uint32_t -: "opcode"
  let nr_files = uint32_t -: "nr_files"
  let nr_bufs = uint32_t -: "nr_bufs"
  let ret = int64_t -: "ret"
  let _ = seal t

  let unload (t : t structure) =
    let ctx_ptr = getf t ctx |> raw_address_of_ptr in
    let opcode = getf t opcode |> Unsigned.UInt32.to_int32 in
    let nr_files = getf t nr_files |> Unsigned.UInt32.to_int32 in
    let nr_bufs = getf t nr_bufs |> Unsigned.UInt32.to_int32 in
    let ret = getf t ret in
    { ctx = ctx_ptr; opcode; nr_files; nr_bufs; ret }
end

module Struct_io_uring_file_get = struct
  type t = { ctx : nativeint; req : nativeint; fd : int }

  let t : t structure typ = structure "io_uring_file_get"
  let ( -: ) ty label = field t label ty
  let ctx = ptr void -: "ctx"
  let req = ptr void -: "req"
  let fd = int -: "fd"
  let _ = seal t

  let unload (t : t structure) =
    let ctx_ptr = getf t ctx |> raw_address_of_ptr in
    let req_ptr = getf t req |> raw_address_of_ptr in
    let fd = getf t fd in
    { ctx = ctx_ptr; req = req_ptr; fd }
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

  let t : t structure typ = structure "io_uring_submit_sqe"
  let ( -: ) ty label = field t label ty
  let ctx = ptr void -: "ctx"
  let req = ptr void -: "req"
  let opcode = uchar -: "opcode"
  let flags = ulong -: "flags"
  let force_nonblock = bool -: "force_nonblock"
  let sq_thread = bool -: "sq_thread"
  let op_str = array max_op_str_len char -: "op_str"
  let _ = seal t

  let unload (t : t structure) =
    let ctx_ptr = getf t ctx |> raw_address_of_ptr in
    let req_ptr = getf t req |> raw_address_of_ptr in
    let opcode = getf t opcode |> Unsigned.UChar.to_int in
    let flags = getf t flags |> Unsigned.ULong.to_int in
    let force_nonblock = getf t force_nonblock in
    let sq_thread = getf t sq_thread in
    let op_str = getf t op_str |> char_array_as_string in
    { req_ptr; ctx_ptr; opcode; flags; force_nonblock; sq_thread; op_str }
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

  let t : t structure typ = structure "io_uring_queue_async_work"
  let ( -: ) ty label = field t label ty
  let ctx = ptr void -: "ctx"
  let req = ptr void -: "req"
  let opcode = uchar -: "opcode"
  let flags = uint32_t -: "flags"
  let work = ptr void -: "work"
  let op_str = array max_op_str_len char -: "op_str"
  let _ = seal t

  let unload (t : t structure) =
    let ctx_ptr = getf t ctx |> raw_address_of_ptr in
    let req_ptr = getf t req |> raw_address_of_ptr in
    let opcode = getf t opcode |> Unsigned.UChar.to_int in
    let flags = getf t flags |> Unsigned.UInt32.to_int32 in
    let work_ptr = getf t work |> raw_address_of_ptr |> Int64.of_nativeint in
    let op_str = getf t op_str |> char_array_as_string in
    { ctx_ptr; req_ptr; opcode; flags; work_ptr; op_str }
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

  let t : t structure typ = structure "io_uring_poll_arm"
  let ( -: ) ty label = field t label ty
  let ctx = ptr void -: "ctx"
  let req = ptr void -: "req"
  let opcode = uchar -: "opcode"
  let mask = int -: "mask"
  let events = int -: "events"
  let op_str = array max_op_str_len char -: "op_str"
  let _ = seal t

  let unload (t : t structure) =
    let ctx_ptr = getf t ctx |> raw_address_of_ptr in
    let req_ptr = getf t req |> raw_address_of_ptr in
    let opcode = getf t opcode |> Unsigned.UChar.to_int in
    let mask = getf t mask in
    let events = getf t events in
    let op_str = getf t op_str |> char_array_as_string in
    { ctx_ptr; req_ptr; opcode; mask; events; op_str }
end

module Struct_io_uring_task_add = struct
  type t = {
    ctx_ptr : nativeint;
    req_ptr : nativeint;
    opcode : int;
    mask : int;
    op_str : string;
  }

  let t : t structure typ = structure "io_uring_task_add"
  let ( -: ) ty label = field t label ty
  let ctx = ptr void -: "ctx"
  let req = ptr void -: "req"
  let opcode = uchar -: "opcode"
  let mask = int -: "mask"
  let op_str = array max_op_str_len char -: "op_str"
  let _ = seal t

  let unload (t : t structure) =
    let ctx_ptr = getf t ctx |> raw_address_of_ptr in
    let req_ptr = getf t req |> raw_address_of_ptr in
    let opcode = getf t opcode |> Unsigned.UChar.to_int in
    let mask = getf t mask in
    let op_str = getf t op_str |> char_array_as_string in
    { ctx_ptr; req_ptr; opcode; mask; op_str }
end

module Struct_io_uring_task_work_run = struct
  type t = { tctx_ptr : nativeint; count : int; loops : int }

  let t : t structure typ = structure "io_uring_task_work_run"
  let ( -: ) ty label = field t label ty
  let tctx = ptr void -: "tctx"
  let count = uint32_t -: "count"
  let loops = uint32_t -: "loops"
  let _ = seal t

  let unload (t : t structure) =
    let tctx_ptr = getf t tctx |> raw_address_of_ptr in
    let count = getf t count |> Unsigned.UInt32.to_int in
    let loops = getf t loops |> Unsigned.UInt32.to_int in
    { tctx_ptr; count; loops }
end

module Struct_io_uring_short_write = struct
  type t = { ctx_ptr : nativeint; fpos : int64; wanted : int64; got : int64 }

  let t : t structure typ = structure "io_uring_short_write"
  let ( -: ) ty label = field t label ty
  let ctx = ptr void -: "ctx"
  let fpos = uint64_t -: "fpos"
  let wanted = uint64_t -: "wanted"
  let got = uint64_t -: "got"
  let _ = seal t

  let unload (t : t structure) =
    let ctx_ptr = getf t ctx |> raw_address_of_ptr in
    let fpos = getf t fpos |> Unsigned.UInt64.to_int64 in
    let wanted = getf t wanted |> Unsigned.UInt64.to_int64 in
    let got = getf t got |> Unsigned.UInt64.to_int64 in
    { ctx_ptr; fpos; wanted; got }
end

module Struct_io_uring_local_work_run = struct
  type t = { ctx_ptr : nativeint; count : int; loops : int }

  let t : t structure typ = structure "io_uring_local_work_run"
  let ( -: ) ty label = field t label ty
  let ctx = ptr void -: "ctx"
  let count = int -: "count"
  let loops = uint32_t -: "loops"
  let _ = seal t

  let unload (t : t structure) =
    let ctx_ptr = getf t ctx |> raw_address_of_ptr in
    let count = getf t count in
    let loops = getf t loops |> Unsigned.UInt32.to_int in
    { ctx_ptr; count; loops }
end

module Struct_io_uring_defer = struct
  type t = {
    ctx_ptr : nativeint;
    req_ptr : nativeint;
    opcode : int;
    op_str : string;
  }

  let t : t structure typ = structure "io_uring_defer"
  let ( -: ) ty label = field t label ty
  let ctx = ptr void -: "ctx"
  let req = ptr void -: "req"
  let opcode = uchar -: "opcode"
  let op_str = array max_op_str_len char -: "op_str"
  let _ = seal t

  let unload (t : t structure) =
    let ctx_ptr = getf t ctx |> raw_address_of_ptr in
    let req_ptr = getf t req |> raw_address_of_ptr in
    let opcode = getf t opcode |> Unsigned.UChar.to_int in
    let op_str = getf t op_str |> char_array_as_string in
    { ctx_ptr; req_ptr; opcode; op_str }
end

module Struct_io_uring_link = struct
  type t = {
    ctx_ptr : nativeint;
    req_ptr : nativeint;
    target_req_ptr : nativeint;
  }

  let t : t structure typ = structure "io_uring_link"
  let ( -: ) ty label = field t label ty
  let ctx = ptr void -: "ctx"
  let req = ptr void -: "req"
  let target_req = ptr void -: "target_req"
  let _ = seal t

  let unload (t : t structure) =
    let ctx_ptr = getf t ctx |> raw_address_of_ptr in
    let req_ptr = getf t req |> raw_address_of_ptr in
    let target_req_ptr = getf t target_req |> raw_address_of_ptr in
    { ctx_ptr; req_ptr; target_req_ptr }
end

module Struct_io_uring_fail_link = struct
  type t = {
    ctx_ptr : nativeint;
    req_ptr : nativeint;
    opcode : int;
    link_ptr : nativeint;
    op_str : string;
  }

  let t : t structure typ = structure "io_uring_fail_link"
  let ( -: ) ty label = field t label ty
  let ctx = ptr void -: "ctx"
  let req = ptr void -: "req"
  let opcode = uchar -: "opcode"
  let link = ptr void -: "link"
  let op_str = array max_op_str_len char -: "op_str"
  let _ = seal t

  let unload (t : t structure) =
    let ctx_ptr = getf t ctx |> raw_address_of_ptr in
    let req_ptr = getf t req |> raw_address_of_ptr in
    let opcode = getf t opcode |> Unsigned.UChar.to_int in
    let link_ptr = getf t link |> raw_address_of_ptr in
    let op_str = getf t op_str |> char_array_as_string in
    { ctx_ptr; req_ptr; opcode; link_ptr; op_str }
end

module Struct_io_uring_cqring_wait = struct
  type t = { ctx_ptr : nativeint; min_events : int }

  let t : t structure typ = structure "io_uring_cqring_wait"
  let ( -: ) ty label = field t label ty
  let ctx = ptr void -: "ctx"
  let min_events = int -: "min_events"
  let _ = seal t

  let unload (t : t structure) =
    let ctx_ptr = getf t ctx |> raw_address_of_ptr in
    let min_events = getf t min_events in
    { ctx_ptr; min_events }
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

  let t : t structure typ = structure "io_uring_req_failed"
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
  let op_str = array max_op_str_len char -: "op_str"
  let _ = seal t

  let unload (t : t structure) =
    let ctx_ptr = getf t ctx |> raw_address_of_ptr in
    let req_ptr = getf t req |> raw_address_of_ptr in
    let opcode = getf t opcode |> Unsigned.UChar.to_int in
    let flags = getf t flags |> Unsigned.UChar.to_int in
    let ioprio = getf t ioprio |> Unsigned.UChar.to_int in
    let off = getf t off |> Unsigned.ULLong.to_int64 in
    let addr = getf t addr |> Unsigned.ULLong.to_int64 in
    let len = getf t len |> Unsigned.ULong.to_int in
    let op_flags = getf t op_flags |> Unsigned.ULong.to_int in
    let buf_index = getf t buf_index |> Unsigned.UInt.to_int in
    let personality = getf t personality |> Unsigned.UInt.to_int in
    let file_index = getf t file_index |> Unsigned.ULong.to_int in
    let pad1 = getf t pad1 |> Unsigned.ULLong.to_int64 in
    let addr3 = getf t addr3 |> Unsigned.ULLong.to_int64 in
    let error = getf t error in
    let op_str = getf t op_str |> char_array_as_string in
    {
      ctx_ptr;
      req_ptr;
      opcode;
      flags;
      ioprio;
      off;
      addr;
      len;
      op_flags;
      buf_index;
      personality;
      file_index;
      pad1;
      addr3;
      error;
      op_str;
    }
end

module Struct_io_uring_cqe_overflow = struct
  type t = {
    ctx_ptr : nativeint;
    user_data : int64;
    res : int;
    cflags : int;
    ocqe_ptr : nativeint;
  }

  let t : t structure typ = structure "io_uring_cqe_overflow"
  let ( -: ) ty label = field t label ty
  let ctx = ptr void -: "ctx"
  let user_data = ullong -: "user_data"
  let res = int -: "res"
  let cflags = ulong -: "cflags"
  let ocqe = ptr void -: "ocqe"
  let _ = seal t

  let unload (t : t structure) =
    let ctx_ptr = getf t ctx |> raw_address_of_ptr in
    let user_data = getf t user_data |> Unsigned.ULLong.to_int64 in
    let res = getf t res in
    let cflags = getf t cflags |> Unsigned.ULong.to_int in
    let ocqe_ptr = getf t ocqe |> raw_address_of_ptr in
    { ctx_ptr; user_data; res; cflags; ocqe_ptr }
end

module Struct_io_uring_complete = struct
  type t = { req_ptr : nativeint; ctx_ptr : nativeint; res : int; cflags : int }

  let t : t structure typ = structure "io_uring_complete"
  let ( -: ) ty label = field t label ty
  let ctx = ptr void -: "ctx"
  let req = ptr void -: "req"
  let res = int -: "res"
  let cflags = uint -: "cflags"
  let _ = seal t

  let unload (t : t structure) =
    let ctx_ptr = getf t ctx |> raw_address_of_ptr in
    let req_ptr = getf t req |> raw_address_of_ptr in
    let res = getf t res in
    let cflags = getf t cflags |> Unsigned.UInt.to_int in
    { ctx_ptr; req_ptr; res; cflags }
end

type event

let struct_event : event structure typ = structure "event"
let ( -: ) ty label = field struct_event label ty
let t = enum_tracepoint_t -: "t"
let pid = int -: "pid"
let tid = int -: "tid"
let ts = uint64_t -: "ts"
let comm = array task_comm_len char -: "comm"
let extra : [ `extra ] union typ = union "extra"
let io_uring_create = field extra "io_uring_create" Struct_io_uring_create.t

let io_uring_register =
  field extra "io_uring_register" Struct_io_uring_register.t

let io_uring_file_get =
  field extra "io_uring_file_get" Struct_io_uring_file_get.t

let io_uring_submit_sqe =
  field extra "io_uring_submit_sqe" Struct_io_uring_submit_sqe.t

let io_uring_queue_async_work =
  field extra "io_uring_queue_async_work" Struct_io_uring_queue_async_work.t

let io_uring_poll_arm =
  field extra "io_uring_poll_arm" Struct_io_uring_poll_arm.t

let io_uring_task_add =
  field extra "io_uring_task_add" Struct_io_uring_task_add.t

let io_uring_task_work_run =
  field extra "io_uring_task_work_run" Struct_io_uring_task_work_run.t

let io_uring_short_write =
  field extra "io_uring_short_write" Struct_io_uring_short_write.t

let io_uring_local_work_run =
  field extra "io_uring_local_work_run" Struct_io_uring_local_work_run.t

let io_uring_defer = field extra "io_uring_defer" Struct_io_uring_defer.t
let io_uring_link = field extra "io_uring_link" Struct_io_uring_link.t

let io_uring_fail_link =
  field extra "io_uring_fail_link" Struct_io_uring_fail_link.t

let io_uring_cqring_wait =
  field extra "io_uring_cqring_wait" Struct_io_uring_cqring_wait.t

let io_uring_req_failed =
  field extra "io_uring_req_failed" Struct_io_uring_req_failed.t

let io_uring_cqe_overflow =
  field extra "io_uring_cqe_overflow" Struct_io_uring_cqe_overflow.t

let io_uring_complete =
  field extra "io_uring_complete" Struct_io_uring_complete.t

let () = seal extra
let ufield = field struct_event "" extra
let _ = seal struct_event
