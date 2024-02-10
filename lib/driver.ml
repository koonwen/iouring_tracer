open Unix

type 'a program = Binary of string | Function of (unit -> 'a)

let read_file filename =
  In_channel.with_open_bin filename (fun ic -> In_channel.input_all ic)

let runner ~(input : Bpftrace.arg) ?log_file (f : 'a program) =
  if not Sys.unix then failwith "this system is not supported";
  if getuid () <> 0 then failwith "bpftrace needs to be run as root";
  match f with
  | Binary bin ->
      let cmd =
        Bpftrace.make ?output:log_file ~proc_management:(Command bin) input
      in
      Bpftrace.exec cmd |> ignore
  | Function f -> (
      match fork () with
      (* Child *)
      | 0 -> f ()
      (* Parent *)
      | child -> (
          let cmd =
            Bpftrace.make ?output:log_file ~proc_management:(PID child) input
          in
          match Bpftrace.exec cmd with
          | WEXITED _e | WSIGNALED _e | WSTOPPED _e -> kill child Sys.sigint))

(* let tracepoints f = runner ~bpf_prog:"tracepoints.bt" (Function f) *)
(* let kprobes f = runner ~bpf_prog:"kprobes.bt" (Function f) *)
