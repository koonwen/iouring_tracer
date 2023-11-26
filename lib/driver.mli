type 'a program = Binary of string | Function of (unit -> 'a)

val runner : bpf_prog:string -> ?log_file:string -> unit program -> unit
val kprobes : (unit -> unit) -> unit
val tracepoints : (unit -> unit) -> unit
