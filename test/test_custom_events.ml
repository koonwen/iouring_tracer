open Obpftrace

let bpftrace_ev_handler _i _ts ty s =
  match Runtime_events_hook.User.tag ty with
  | Runtime_events_hook.Io_uring -> Printf.printf "%s\n%!" s
  | _ -> ()

let () =
  Driver.runner ~input:Bpftrace.Default ~ev_handler_op:bpftrace_ev_handler
    (Function (fun () -> Unix.sleepf 1.0))
