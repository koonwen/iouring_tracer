open Unix

type 'a program = Binary of string | Function of (unit -> 'a)

let runner ~(input : Bpftrace.arg) ?log_file ?ev_handler_op (f : 'a program) =
  if not Sys.unix then failwith "this system is not supported";
  if getuid () <> 0 then failwith "bpftrace needs to be run as root";
  let child_alive c =
    match Unix.waitpid [ Unix.WNOHANG ] c with
    | 0, _ -> true
    | p, _ when p = c -> false
    | _, _ -> assert false
  in
  match f with
  | Binary bin -> (
      match fork () with
      (* Child *)
      | 0 ->
          let cmd =
            Bpftrace.make ?output:log_file ~proc_management:(Command bin) input
          in
          Bpftrace.exec cmd |> ignore
      (* Parent *)
      | child ->
          Unix.sleepf 1.0;
          let filename = Option.value ~default:"trace.txt" log_file in
          Runtime_events_hook.trace_poll ?ev_handler_op filename (fun () ->
              child_alive child))
  | Function f -> (
      match fork () with
      (* Child *)
      | 0 -> f ()
      (* Parent *)
      | child1 -> (
          match fork () with
          | 0 ->
              let filename = Option.value ~default:"trace.txt" log_file in
              Runtime_events_hook.trace_poll ?ev_handler_op filename (fun () ->
                  child_alive child1)
          | child2 -> (
              let cmd =
                Bpftrace.make ?output:log_file ~proc_management:(PID child1)
                  input
              in
              match Bpftrace.exec cmd with
              | WEXITED _e | WSIGNALED _e | WSTOPPED _e ->
                  kill child1 Sys.sigint;
                  kill child2 Sys.sigint)))
