open Ocaml_libbpf
module F = Libbpf.Functions
module T = Libbpf.Types
module W = Fxt.Write
module D = Definitions.Uring_ops

exception Exit of int

(* Describe event handler *)
let handle_event (wt : Ring_writer.t) _ctx data _size =
  let open Ctypes in
  let event = !@(from_voidp D.struct_event data) in
  let ts = getf event D.ts |> Unsigned.UInt64.to_int64 in
  (match getf event D.t with
  | D.SYS_ENTER_IO_URING_ENTER ->
      W.duration_begin wt.fxt ~name:"IO_URING_ENTER" ~thread:wt.syscalls
        ~category:"uring" ~ts
  | D.SYS_EXIT_IO_URING_ENTER ->
      W.duration_end wt.fxt ~name:"IO_URING_ENTER" ~thread:wt.syscalls
        ~category:"uring" ~ts
  | D.IO_URING_SUBMIT_SQE ->
      let module S = D.Struct_io_uring_submit_sqe in
      let u = getf event D.ufield in
      let t = getf u D.io_uring_submit_sqe in
      let req = getf t S.req |> raw_address_of_ptr |> Int64.of_nativeint in
      let opcode = getf t S.opcode in
      let flags = getf t S.flags in
      let force_nonblock = getf t S.force_nonblock in
      let sq_thread = getf t S.sq_thread in
      let op_str = getf t S.op_str |> Definitions.char_array_as_string in
      Ring_writer.submission_event wt ~name:op_str ~ts ~correlation_id:req
        ~args:
          [
            ("req", `Pointer req);
            ("opcode", `Int64 (Unsigned.UInt8.to_int64 opcode));
            ("flags", `Int64 (Unsigned.UInt32.to_int64 flags));
            ("force_nonblock", `String (Bool.to_string force_nonblock));
            ("sq_thread", `String (Bool.to_string sq_thread));
          ]
  | D.IO_URING_COMPLETE ->
      let module S = D.Struct_io_uring_complete in
      let u = getf event D.ufield in
      let t = getf u D.io_uring_complete in
      let req = getf t S.req |> raw_address_of_ptr |> Int64.of_nativeint in
      let res = getf t S.res |> Int64.of_int in
      let cflags = getf t S.cflags |> Unsigned.UInt32.to_int64 in
      Ring_writer.completion_event wt ~name:"complete" ~ts ~correlation_id:req
        ~args:
          [
            ("req", `Pointer req); ("res", `Int64 res); ("cflags", `Int64 cflags);
          ]);
  0

let run handle_event =
  (* Implicitly bump RLIMIT_MEMLOCK to create BPF maps *)
  F.libbpf_set_strict_mode T.LIBBPF_STRICT_AUTO_RLIMIT_MEMLOCK;

  (* Set signal handlers *)
  let exitting = ref true in
  let sig_handler = Sys.Signal_handle (fun _ -> exitting := false) in
  Sys.(set_signal sigint sig_handler);
  Sys.(set_signal sigterm sig_handler);

  (* Read BPF object *)
  let obj =
    match F.bpf_object__open "uring.bpf.o" with
    | None ->
        Printf.eprintf "Failed to open BPF object\n";
        raise (Exit 1)
    | Some obj -> obj
  in

  at_exit (fun () -> F.bpf_object__close obj);

  (* Load BPF object *)
  if F.bpf_object__load obj = 1 then (
    Printf.eprintf "Failed to load BPF object\n";
    raise (Exit 1));

  let program_names =
    [
      "handle_submit";
      "handle_complete";
      "handle_sys_enter_io_uring_enter";
      "handle_sys_exit_io_uring_enter";
    ]
  in

  (* Find program by name *)
  let progs =
    let find_exn name =
      match F.bpf_object__find_program_by_name obj name with
      | None ->
          Printf.eprintf "Failed to find bpf program: %s\n" name;
          raise (Exit 1)
      | Some p -> p
    in
    List.map find_exn program_names
  in

  (* Attach tracepoint *)
  let links =
    let attach_exn prog =
      let link = F.bpf_program__attach prog in
      if F.libbpf_get_error (Ctypes.to_voidp link) <> Signed.Long.zero then (
        Printf.eprintf "Failed to attach BPF program\n";
        raise (Exit 1));
      link
    in
    List.map attach_exn progs
  in

  at_exit (fun () ->
      List.iter (fun link -> F.bpf_link__destroy link |> ignore) links);

  (* Load maps *)
  let map =
    match F.bpf_object__find_map_by_name obj "rb" with
    | None ->
        Printf.eprintf "Failed to find map";
        raise (Exit 1)
    | Some m -> m
  in
  let rb_fd = F.bpf_map__fd map in

  at_exit (fun () ->
      match F.bpf_object__find_map_by_name obj "global_counter" with
      | None -> Printf.eprintf "Failed to find global_counter map"
      | Some global_counter ->
          let open Ctypes in
          let key = Ctypes.(allocate int 0) in
          let sz_key = Ctypes.(sizeof int |> Unsigned.Size_t.of_int) in
          let value = Ctypes.(allocate long Signed.Long.zero) in
          let sz_value = Ctypes.(sizeof long |> Unsigned.Size_t.of_int) in
          let flags = Unsigned.UInt64.zero in
          let res =
            F.bpf_map__lookup_elem global_counter (to_voidp key) sz_key
              (to_voidp value) sz_value flags
          in
          if res <> 0 then Printf.eprintf "Failed to lookup element got %d\n" res
          else
            Printf.printf
              "Failed to reserve space in Ringbuf, Dropped events %s\n"
              (Ctypes_value_printing.string_of long !@value));

  let handle_event =
    Ctypes.(
      coerce
        (Foreign.funptr ~runtime_lock:true ~check_errno:true
           (ptr void @-> ptr void @-> size_t @-> returning int))
        T.ring_buffer_sample_fn handle_event)
  in

  (* Set up ring buffer polling *)
  let rb =
    match
      F.ring_buffer__new rb_fd handle_event Ctypes.null
        Ctypes.(from_voidp T.ring_buffer_opts null)
    with
    | None ->
        Printf.eprintf "Failed to create ring buffer\n";
        raise (Exit 1)
    | Some rb -> rb
  in

  at_exit (fun () -> F.ring_buffer__free rb);

  while !exitting do
    let err = F.ring_buffer__poll rb 100 in
    match err with
    | e when e = Sys.sighup -> raise (Exit 0)
    | e when e < 0 ->
        Printf.eprintf "Error polling ring buffer, %d\n" e;
        raise (Exit 1)
    | _ -> ()
  done

let () =
  Eio_linux.run @@ fun env ->
  Eio.Switch.run (fun sw ->
      let tracefile = Eio.Path.( / ) (Eio.Stdenv.cwd env) "trace.fxt" in
      let out = Eio.Path.open_out ~sw ~create:(`Or_truncate 0o644) tracefile in
      Eio.Buf_write.with_flow out (fun w ->
          let fxt = W.of_writer w in
          let t = Ring_writer.make fxt in
          try run (handle_event t) with Exit i -> Printf.eprintf "exit %d%!" i))
