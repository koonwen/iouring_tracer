open Ocaml_libbpf
module F = C.Functions
module T = C.Types
module B = Bindings
module W = Writer

type poll_behaviour = Poll of int | Busywait

exception Exit of int

let load_run ~poll_behaviour ~bpf_object_path ~bpf_program_names
    ~(writer : Writer.t) callback =
  with_bpf_object_open_load_link ~obj_path:bpf_object_path
    ~program_names:bpf_program_names (fun obj _links ->
      (* Set signal handlers *)
      let cont = ref true in
      let sig_handler = Sys.Signal_handle (fun _ -> cont := false) in
      Sys.(set_signal sigint sig_handler);
      Sys.(set_signal sigterm sig_handler);

      let callback_w_ctx = callback writer in
      let map = bpf_object_find_map_by_name obj "rb" in
      Ocaml_libbpf_maps.RingBuffer.init map ~callback:callback_w_ctx (fun rb ->
          let cb = ref 0 in

          (match poll_behaviour with
          | Poll timeout ->
              while !cont do
                match Ocaml_libbpf_maps.RingBuffer.poll rb ~timeout with
                (* Ctrl-C will cause -EINTR exception *)
                | e when e = Sys.sigint -> cont := false
                | i -> cb := !cb + i
              done
          | Busywait -> (
              match Ocaml_libbpf_maps.RingBuffer.consume rb with
              | e when e = Sys.sigint -> cont := false
              | i -> cb := !cb + i));

          let globals = bpf_object_find_map_by_name obj "globals" in
          let lookup_globals idx =
            bpf_map_lookup_value ~key_ty:Ctypes.int ~val_ty:Ctypes.long
              ~val_zero:Signed.Long.zero globals idx
          in
          (* Print globals at the end *)
          let total = lookup_globals 1 in
          let lost = lookup_globals 2 in
          let unrelated = lookup_globals 3 in
          let skipped = lookup_globals 4 in
          let str_of_long clong =
            Ctypes_value_printing.string_of Ctypes.long clong
          in
          Printf.printf
            "\n\
             User-space consumed %d events\n\
             Kernel-space recorded %s total events, %s lost events, %s \
             unrelated events, %s skipped events\n"
            !cb (str_of_long total) (str_of_long lost) (str_of_long skipped)
            (str_of_long unrelated)))

let run ?(tracefile = "trace.fxt") ?(poll_behaviour = Poll 100) ~bpf_object_path
    ~bpf_program_names callback =
  Eio_linux.run @@ fun env ->
  Eio.Switch.run (fun sw ->
      let output_file = Eio.Path.( / ) (Eio.Stdenv.cwd env) tracefile in
      let out =
        Eio.Path.open_out ~sw ~create:(`Or_truncate 0o644) output_file
      in
      Eio.Buf_write.with_flow out (fun w ->
          let writer = W.make (W.of_writer w) in
          try
            load_run ~poll_behaviour ~bpf_object_path ~bpf_program_names ~writer
              callback
          with Exit i -> Printf.eprintf "exit %d\n" i))
