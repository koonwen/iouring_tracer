open Unix

let runner ?output (prog: Bpftrace.prog) =
  if not Sys.unix then failwith "this system is not supported";
  if getuid () <> 0 then failwith "bpftrace needs to be run as root";
  match Bpftrace.( make ?output prog |> exec) with
  | WEXITED i -> Printf.printf "[Exited: %d]" i
  | WSIGNALED i -> Printf.printf "[Signalled: %d]" i
  | WSTOPPED i -> Printf.printf "[Stopped: %d]" i
