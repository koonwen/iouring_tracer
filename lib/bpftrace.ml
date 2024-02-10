[@@@warning "-32"]
let src = Logs.Src.create "bpftrace" ~doc:"Internal OCaml bindings for bpftrace"

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

let stringify_arg = function File f -> f | Inline p -> "-e" ^ p
let stringify_mode mode = "-B" ^ String.lowercase_ascii (show_mode mode)
let stringify_format format = "-f" ^ String.lowercase_ascii (show_format format)
let stringify_output output = "-o" ^ output

let stringify_proc_management = function
  | PID i -> "-p" ^ Int.to_string i
  | Command c -> "-c" ^ c

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
  let proc_management' = Option.map stringify_proc_management proc_management in
  let optionals =
    List.filter_map Fun.id [ mode'; format'; output'; proc_management' ]
  in
  let flags' = stringify_flags flags in
  let arg' = stringify_arg arg in
  Filename.quote_command "bpftrace" ((arg' :: optionals) @ flags')

let%expect_test "default" =
  make (File "default_test.bt") |> quote_cmd |> print_string;
  [%expect {| 'bpftrace' 'default_test.bt' '-otrace.txt' |}]

let%expect_test "loaded" =
  make ~mode:Line ~format:Json ~proc_management:(PID 0)
    ~flags:[ No_warnings; Unsafe; K; KK; Debug; Debug_verbose ]
    (Inline "loaded_test.bt")
  |> quote_cmd |> print_string;
  [%expect
    {| 'bpftrace' '-eloaded_test.bt' '-Bline' '-fjson' '-otrace.txt' '-p0' '--no-warnings' 'unsafe' '-k' '-kk' '-d' '-dd' |}]

let exec t =
  let cmd_s = quote_cmd t in
  Log.debug (fun m -> m "Exec: %s" cmd_s);
  Unix.system cmd_s
