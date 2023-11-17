(* Entry point *)
let iou trace_file f =
  let bpftrace_prog = "tracepoints.bt" in
  Iouring_tracer.Driver.(runner ~log_file:trace_file bpftrace_prog (Binary f))

open Cmdliner

let log_file =
  let doc = "write trace log to FILE" in
  Arg.(value & opt file "trace.txt" & info [ "-l" ] ~docv:"FILE" ~doc)

let program =
  let doc = "program to execute" in
  Arg.(required & pos 0 (some string) None & info [] ~docv:"PROGRAM" ~doc)

let cmd =
  let doc = "IO-uring tracer" in
  let man = [ `S Manpage.s_description ] in
  let info = Cmd.info "iou" ~version:"%%VERSION%%" ~doc ~man in
  Cmd.v info Term.(const iou $ log_file $ program)

let () = exit (Cmd.eval cmd)
