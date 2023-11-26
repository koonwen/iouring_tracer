open Unix

type 'a program = Binary of string | Function of (unit -> 'a)

let read_file filename =
  In_channel.with_open_bin filename (fun ic -> In_channel.input_all ic)

let runner ~bpf_prog ?log_file (f : 'a program) =
  if not Sys.unix then failwith "this system is not supported";
  if getuid () <> 0 then failwith "bpftrace needs to be run as root";
  let prog_op =
    if Sys.file_exists bpf_prog then Some (read_file bpf_prog)
    else Bpftrace_progs.read bpf_prog
  in
  match prog_op with
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
          | WEXITED e | WSIGNALED e | WSTOPPED e -> _exit e)
      (* Parent *)
      | child ->
          Unix.sleepf 1.;
          at_exit (fun () -> kill child Sys.sigint);
          (* Need to figure out how to run this in a less privileged environment *)
          (match f with
          | Function f -> (
              try f ()
              with _ ->
                Printf.printf "Something went wrong with traced program%!")
          | Binary bin -> system bin |> ignore);
          (* This isn't the behaviour we want, should kill child when
             traced program ends or error occurs, adding `kill child
             sigint` exhibits funny behaviour by orphaning the child
             likely because of the _exit e. Manual cancellation is the
             current way to stop all processes *)
          wait () |> ignore)

let tracepoints f = runner ~bpf_prog:"tracepoints.bt" (Function f)
let kprobes f = runner ~bpf_prog:"kprobes.bt" (Function f)
