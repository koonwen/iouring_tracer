open Unix

let runner ?output (prog : Bpftrace.prog) =
  if not Sys.unix then failwith "this system is not supported";
  if getuid () <> 0 then failwith "bpftrace needs to be run as root";
  match Bpftrace.(make ?output prog |> exec) with
  | WEXITED i -> Printf.printf "[Exited: %d]" i
  | WSIGNALED i -> Printf.printf "[Signalled: %d]" i
  | WSTOPPED i -> Printf.printf "[Stopped: %d]" i

(* let root_runner ?output (prog : Bpftrace.prog) = *)
(*   if not Sys.unix then failwith "this system is not supported"; *)
(*   if getuid () <> 0 then failwith "bpftrace needs to be run as root"; *)

(*   match fork () with *)
(*   | 0 -> ( *)
(*       match f with Binary bin -> system bin |> ignore | Function f -> f ()) *)
(*   | bpftrace_pid -> *)
(*       at_exit (fun () -> *)
(*           kill trace_poll_pid Sys.sigint; *)
(*           kill bpftrace_pid Sys.sigint); *)
(*       Bpftrace.( *)
(*         make ?output ~proc_management:(PID bpftrace_pid) input |> exec |> ignore) *)
