[@@@warning "-32"]

let src = Logs.Src.create "bpftrace" ~doc:"Internal OCaml bindings for bpftrace"

module Log = (val Logs.src_log src : Logs.LOG)

type t = {
  config : config list;
  mode : mode option;
  format : format option;
  output : string option;
  proc_management : proc_management option;
  flags : flag list;
  prog : prog;
}

and config =
  | PERF_RB_PAGES of int
  | LOG_SIZE of int
  | MAX_BPF_PROGS of int
  | MAX_PROBES of int
  | DEBUG_OUTPUT of bool

and mode = Line | Full
and format = Json | Text
and proc_management = PID of int | Command of string
and flag = No_warnings | Unsafe | K | KK | Debug | Debug_verbose

and prog = Script of string | Inline of string
[@@deriving show { with_path = false }]

let stringify_config = function
  | PERF_RB_PAGES i -> ("BPFTRACE_PERF_RB_PAGES", string_of_int i)
  | LOG_SIZE i -> ("BPFTRACE_LOG_SIZE", string_of_int i)
  | MAX_BPF_PROGS i -> ("BPFTRACE_MAX_BPF_PROGS", string_of_int i)
  | MAX_PROBES i -> ("BPFTRACE_MAX_PROBES", string_of_int i)
  | DEBUG_OUTPUT b ->
      ("BPFTRACE_DEBUG_OUTPUT", string_of_int (if b then 1 else 0))

let stringify_prog = function Script f -> f | Inline p -> "-e" ^ p
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

let make ?(config = []) ?mode ?format ?output ?proc_management ?(flags = [])
    prog =
  { config; mode; format; output; proc_management; flags; prog }

let quote_cmd { config; mode; format; output; proc_management; flags; prog } =
  let config' = List.map stringify_config config in
  let mode' = Option.map stringify_mode mode in
  let format' = Option.map stringify_format format in
  let proc_management' = Option.map stringify_proc_management proc_management in
  let optionals = List.filter_map Fun.id [ mode'; format'; proc_management' ] in
  let flags' = stringify_flags flags in
  (* Instead of using Bpftrace internal command to pipe output, we will
       hand pipe it so that the it is unbuffered and we can thread the
       events closer to realtime into the custom_events *)
  let prog' = stringify_prog prog in
  ( Filename.quote_command ?stdout:output "bpftrace"
      ((prog' :: optionals) @ flags'),
    config' )

let%expect_test "loaded" =
  make ~mode:Line ~format:Json ~proc_management:(PID 0)
    ~flags:[ No_warnings; Unsafe; K; KK; Debug; Debug_verbose ]
    (Inline "loaded_test.bt")
  |> quote_cmd |> fst |> print_string;
  [%expect
    {| 'bpftrace' '-eloaded_test.bt' '-Bline' '-fjson' '-p0' '--no-warnings' 'unsafe' '-k' '-kk' '-d' '-dd' >'trace.txt' |}]

let exec t =
  let cmd_s, config = quote_cmd t in
  (* Load environment first *)
  List.iter
    (fun (name, value) ->
      Log.debug (fun m -> m "%s=%s" name value);
      Unix.putenv name value)
    config;
  Log.debug (fun m -> m "Exec: %s" cmd_s);
  Unix.system cmd_s
