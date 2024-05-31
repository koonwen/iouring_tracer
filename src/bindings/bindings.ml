open Ctypes
include Compile_time.Bindings (Uring_generated)

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

(* module Skel = struct *)
(*   open Ocaml_libbpf.Libbpf.Types *)
(*   type uring_bpf *)

(*   let uring_bpf : uring_bpf structure typ = structure "uring_bpf" *)
(*   let struct_anon_maps : [`anon] structure typ = structure "" *)
(*   let ( -: ) ty label = field struct_anon_maps label ty *)
(*   let rb = ptr bpf_map -: "rb" *)
(*   let bss = ptr bpf_map -: "bss" *)
(*   let _ = seal struct_anon_maps *)
(*   let maps = field uring_bpf "maps" struct_anon_maps *)
(*   let _ = seal uring_bpf *)

(*   let uring_bpf__destroy = *)
(*     Foreign.foreign "uring_bpf__destroy" (ptr uring_bpf @-> returning void) *)

(*   let uring_bpf__create_skeleton = *)
(*     Foreign.foreign "uring_bpf__create_skeleton" *)
(*       (ptr uring_bpf @-> returning int) *)

(*   let uring_bpf__open_and_load = *)
(*     Foreign.foreign "uring_bpf__open_and_load" *)
(*       (void @-> returning (ptr uring_bpf)) *)

(*   let uring_bpf__attach = *)
(*     Foreign.foreign "uring_bpf__attach" (ptr uring_bpf @-> returning int) *)

(*   let uring_bpf__detach = *)
(*     Foreign.foreign "uring_bpf__detach" (ptr uring_bpf @-> returning int) *)
(* end *)

let () =
  assert (Defines.max_op_str_len = max_op_str_len);
  assert (Defines.task_comm_len = task_comm_len)

let unload_create (s : Struct_io_uring_create.t structure) =
  let open Struct_io_uring_create in
  let fd = getf s fd in
  let ctx_ptr = getf s ctx |> raw_address_of_ptr in
  let cq_entries = getf s cq_entries |> Unsigned.UInt32.to_int32 in
  let sq_entries = getf s sq_entries |> Unsigned.UInt32.to_int32 in
  let flags = getf s flags |> Unsigned.UInt32.to_int32 in
  { fd; ctx_ptr; sq_entries; cq_entries; flags }

let unload_register (s : Struct_io_uring_register.t structure) =
  let open Struct_io_uring_register in
  let ctx_ptr = getf s ctx |> raw_address_of_ptr in
  let opcode = getf s opcode |> Unsigned.UInt32.to_int32 in
  let nr_files = getf s nr_files |> Unsigned.UInt32.to_int32 in
  let nr_bufs = getf s nr_bufs |> Unsigned.UInt32.to_int32 in
  let ret = getf s ret in
  { ctx = ctx_ptr; opcode; nr_files; nr_bufs; ret }

let unload_file_get (s : Struct_io_uring_file_get.t structure) =
  let open Struct_io_uring_file_get in
  let ctx_ptr = getf s ctx |> raw_address_of_ptr in
  let req_ptr = getf s req |> raw_address_of_ptr in
  let fd = getf s fd in
  { ctx = ctx_ptr; req = req_ptr; fd }

let unload_submit_sqe (s : Struct_io_uring_submit_sqe.t structure) =
  let open Struct_io_uring_submit_sqe in
  let ctx_ptr = getf s ctx |> raw_address_of_ptr in
  let req_ptr = getf s req |> raw_address_of_ptr in
  let opcode = getf s opcode |> Unsigned.UChar.to_int in
  let flags = getf s flags |> Unsigned.ULong.to_int in
  let force_nonblock = getf s force_nonblock in
  let sq_thread = getf s sq_thread in
  let op_str = getf s op_str |> char_array_as_string in
  { req_ptr; ctx_ptr; opcode; flags; force_nonblock; sq_thread; op_str }

let unload_queue_async_work (s : Struct_io_uring_queue_async_work.t structure) =
  let open Struct_io_uring_queue_async_work in
  let ctx_ptr = getf s ctx |> raw_address_of_ptr in
  let req_ptr = getf s req |> raw_address_of_ptr in
  let opcode = getf s opcode |> Unsigned.UChar.to_int in
  let flags = getf s flags |> Unsigned.UInt32.to_int32 in
  let work_ptr = getf s work |> raw_address_of_ptr |> Int64.of_nativeint in
  let op_str = getf s op_str |> char_array_as_string in
  { ctx_ptr; req_ptr; opcode; flags; work_ptr; op_str }

let unload_poll_arm (s : Struct_io_uring_poll_arm.t structure) =
  let open Struct_io_uring_poll_arm in
  let ctx_ptr = getf s ctx |> raw_address_of_ptr in
  let req_ptr = getf s req |> raw_address_of_ptr in
  let opcode = getf s opcode |> Unsigned.UChar.to_int in
  let mask = getf s mask in
  let events = getf s events in
  let op_str = getf s op_str |> char_array_as_string in
  { ctx_ptr; req_ptr; opcode; mask; events; op_str }

let unload_task_add (s : Struct_io_uring_task_add.t structure) =
  let open Struct_io_uring_task_add in
  let ctx_ptr = getf s ctx |> raw_address_of_ptr in
  let req_ptr = getf s req |> raw_address_of_ptr in
  let opcode = getf s opcode |> Unsigned.UChar.to_int in
  let mask = getf s mask in
  let op_str = getf s op_str |> char_array_as_string in
  { ctx_ptr; req_ptr; opcode; mask; op_str }

let unload_task_work_run (s : Struct_io_uring_task_work_run.t structure) =
  let open Struct_io_uring_task_work_run in
  let tctx_ptr = getf s tctx |> raw_address_of_ptr in
  let count = getf s count |> Unsigned.UInt32.to_int in
  let loops = getf s loops |> Unsigned.UInt32.to_int in
  { tctx_ptr; count; loops }

let unload_short_write (s : Struct_io_uring_short_write.t structure) =
  let open Struct_io_uring_short_write in
  let ctx_ptr = getf s ctx |> raw_address_of_ptr in
  let fpos = getf s fpos |> Unsigned.UInt64.to_int64 in
  let wanted = getf s wanted |> Unsigned.UInt64.to_int64 in
  let got = getf s got |> Unsigned.UInt64.to_int64 in
  { ctx_ptr; fpos; wanted; got }

let unload_local_work_run (s : Struct_io_uring_local_work_run.t structure) =
  let open Struct_io_uring_local_work_run in
  let ctx_ptr = getf s ctx |> raw_address_of_ptr in
  let count = getf s count in
  let loops = getf s loops |> Unsigned.UInt32.to_int in
  { ctx_ptr; count; loops }

let unload_defer (s : Struct_io_uring_defer.t structure) =
  let open Struct_io_uring_defer in
  let ctx_ptr = getf s ctx |> raw_address_of_ptr in
  let req_ptr = getf s req |> raw_address_of_ptr in
  let opcode = getf s opcode |> Unsigned.UChar.to_int in
  let op_str = getf s op_str |> char_array_as_string in
  { ctx_ptr; req_ptr; opcode; op_str }

let unload_link (s : Struct_io_uring_link.t structure) =
  let open Struct_io_uring_link in
  let ctx_ptr = getf s ctx |> raw_address_of_ptr in
  let req_ptr = getf s req |> raw_address_of_ptr in
  let target_req_ptr = getf s target_req |> raw_address_of_ptr in
  { ctx_ptr; req_ptr; target_req_ptr }

let unload_fail_link (s : Struct_io_uring_fail_link.t structure) =
  let open Struct_io_uring_fail_link in
  let ctx_ptr = getf s ctx |> raw_address_of_ptr in
  let req_ptr = getf s req |> raw_address_of_ptr in
  let opcode = getf s opcode |> Unsigned.UChar.to_int in
  let link_ptr = getf s link |> raw_address_of_ptr in
  let op_str = getf s op_str |> char_array_as_string in
  { ctx_ptr; req_ptr; opcode; link_ptr; op_str }

let unload_cqring_wait (s : Struct_io_uring_cqring_wait.t structure) =
  let open Struct_io_uring_cqring_wait in
  let ctx_ptr = getf s ctx |> raw_address_of_ptr in
  let min_events = getf s min_events in
  { ctx_ptr; min_events }

let unload_req_failed (s : Struct_io_uring_req_failed.t structure) =
  let open Struct_io_uring_req_failed in
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

let unload_cqe_overflow (s : Struct_io_uring_cqe_overflow.t structure) =
  let open Struct_io_uring_cqe_overflow in
  let ctx_ptr = getf s ctx |> raw_address_of_ptr in
  let user_data = getf s user_data |> Unsigned.ULLong.to_int64 in
  let res = getf s res in
  let cflags = getf s cflags |> Unsigned.ULong.to_int in
  let ocqe_ptr = getf s ocqe |> raw_address_of_ptr in
  { ctx_ptr; user_data; res; cflags; ocqe_ptr }

let unload_complete (s : Struct_io_uring_complete.t structure) =
  let open Struct_io_uring_complete in
  let ctx_ptr = getf s ctx |> raw_address_of_ptr in
  let req_ptr = getf s req |> raw_address_of_ptr in
  let res = getf s res in
  let cflags = getf s cflags |> Unsigned.UInt.to_int in
  { ctx_ptr; req_ptr; res; cflags }
