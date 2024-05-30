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
  let opcode = uint8_t -: "opcode"
  let flags = ulong -: "flags"
  let force_nonblock = bool -: "force_nonblock"
  let sq_thread = bool -: "sq_thread"
  let op_str = array max_op_str_len char -: "op_str"
  let _ = seal t

  let unload (t : t structure) =
    let ctx_ptr = getf t ctx |> raw_address_of_ptr in
    let req_ptr = getf t req |> raw_address_of_ptr in
    let opcode = getf t opcode |> Unsigned.UInt8.to_int in
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
  let opcode = uint8_t -: "opcode"
  let flags = uint32_t -: "flags"
  let work = ptr void -: "work"
  let op_str = array max_op_str_len char -: "op_str"
  let _ = seal t

  let unload (t : t structure) =
    let ctx_ptr = getf t ctx |> raw_address_of_ptr in
    let req_ptr = getf t req |> raw_address_of_ptr in
    let opcode = getf t opcode |> Unsigned.UInt8.to_int in
    let flags = getf t flags |> Unsigned.UInt32.to_int32 in
    let work_ptr = getf t work |> raw_address_of_ptr |> Int64.of_nativeint in
    let op_str = getf t op_str |> char_array_as_string in
    { ctx_ptr; req_ptr; opcode; flags; work_ptr; op_str }
end

module Struct_io_uring_complete = struct
  type t = {
    req_ptr : nativeint;
    ctx_ptr : nativeint;
    res : int;
    cflags : int32;
  }

  let t : t structure typ = structure "io_uring_complete"
  let ( -: ) ty label = field t label ty
  let ctx = ptr void -: "ctx"
  let req = ptr void -: "req"
  let res = int -: "res"
  let cflags = uint32_t -: "cflags"
  let _ = seal t

  let unload (t : t structure) =
    let ctx_ptr = getf t ctx |> raw_address_of_ptr in
    let req_ptr = getf t req |> raw_address_of_ptr in
    let res = getf t res in
    let cflags = getf t cflags |> Unsigned.UInt32.to_int32 in
    { ctx_ptr; req_ptr; res; cflags }
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

let io_uring_submit_sqe =
  field extra "io_uring_submit_sqe" Struct_io_uring_submit_sqe.t

let io_uring_queue_async_work =
  field extra "io_uring_queue_async_work" Struct_io_uring_queue_async_work.t

let io_uring_complete =
  field extra "io_uring_complete" Struct_io_uring_complete.t

let io_uring_cqring_wait =
  field extra "io_uring_cqring_wait" Struct_io_uring_cqring_wait.t

let () = seal extra
let ufield = field struct_event "" extra
let _ = seal struct_event
