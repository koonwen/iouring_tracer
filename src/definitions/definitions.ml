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

module Uring_ops = struct
  include Defs.Uring.Bindings (Uring_generated)

  module Struct_io_uring_submit_sqe = struct
    type io_uring_submit_sqe

    let t : io_uring_submit_sqe structure typ =
      structure "io_uring_submit_sqe"

    let ( -: ) ty label = field t label ty
    let req = ptr void -: "req" [@@warning "-32"]
    let opcode = uint8_t -: "opcode"
    let flags = uint32_t -: "flags"
    let force_nonblock = bool -: "force_nonblock"
    let sq_thread = bool -: "sq_thread"
    let op_str = array max_op_str_len char -: "op_str"
    let _ = seal t
  end

  module Struct_io_uring_complete = struct
    type io_uring_complete

    let t : io_uring_complete structure typ =
      structure "io_uring_complete"

    let ( -: ) ty label = field t label ty
    let req = ptr void -: "req"
    let res = int -: "res"
    let cflags = uint32_t -: "cflags"
    let _ = seal t
  end

  type event

  let struct_event : event structure typ = structure "event"
  let ( -: ) ty label = field struct_event label ty
  let t = enum_tracepoint_t -: "t"
  let pid = int -: "pid"
  let tid = int -: "tid"
  let ts = uint64_t -: "ts"
  let comm = array task_comm_len char -: "comm"
  let extra : [`extra] union typ = union "extra"
  let io_uring_submit_sqe = field extra "io_uring_submit_sqe" Struct_io_uring_submit_sqe.t
  let io_uring_complete = field extra "io_uring_complete" Struct_io_uring_complete.t
  let () = seal extra
  let ufield = field struct_event "" extra
  let _ = seal struct_event
end
