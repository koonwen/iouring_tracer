type t

type config =
  | PERF_RB_PAGES of int
  | LOG_SIZE of int
  | MAX_BPF_PROGS of int
  | MAX_PROBES of int
  | DEBUG_OUTPUT of bool

type prog = Script of string | Inline of string
type mode = Line | Full
type format = Json | Text
type proc_management = PID of int | Command of string
type flag = No_warnings | Unsafe | K | KK | Debug | Debug_verbose

val make :
  ?config:config list ->
  ?mode:mode ->
  ?format:format ->
  ?output:string ->
  ?proc_management:proc_management ->
  ?flags:flag list ->
  prog ->
  t

val exec : t -> Unix.process_status
val pp_prog : Format.formatter -> prog -> unit
