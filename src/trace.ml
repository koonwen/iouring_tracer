open Ocaml_libbpf
module F = Libbpf.Functions
module T = Libbpf.Types
module W = Fxt.Write

exception Exit of int

(* Event type definition *)
open Ctypes

type event

let struct_event : event Ctypes_static.structure typ = Ctypes.structure "event"
let ( -: ) ty label = Ctypes.field struct_event label ty
let pid = int -: "pid"
let probe_t = int -: "probe"
let _ = Ctypes.seal struct_event

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
    match F.bpf_object__open "trace_uring_primative.bpf.o" with
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

  (* Find program by name *)
  let prog =
    match F.bpf_object__find_program_by_name obj "handle_complete" with
    | None ->
        Printf.eprintf "Failed to find bpf program\n";
        raise (Exit 1)
    | Some p -> p
  in

  (* Attach tracepoint *)
  let link = F.bpf_program__attach prog in
  if F.libbpf_get_error (Ctypes.to_voidp link) <> Signed.Long.zero then (
    Printf.eprintf "Failed to attach BPF program\n";
    raise (Exit 1));

  at_exit (fun () -> F.bpf_link__destroy link |> ignore);

  (* Load maps *)
  let map =
    match F.bpf_object__find_map_by_name obj "rb" with
    | None ->
        Printf.eprintf "Failed to find map";
        raise (Exit 1)
    | Some m -> m
  in
  let rb_fd = F.bpf_map__fd map in

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

          (* Describe event handler *)
          let handle_event =
            let open Ctypes in
            let _handle_event _ctx data _sz =
              let ts = Unix.gettimeofday () |> Int64.of_float in
              let thread =
                {
                  Fxt.Write.pid = Int64.of_int @@ Unix.getpid ();
                  tid = Thread.self () |> Thread.id |> Int64.of_int;
                }
              in
              let event = !@(from_voidp struct_event data) in
              let pid = getf event pid in
              let _probe_t = getf event probe_t in
              W.instant_event fxt ~name:"hello" ~category:"bpf" ~thread ~ts;
              Printf.printf "Handle_event called from pid=%d\n%!" pid;
              0
            in
            coerce
              (Foreign.funptr ~runtime_lock:true ~check_errno:true
                 (ptr void @-> ptr void @-> size_t @-> returning int))
              T.ring_buffer_sample_fn _handle_event
          in

          try run handle_event with Exit i -> Printf.eprintf "exit %d%!" i))
