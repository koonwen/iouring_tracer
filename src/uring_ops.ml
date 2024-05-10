[@@@warning "-26-27"]

module D = Definitions.Uring_ops
module W = Fxt.Write

let tbl : (unit Ctypes_static.ptr, 'a) Hashtbl.t = Hashtbl.create 50

(* Print out remaining events that were unmatched *)
let dump_tbl () =
  let s =
    Hashtbl.fold
      (fun k (start, _, _, _, _, op_str) acc ->
        let p = Ctypes_value_printing.string_of Ctypes.(ptr void) k in
        let s = Format.sprintf "[%Ld] %s %s\n" start op_str p in
        s ^ acc)
      tbl "End of Table"
  in
  print_endline s

(* move all the extraction of fields to definitions *)
let handle_event _ctx data _size fxt =
  let open Ctypes in
  let event = !@(from_voidp D.struct_event data) in
  let ts = getf event D.ts |> Unsigned.UInt64.to_int64 in
  (match getf event D.t with
  | D.IO_URING_SUBMIT_SQE ->
      let module S = D.Struct_io_uring_submit_sqe in
      let u = getf event D.ufield in
      let t = getf u D.io_uring_submit_sqe in
      let req = getf t S.req in
      let opcode = getf t S.opcode in
      let flags = getf t S.flags in
      let force_nonblock = getf t S.force_nonblock in
      let sq_thread = getf t S.sq_thread in
      let op_str = getf t S.op_str |> Definitions.char_array_as_string in
      Hashtbl.replace tbl req
        (ts, opcode, flags, force_nonblock, sq_thread, op_str)
  | D.IO_URING_COMPLETE -> (
      let module S = D.Struct_io_uring_complete in
      let u = getf event D.ufield in
      let t = getf u D.io_uring_complete in
      let req = getf t S.req in
      match Hashtbl.find_opt tbl req with
      | Some (start, opcode, flags, force_nonblock, sq_thread, op_str) ->
          let res = getf t S.res |> Int64.of_int in
          let cflags = getf t S.cflags |> Unsigned.UInt32.to_int64 in
          let pid = getf event D.pid |> Int64.of_int in
          let tid = getf event D.tid |> Int64.of_int in
          let thread = { Fxt.Write.pid; tid } in
          W.duration_begin fxt
            ~args:
              [
                ("opcode", `Int64 (Unsigned.UInt8.to_int64 opcode));
                ("flags", `Int64 (Unsigned.UInt32.to_int64 flags));
                ("force_nonblock", `String (Bool.to_string force_nonblock));
                ("sq_thread", `String (Bool.to_string sq_thread));
              ]
            ~name:op_str ~category:"bpf" ~thread ~ts:start;
          W.duration_end fxt
            ~args:[ ("res", `Int64 res); ("cflags", `Int64 cflags) ]
            ~name:op_str ~category:"bpf" ~thread ~ts;
          Hashtbl.remove tbl req
      | None -> Printf.eprintf "No matching exec event\n%!"));
  0

let () =
  Util.event_loop_run ~tracefile:"ops.fxt" ~bpf_object_path:"uring_ops.bpf.o"
    ~program_names:[ "handle_submit"; "handle_complete" ]
    [ handle_event ];
  (* Print unmatched events *)
  dump_tbl ()
