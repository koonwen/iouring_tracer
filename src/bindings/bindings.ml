open Ctypes
include Stubs.Bindings (Uring_generated)
include Consts

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

let () =
  assert (Defines.max_op_str_len = max_op_str_len);
  assert (Defines.task_comm_len = task_comm_len)

type io_uring_create = {
  fd : int;
  ctx_ptr : nativeint;
  sq_entries : int32;
  cq_entries : int32;
  flags : Consts.Setup_flags.t list;
}

let unload_create s =
  let open Create in
  let fd = getf s fd in
  let ctx_ptr = getf s ctx |> raw_address_of_ptr in
  let cq_entries = getf s cq_entries |> Unsigned.UInt32.to_int32 in
  let sq_entries = getf s sq_entries |> Unsigned.UInt32.to_int32 in
  let flags = getf s flags |> Unsigned.UInt32.to_int64 |> Consts.read in
  { fd; ctx_ptr; sq_entries; cq_entries; flags }

type register = {
  ctx : nativeint;
  opcode : int32;
  nr_files : int32;
  nr_bufs : int32;
  ret : int64;
}

let unload_register s =
  let open Register in
  let ctx_ptr = getf s ctx |> raw_address_of_ptr in
  let opcode = getf s opcode |> Unsigned.UInt32.to_int32 in
  let nr_files = getf s nr_files |> Unsigned.UInt32.to_int32 in
  let nr_bufs = getf s nr_bufs |> Unsigned.UInt32.to_int32 in
  let ret = getf s ret in
  { ctx = ctx_ptr; opcode; nr_files; nr_bufs; ret }

type io_uring_file_get = { ctx_ptr : nativeint; req_ptr : nativeint; fd : int }

let unload_file_get s =
  let open File_get in
  let ctx_ptr = getf s ctx |> raw_address_of_ptr in
  let req_ptr = getf s req |> raw_address_of_ptr in
  let fd = getf s fd in
  { ctx_ptr; req_ptr; fd }

type io_uring_submit_sqe = {
  ctx_ptr : nativeint;
  req_ptr : nativeint;
  opcode : int;
  flags : int;
  force_nonblock : bool;
  sq_thread : bool;
  op_str : string;
}

let unload_submit_sqe s =
  let open Submit_sqe in
  let ctx_ptr = getf s ctx |> raw_address_of_ptr in
  let req_ptr = getf s req |> raw_address_of_ptr in
  let opcode = getf s opcode |> Unsigned.UChar.to_int in
  let flags = getf s flags |> Unsigned.ULong.to_int in
  let force_nonblock = getf s force_nonblock in
  let sq_thread = getf s sq_thread in
  let op_str = getf s op_str |> char_array_as_string in
  { req_ptr; ctx_ptr; opcode; flags; force_nonblock; sq_thread; op_str }

type io_uring_queue_async_work = {
  ctx_ptr : nativeint;
  req_ptr : nativeint;
  opcode : int;
  flags : int32;
  work_ptr : int64;
  op_str : string;
}

let unload_queue_async_work s =
  let open Queue_async_work in
  let ctx_ptr = getf s ctx |> raw_address_of_ptr in
  let req_ptr = getf s req |> raw_address_of_ptr in
  let opcode = getf s opcode |> Unsigned.UChar.to_int in
  let flags = getf s flags |> Unsigned.UInt32.to_int32 in
  let work_ptr = getf s work |> raw_address_of_ptr |> Int64.of_nativeint in
  let op_str = getf s op_str |> char_array_as_string in
  { ctx_ptr; req_ptr; opcode; flags; work_ptr; op_str }

type poll_arm = {
  ctx_ptr : nativeint;
  req_ptr : nativeint;
  opcode : int;
  mask : int;
  events : int;
  op_str : string;
}

let unload_poll_arm s =
  let open Poll_arm in
  let ctx_ptr = getf s ctx |> raw_address_of_ptr in
  let req_ptr = getf s req |> raw_address_of_ptr in
  let opcode = getf s opcode |> Unsigned.UChar.to_int in
  let mask = getf s mask in
  let events = getf s events in
  let op_str = getf s op_str |> char_array_as_string in
  { ctx_ptr; req_ptr; opcode; mask; events; op_str }

type task_add = {
  ctx_ptr : nativeint;
  req_ptr : nativeint;
  opcode : int;
  mask : int;
  op_str : string;
}

let unload_task_add s =
  let open Task_add in
  let ctx_ptr = getf s ctx |> raw_address_of_ptr in
  let req_ptr = getf s req |> raw_address_of_ptr in
  let opcode = getf s opcode |> Unsigned.UChar.to_int in
  let mask = getf s mask in
  let op_str = getf s op_str |> char_array_as_string in
  { ctx_ptr; req_ptr; opcode; mask; op_str }

type task_work_run = { tctx_ptr : nativeint; count : int; loops : int }

let unload_task_work_run s =
  let open Task_work_run in
  let tctx_ptr = getf s tctx |> raw_address_of_ptr in
  let count = getf s count |> Unsigned.UInt32.to_int in
  let loops = getf s loops |> Unsigned.UInt32.to_int in
  { tctx_ptr; count; loops }

