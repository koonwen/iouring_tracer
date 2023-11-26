let trace_prog_error () =
  failwith "Traced program error"

let () = Obpftrace.Driver.kprobes trace_prog_error
