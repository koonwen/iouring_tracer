open Ocaml_libbpf
module F = Primative.Functions
module T = Primative.Types
module W = Fxt.Write
module B = Bindings

type uring_bpf
external uring_bpf__open_and_load: unit -> uring_bpf = "caml_uring_bpf__open_and_load"
external uring_bpf__destroy: uring_bpf -> unit = "caml_uring_bpf__destroy"
external uring_bpf__attach: uring_bpf -> int = "caml_uring_bpf__attach"
external uring_bpf__get_rb: uring_bpf -> T.bpf_map Ctypes.structure Ctypes.ptr = "caml_uring_bpf__get_rb"

type poll_behaviour = Poll of int | Busywait [@@warning "-37"]

exception Exit of int

type handler = unit Ctypes.ptr -> unit Ctypes.ptr -> Unsigned.size_t -> int

let pipeline (handlers : handler list) ctx data size_t =
  List.iter
    (fun handler ->
      match handler ctx data size_t with
      | 0 -> () (* result ok *)
      | e -> raise (Exit e))
    handlers;
  (* Return 0 *)
  0

let load_run ~poll_behaviour handlers =
  (* Implicitly bump RLIMIT_MEMLOCK to create BPF maps *)
  F.libbpf_set_strict_mode T.LIBBPF_STRICT_AUTO_RLIMIT_MEMLOCK;

  (* Set signal handlers *)
  let exitting = ref true in
  let sig_handler = Sys.Signal_handle (fun _ -> exitting := false) in
  Sys.(set_signal sigint sig_handler);
  Sys.(set_signal sigterm sig_handler);

  (* Create and Load skeleton *)
  let skel = uring_bpf__open_and_load () in

  at_exit (fun () -> uring_bpf__destroy skel);

  (* Attach tracepoint *)
  if uring_bpf__attach skel <> 0 then (
    Printf.eprintf "Failed to attach BPF skeleton\n";
    raise (Exit 1))
  else Printf.printf "Successfully started!\n%!";

  let handle_event_coerce =
    let open Ctypes in
    let handler = pipeline handlers in
    coerce
      (Foreign.funptr ~runtime_lock:true ~check_errno:true
         (ptr void @-> ptr void @-> size_t @-> returning int))
      T.ring_buffer_sample_fn handler
  in

  let rb = uring_bpf__get_rb skel in
  let rb_fd = F.bpf_map__fd rb in

  (* Set up ring buffer polling *)
  let rb =
    match
      F.ring_buffer__new rb_fd handle_event_coerce Ctypes.null
        Ctypes.(from_voidp T.ring_buffer_opts null)
    with
    | None ->
        Printf.eprintf "Failed to create ring buffer\n";
        raise (Exit 1)
    | Some rb -> rb
  in

  let cb = ref 0 in

  at_exit (fun () ->
      F.ring_buffer__free rb;
      Printf.printf "Consumed %d events\n" !cb);

  (match poll_behaviour with
  | Poll timeout ->
      while !exitting do
        let err = F.ring_buffer__poll rb timeout in
        match err with
        | e when e = Sys.sighup -> raise (Exit 0)
        | e when e < 0 ->
            Printf.eprintf "Error polling ring buffer, %d\n" e;
            raise (Exit 1)
        | i -> cb := !cb + i
      done
  | Busywait -> (
      match F.ring_buffer__consume rb with
      | i when i >= 0 -> cb := !cb + i
      | e when e = Sys.sighup -> raise (Exit 0)
      | e ->
          Printf.eprintf "Error polling ring buffer, %d\n" e;
          raise (Exit 1)));
  raise (Exit 0)

let run ?(tracefile = "trace.fxt") ?(poll_behaviour = Poll 100) handlers =
  Eio_linux.run @@ fun env ->
  Eio.Switch.run (fun sw ->
      let output_file = Eio.Path.( / ) (Eio.Stdenv.cwd env) tracefile in
      let out =
        Eio.Path.open_out ~sw ~create:(`Or_truncate 0o644) output_file
      in
      Eio.Buf_write.with_flow out (fun w ->
          let _fxt = W.of_writer w in
          try load_run ~poll_behaviour handlers
          with Exit i -> Printf.eprintf "exit %d%!" i))
