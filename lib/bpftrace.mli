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

val pp_arg: Format.formatter -> arg -> unit
