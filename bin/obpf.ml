open Obpftrace
open Cmdliner

(* Find .bt scripts *)
let bt_file_mappings =
  List.filter (fun filename -> Filename.check_suffix filename "bt") Bt.file_list
  |> List.map (fun filename ->
         (filename, Bpftrace.Inline (Bt.read filename |> Option.get)))

let default = List.assoc "uring_spans.bt" bt_file_mappings

(* Entry point *)
let obpf_gen () = ()

let obpf_trace log_level output prog =
  Fmt_tty.setup_std_outputs ();
  Logs.set_reporter (Logs_fmt.reporter ());
  Logs.set_level log_level;
  Driver.(runner ?output prog)

let gen_cmd =
  let info = Cmd.info "gen" in
  Cmd.v info Term.(const obpf_gen $ const ())

let trace_cmd =
  let output =
    let doc = "write trace log to FILE" in
    Arg.(value & opt (some string) None & info [ "o" ] ~docv:"FILE" ~doc)
  in
  let prog =
    let bpf_conv =
      let parser s =
        match List.assoc_opt s bt_file_mappings with
        | Some prog -> Result.ok prog
        | None ->
            if Sys.file_exists s then Result.ok (Bpftrace.Script s)
            else Result.error (`Msg "No such script")
      in
      let printer = Bpftrace.pp_prog in
      Arg.conv (parser, printer)
    in
    let doc =
      let options = Arg.doc_alts (List.map fst bt_file_mappings) in
      Format.sprintf
        "path to bpftrace program. If absent, defaults to dumping all io_uring \
         probes in strace style. Options are %s"
        options
    in
    Arg.(

      value & opt bpf_conv default
      & info ~absent:"$(b,uring_spans.bt)" [ "p" ] ~docv:"FILE" ~doc)
  in
  let doc = "Program tracer tool using bpftrace" in
  let man = [ `S Manpage.s_description ] in
  let info = Cmd.info "trace" ~version:"%%VERSION%%" ~doc ~man in
  Cmd.v info Term.(const obpf_trace $ Logs_cli.level () $ output $ prog)

let obpf =
  let doc = Cmd.info "obpf" in
  Cmd.group doc [ gen_cmd; trace_cmd ]

let () = exit (Cmd.eval obpf)
