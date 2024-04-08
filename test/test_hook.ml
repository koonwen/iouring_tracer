let src = Logs.Src.create "test logs" ~doc:"logging for test suites"

module Log = (val Logs.src_log src : Logs.LOG)

let () =
  Fmt_tty.setup_std_outputs ();
  Logs.set_reporter (Logs_fmt.reporter ());
  Logs.set_level (Some Debug)

let ring_ctx_manager ?polling_timeout ~queue_depth f =
  Log.debug (fun m -> m "init ring: queue_depth=%d" queue_depth);
  let ring = Uring.create ?polling_timeout ~queue_depth () in
  let res = f ring in
  Uring.exit ring;
  res

let read_async (files : string list) =
  ring_ctx_manager ~queue_depth:(List.length files) (fun ring ->
      let bufs =
        List.mapi
          (fun i file ->
            let fd = Unix.(openfile file [ O_RDONLY ] 0o666) in
            let fstat = Unix.fstat fd in
            let buf = Cstruct.create fstat.st_size in
            Log.info (fun m -> m "File: %s, sz:%d" file fstat.st_size);
            match
              Uring.read ring ~file_offset:Optint.Int63.zero fd buf (i, file)
            with
            | None -> failwith "Uring.read failed"
            | Some _ -> buf)
          files
      in
      Logs.debug (fun m -> m "%a" Uring.Stats.pp (Uring.get_debug_stats ring));
      List.iter
        (fun _ ->
          match Uring.wait ~timeout:1.0 ring with
          | None -> failwith "Something went wrong"
          | Some { data; _ } ->
              let i, file = data in
              Printf.printf "File: %s, pos = %d\n%!" file i)
        bufs)

let () =
  let dir = "/home/koonwen/Repos/iouring_tracer/test" in
  let f = dir ^ "/" ^ "sample.txt" in
  Hook.run (fun () -> read_async [f; f])
