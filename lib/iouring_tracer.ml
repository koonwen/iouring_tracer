(* Main function to spawn tracing process *)
open Unix

type program = Binary of string | Function of (unit -> unit)

let runner bpf_prog ?log_file (f : program) =
  if not Sys.unix then failwith "this system is not supported";
  if getuid () <> 0 then failwith "uring_trace needs to be run as root";
  match Bpftrace_progs.read bpf_prog with
  | None -> failwith "Program not found"
  | Some prog -> (
      let log = Option.value ~default:"trace.txt" log_file in
      let cmd = "bpftrace -e" ^ Filename.quote_command prog [] ~stdout:log in
      let pid = fork () in
      match pid with
      | 0 -> (
          match system cmd with
          | WEXITED _ | WSIGNALED _ | WSTOPPED _ ->
              Printf.printf "bpftrace failed";
              _exit 0)
      | _ -> (
          Unix.sleepf 1.;
          (* Need to run this in a less privileged environment *)
          match f with
          | Binary f ->
              let _pid = create_process f [||] stdin stdout stderr in
              wait () |> ignore
          | Function f -> ( try f () with _ -> kill pid Sys.sigint)))

let tracepoints f = runner "tracepoints.bt" (Function f)
let kprobes f = runner "kprobes.bt" (Function f)
