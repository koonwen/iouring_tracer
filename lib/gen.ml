(* Generator for bpftrace files *)

let entry =
  "BEGIN {\n\ttime('[%H:%M:%S]: ');\n\tprintf('Tracing IO_uring kprobes...\\n');\n}"

let gen = Out_channel.with_open_bin "bpfgen.bt" (fun oc ->
    let fmt = Format.formatter_of_out_channel oc in
    Format.fprintf fmt "@[%s@]@." entry
  )
