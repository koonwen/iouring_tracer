(* Entry point *)
let obpf bpftrace_prog trace_file bin =
  Obpftrace.Driver.(
    runner ~log_file:trace_file ~bpf_prog:bpftrace_prog (Binary bin))

open Cmdliner

let gen_cmd =
  let info = Cmd.info "gen" in
  Cmd.v info Term.(const ())

let log_file =
  let doc = "write trace log to FILE" in
  Arg.(value & opt file "trace.txt" & info [ "l" ] ~docv:"FILE" ~doc)

let bpftrace_prog =
  let doc = "path to bpftrace program" in
  Arg.(value & opt file "tracepoints.bt" & info [ "p" ] ~docv:"FILE" ~doc)

let program =
  let doc = "program to trace" in
  Arg.(required & pos 0 (some string) None & info [] ~docv:"PROGRAM" ~doc)

let trace_cmd =
  let doc = "Program tracer tool using bpftrace" in
  let man = [ `S Manpage.s_description ] in
  let info = Cmd.info "trace" ~version:"%%VERSION%%" ~doc ~man in
  Cmd.v info Term.(const obpf $ bpftrace_prog $ log_file $ program)

let trace =
  let doc = Cmd.info "obpf" in
  Cmd.group doc [ gen_cmd; trace_cmd ]

let () = exit (Cmd.eval trace)
