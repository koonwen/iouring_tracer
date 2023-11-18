open Unix

type 'a program = Binary of string | Function of (unit -> 'a)

let runner bpf_prog ?log_file (f : 'a program) =
  if not Sys.unix then failwith "this system is not supported";
  if getuid () <> 0 then failwith "uring_trace needs to be run as root";
  match Bpftrace_progs.read bpf_prog with
  | None -> failwith "Bpftrace program not found"
  | Some prog -> (
      match fork () with
      (* Child *)
      | 0 -> (
          let log = Option.value ~default:"trace.txt" log_file in
          let cmd =
            "bpftrace -e" ^ Filename.quote_command prog [] ~stdout:log
          in
          match system cmd with
          | WEXITED e | WSIGNALED e | WSTOPPED e ->
              Printf.printf "Error occurred in bpftrace";
              _exit e)
      (* Parent *)
      | _ -> (
          Unix.sleepf 1.;
          (* Need to figure out how to run this in a less privileged environment *)
          match f with
          | Function f -> ( try f () with _ -> kill 0 Sys.sigint)
          | Binary bin -> (
              match system bin with
              | WEXITED e | WSIGNALED e | WSTOPPED e ->
                  Printf.printf "Error occurred in binary";
                  kill 0 Sys.sigint;
                  _exit e)))

let tracepoints f = runner "tracepoints.bt" (Function f)
let kprobes f = runner "kprobes.bt" (Function f)