type short_write = {
  ctx_ptr : nativeint;
  fpos : int64;
  wanted : int64;
  got : int64;
}

let unload_short_write s =
  let open Short_write in
  let ctx_ptr = getf s ctx |> raw_address_of_ptr in
  let fpos = getf s fpos |> Unsigned.UInt64.to_int64 in
  let wanted = getf s wanted |> Unsigned.UInt64.to_int64 in
  let got = getf s got |> Unsigned.UInt64.to_int64 in
  { ctx_ptr; fpos; wanted; got }

type local_work_run = { ctx_ptr : nativeint; count : int; loops : int }

let unload_local_work_run s =
  let open Local_work_run in
  let ctx_ptr = getf s ctx |> raw_address_of_ptr in
  let count = getf s count in
  let loops = getf s loops |> Unsigned.UInt32.to_int in
  { ctx_ptr; count; loops }

type defer = {
  ctx_ptr : nativeint;
  req_ptr : nativeint;
  opcode : int;
  op_str : string;
}

let unload_defer s =
  let open Defer in
  let ctx_ptr = getf s ctx |> raw_address_of_ptr in
  let req_ptr = getf s req |> raw_address_of_ptr in
  let opcode = getf s opcode |> Unsigned.UChar.to_int in
  let op_str = getf s op_str |> char_array_as_string in
  { ctx_ptr; req_ptr; opcode; op_str }

type link = {
  ctx_ptr : nativeint;
  req_ptr : nativeint;
  target_req_ptr : nativeint;
}

let unload_link s =
  let open Link in
  let ctx_ptr = getf s ctx |> raw_address_of_ptr in
  let req_ptr = getf s req |> raw_address_of_ptr in
  let target_req_ptr = getf s target_req |> raw_address_of_ptr in
  { ctx_ptr; req_ptr; target_req_ptr }

type fail_link = {
  ctx_ptr : nativeint;
  req_ptr : nativeint;
  opcode : int;
  link_ptr : nativeint;
  op_str : string;
}

let unload_fail_link s =
  let open Fail_link in
  let ctx_ptr = getf s ctx |> raw_address_of_ptr in
  let req_ptr = getf s req |> raw_address_of_ptr in
  let opcode = getf s opcode |> Unsigned.UChar.to_int in
  let link_ptr = getf s link |> raw_address_of_ptr in
  let op_str = getf s op_str |> char_array_as_string in
  { ctx_ptr; req_ptr; opcode; link_ptr; op_str }

type cqring_wait = { ctx_ptr : nativeint; min_events : int }

let unload_cqring_wait s =
  let open Cqring_wait in
  let ctx_ptr = getf s ctx |> raw_address_of_ptr in
  let min_events = getf s min_events in
  { ctx_ptr; min_events }

type req_failed = {
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

let unload_req_failed s =
  let open Req_failed in
  let ctx_ptr = getf s ctx |> raw_address_of_ptr in
  let req_ptr = getf s req |> raw_address_of_ptr in
  let opcode = getf s opcode |> Unsigned.UChar.to_int in
  let flags = getf s flags |> Unsigned.UChar.to_int in
  let ioprio = getf s ioprio |> Unsigned.UChar.to_int in
  let off = getf s off |> Unsigned.ULLong.to_int64 in
  let addr = getf s addr |> Unsigned.ULLong.to_int64 in
  let len = getf s len |> Unsigned.ULong.to_int in
  let op_flags = getf s op_flags |> Unsigned.ULong.to_int in
  let buf_index = getf s buf_index |> Unsigned.UInt.to_int in
  let personality = getf s personality |> Unsigned.UInt.to_int in
  let file_index = getf s file_index |> Unsigned.ULong.to_int in
  let pad1 = getf s pad1 |> Unsigned.ULLong.to_int64 in
  let addr3 = getf s addr3 |> Unsigned.ULLong.to_int64 in
  let error = getf s error in
  let op_str = getf s op_str |> char_array_as_string in
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

type cqe_overflow = {
  ctx_ptr : nativeint;
  user_data : int64;
  res : int;
  cflags : int;
  ocqe_ptr : nativeint;
}

let unload_cqe_overflow s =
  let open Cqe_overflow in
  let ctx_ptr = getf s ctx |> raw_address_of_ptr in
  let user_data = getf s user_data |> Unsigned.ULLong.to_int64 in
  let res = getf s res in
  let cflags = getf s cflags |> Unsigned.ULong.to_int in
  let ocqe_ptr = getf s ocqe |> raw_address_of_ptr in
  { ctx_ptr; user_data; res; cflags; ocqe_ptr }

type complete = {
  req_ptr : nativeint;
  ctx_ptr : nativeint;
  res : int;
  cflags : int;
}

let unload_complete s =
  let open Complete in
  let ctx_ptr = getf s ctx |> raw_address_of_ptr in
  let req_ptr = getf s req |> raw_address_of_ptr in
  let res = getf s res in
  let cflags = getf s cflags |> Unsigned.UInt.to_int in
  { ctx_ptr; req_ptr; res; cflags }
