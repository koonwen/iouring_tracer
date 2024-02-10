open Obpftrace
open Cmdliner

(* Entry point *)
let obpf_gen () = ()

let obpf_trace input trace_file bin =
  Logs.set_reporter (Logs_fmt.reporter ());
  Logs.set_level (Some Logs.Debug);
  Driver.(runner ~log_file:trace_file ~input (Binary bin))

let gen_cmd =
  let info = Cmd.info "gen" in
  Cmd.v info Term.(const obpf_gen $ const ())

let trace_cmd =

  let log_file =
    let doc = "write trace log to FILE" in
    Arg.(value & opt file "trace.txt" & info [ "l" ] ~docv:"FILE" ~doc)
  in
  let input =
    let bpf_conv =
      Arg.conv
        ( (fun s ->
            if Sys.file_exists s then Stdlib.Result.ok (Bpftrace.File s)
            else Stdlib.Result.ok (Bpftrace.Inline s)),
          Bpftrace.pp_arg )
    in
    let doc = "path to bpftrace program" in
    Arg.(
      value
      & opt bpf_conv (Bpftrace.File "tracepoints.bt")
      & info [ "p" ] ~docv:"FILE" ~doc)
  in
  let program =
    let doc = "program to trace" in
    Arg.(required & pos 0 (some string) None & info [] ~docv:"PROGRAM" ~doc)
  in
  let doc = "Program tracer tool using bpftrace" in
  let man = [ `S Manpage.s_description ] in
  let info = Cmd.info "trace" ~version:"%%VERSION%%" ~doc ~man in
  Cmd.v info Term.(const obpf_trace $ input $ log_file $ program)

let obpf =
  let doc = Cmd.info "obpf" in
  Cmd.group doc [ gen_cmd; trace_cmd ]

let () = exit (Cmd.eval obpf)
