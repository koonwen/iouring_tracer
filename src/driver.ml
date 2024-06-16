open Ocaml_libbpf
module F = C.Functions
module T = C.Types
module W = Fxt.Write
module B = Bindings
module RW = Ring_writer
module M = Bpf_maps.Make (Bpf_maps.IntConv) (Bpf_maps.LongConv)

type poll_behaviour = Poll of int | Busywait

exception Exit of int

let load_run ~poll_behaviour ~bpf_object_path ~bpf_program_names
    ~(writer : Ring_writer.t) callback =
  with_bpf_object_open_load_link ~obj_path:bpf_object_path
    ~program_names:bpf_program_names (fun obj _links ->
      (* Set signal handlers *)
      let exitting = ref true in
      let sig_handler = Sys.Signal_handle (fun _ -> exitting := false) in
      Sys.(set_signal sigint sig_handler);
      Sys.(set_signal sigterm sig_handler);

      let callback_w_ctx = callback writer in
      let map = bpf_object_find_map_by_name obj "rb" in
      let rb = Bpf_maps.RingBuffer.init map ~callback:callback_w_ctx in

      let cb = ref 0 in

      (match poll_behaviour with
      | Poll timeout ->
          while !exitting do
            match Bpf_maps.RingBuffer.poll rb ~timeout with
            | Ok i -> cb := !cb + i
            (* Ctrl-C will cause Error EINTR *)
            | Error e when e = Sys.sighup -> exitting := false
            | Error e ->
                Printf.eprintf "Error polling ring buffer, %d\n%!" e;
                raise (Exit 1)
          done
      | Busywait -> (
          match Bpf_maps.RingBuffer.consume rb with
          | Ok i -> cb := !cb + i
          | Error e when e = Sys.sighup -> raise (Exit 0)
          | Error e ->
              Printf.eprintf "Error polling ring buffer, %d\n%!" e;
              raise (Exit 1)));

      (* Print globals at the end *)
      let globals = bpf_object_find_map_by_name obj "globals" in
      let total = M.bpf_map_lookup_value globals 1 |> Result.get_ok in
      let dropped = M.bpf_map_lookup_value globals 2 |> Result.get_ok in
      let unrelated = M.bpf_map_lookup_value globals 3 |> Result.get_ok in
      let skipped = M.bpf_map_lookup_value globals 4 |> Result.get_ok in
      let str_of_long clong =
        Ctypes_value_printing.string_of Ctypes.long clong
      in
      Printf.printf
        "\n\
         User-space consumed %d events\n\
         Kernel-space recorded %s total events, %s dropped events, %s \
         unrelated events, %s skipped events\n"
        !cb (str_of_long total) (str_of_long dropped) (str_of_long skipped)
        (str_of_long unrelated);

      raise (Exit 0))

let run ?(tracefile = "trace.fxt") ?(poll_behaviour = Poll 100) ~bpf_object_path
    ~bpf_program_names callback =
  Eio_linux.run @@ fun env ->
  Eio.Switch.run (fun sw ->
      let output_file = Eio.Path.( / ) (Eio.Stdenv.cwd env) tracefile in
      let out =
        Eio.Path.open_out ~sw ~create:(`Or_truncate 0o644) output_file
      in
      Eio.Buf_write.with_flow out (fun w ->
          let writer = Ring_writer.make (W.of_writer w) in
          try
            load_run ~poll_behaviour ~bpf_object_path ~bpf_program_names ~writer
              callback
          with Exit i -> Printf.eprintf "exit %d\n" i))
