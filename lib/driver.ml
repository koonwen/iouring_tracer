open Unix

type program = Function | Binary of string

let runner ~(input : Bpftrace.arg) output (f : program) =
  if not Sys.unix then failwith "this system is not supported";
  if getuid () <> 0 then failwith "bpftrace needs to be run as root";
  match fork () with
  | 0 -> (
      (* Wait for bpftrace to initialize *)
      sleepf 2.0;
      match f with Function -> () | Binary bin -> ignore (system bin))
  | user_prog_pid -> (
      let output = Format.sprintf "%d_%s" user_prog_pid output in
      openfile output [ O_CLOEXEC; O_CREAT; O_TRUNC ] 0o600 |> close;
      match fork () with
      | 0 -> Runtime_events_hook.trace_poll output
      | trace_poll_pid ->
          at_exit (fun () ->
              kill trace_poll_pid Sys.sigint;
              kill user_prog_pid Sys.sigint);
          Bpftrace.(
            make ~output ~proc_management:(PID user_prog_pid) input
            |> exec |> ignore))

let start () = runner ~input:Bpftrace.Default "io_uring.events" Function
