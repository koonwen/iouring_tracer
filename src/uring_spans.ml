module D = Definitions.Uring_spans
module W = Fxt.Write

let handle_span _ctx data _size fxt =
  let open Ctypes in
  let event = !@(from_voidp D.struct_event data) in
  let pid = getf event D.pid |> Int64.of_int in
  let tid = getf event D.tid |> Int64.of_int in
  let probe = getf event D.probe in
  let span = getf event D.span in
  let ts = getf event D.ktime_ns |> Unsigned.UInt64.to_int64 in

  (* let comm = getf event D.comm |> Definitions.char_array_as_string in *)
  let name = D.show_syscalls_t probe in
  let thread = { Fxt.Write.pid; tid } in
  (match span with
  | D.BEGIN -> W.duration_begin fxt ~name ~category:"bpf" ~thread ~ts
  | D.END -> W.duration_end fxt ~name ~category:"bpf" ~thread ~ts
  | D.NONE -> failwith "Unexpected value of span enum");
  0

let () =
  Util.event_loop_run ~tracefile:"spans.fxt" ~bpf_object_path:"uring_spans.bpf.o"
    ~program_names:
      [
        "handle_sys_exit_io_uring_register";
        "handle_sys_enter_io_uring_register";
        "handle_sys_exit_io_uring_setup";
        "handle_sys_enter_io_uring_setup";
        "handle_sys_exit_io_uring_enter";
        "handle_sys_enter_io_uring_enter";
      ]
    [ handle_span ]
