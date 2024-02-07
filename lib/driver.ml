open Unix

type 'a program = Binary of string | Function of (unit -> 'a)

module Bpftrace : sig
  type t
  type arg = File of string | Inline of string
  type mode = Line | Full
  type format = Json | Text
  type proc_management = PID of int | Command of string
  type flag = No_warnings | Unsafe | K | KK | Debug | Debug_verbose

  val make :
    ?mode:mode ->
    ?format:format ->
    ?output:string ->
    ?proc_management:proc_management ->
    ?flags:flag list ->
    arg ->
    t

  val quote_cmd : t -> string
  val exec : t -> Unix.process_status
end = struct
  [@@@warning "-32"]

  let src =
    Logs.Src.create "bpftrace" ~doc:"Internal OCaml bindings for bpftrace"

  module Log = (val Logs.src_log src : Logs.LOG)

  type t = {
    (* options *)
    mode : mode option;
    format : format option;
    output : string option;
    proc_management : proc_management option;
    (* flags *)
    flags : flag list;
    (* args *)
    arg : arg;
  }

  and mode = Line | Full
  and format = Json | Text
  and proc_management = PID of int | Command of string
  and flag = No_warnings | Unsafe | K | KK | Debug | Debug_verbose

  and arg = File of string | Inline of string
  [@@deriving show { with_path = false }]

  let stringify_arg = function File f -> f | Inline p -> "-e " ^ p
  let stringify_mode mode = "-B" ^ String.lowercase_ascii (show_mode mode)

  let stringify_format format =
    "-f" ^ String.lowercase_ascii (show_format format)

  let stringify_output output = "-o " ^ output

  let stringify_proc_management = function
    | PID i -> "-p " ^ Int.to_string i
    | Command c -> "-c " ^ c

  let stringify_flags flags =
    List.map
      (function
        | No_warnings -> "--no-warnings"
        | Unsafe -> "unsafe"
        | K -> "-k"
        | KK -> "-kk"
        | Debug -> "-d"
        | Debug_verbose -> "-dd")
      flags

  let make ?mode ?format ?(output = "trace.txt") ?proc_management ?(flags = [])
      arg =
    { mode; format; output = Option.some output; proc_management; flags; arg }

  let quote_cmd { mode; format; output; proc_management; flags; arg } =
    let mode' = Option.map stringify_mode mode in
    let format' = Option.map stringify_format format in
    let output' = Option.map stringify_output output in
    let proc_management' =
      Option.map stringify_proc_management proc_management
    in
    let optionals =
      List.filter_map Fun.id [ mode'; format'; output'; proc_management' ]
    in
    let flags' = stringify_flags flags in
    let arg' = stringify_arg arg in
    Filename.quote_command "bpftrace" ((arg' :: optionals) @ flags')

  let%expect_test "default" =
    make (File "default_test.bt") |> quote_cmd |> print_string;
    [%expect {| 'bpftrace' 'default_test.bt' '-o trace.txt' |}]

  let%expect_test "loaded" =
    make ~mode:Line ~format:Json ~proc_management:(PID 0)
      ~flags:[ No_warnings; Unsafe; K; KK; Debug; Debug_verbose ]
      (Inline "loaded_test.bt")
    |> quote_cmd |> print_string;
    [%expect {| 'bpftrace' '-e loaded_test.bt' '-Bline' '-fjson' '-o trace.txt' '-p 0' '--no-warnings' 'unsafe' '-k' '-kk' '-d' '-dd' |}]

  let exec t =
    let cmd_s = quote_cmd t in
    Log.debug (fun m -> m "Exec: %s" cmd_s);
    Unix.system cmd_s
end

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
