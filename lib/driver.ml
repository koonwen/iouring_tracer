open Unix

type 'a program = Binary of string | Function of (unit -> 'a)

let runner ~(input : Bpftrace.arg) ?(output = "io_uring.events") ?ev_handler_op
    (f : 'a program) =
  if not Sys.unix then failwith "this system is not supported";
  if getuid () <> 0 then failwith "bpftrace needs to be run as root";
  openfile output [ O_CLOEXEC; O_CREAT; O_TRUNC ] 0o600 |> close;
  match fork () with
  | 0 -> (
      match f with Binary bin -> system bin |> ignore | Function f -> f ())
  | bpftrace_pid -> (
      match fork () with
      | 0 -> Runtime_events_hook.trace_poll ?ev_handler_op output
      | trace_poll_pid ->
          at_exit (fun () ->
              kill trace_poll_pid Sys.sigint;
              kill bpftrace_pid Sys.sigint);
          Bpftrace.(
            make ~output ~proc_management:(PID bpftrace_pid) input
            |> exec |> ignore))
