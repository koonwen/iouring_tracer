open Intermediate

(* Generator for bpftrace files *)
let pp_fun ~name ~lines =
  let open Format in
  let pp_line ppf = fprintf ppf "\t%s;" in
  asprintf "%s {@,%a@,}@." name
    (pp_print_list ~pp_sep:pp_print_newline pp_line)
    lines

module Builtins : sig
  type t = string

  val time : t
  val printf : string -> string list -> t
end = struct
  type t = string

  let time = "time(\"[%H:%M:%S]\")"

  let printf fmt args =
    let open Format in
    match args with
    | [] -> sprintf "printf(\"%s\")" fmt
    | l ->
        let args = String.concat ", " l in
        sprintf "printf(\"%s\", %s)" fmt args
end

let entry text =
  let lines = Builtins.[ time; printf text [] ] in
  pp_fun ~name:"BEGIN" ~lines

let pp_program ppf ~fun_list =
  let open Format in
  let pp_sep ppf () = fprintf ppf "\n\n" in
  fprintf ppf "@[<v>%a@]@." (pp_print_list ~pp_sep pp_print_string) fun_list

let transpile_function { probe; domain; name; args } =
  let open Format in
  let fullname = sprintf "%s:%s:%s" probe domain name in
  let fmt_types = List.map fmt_spec args |> String.concat ", " in
  let fmt = " (%s) %s: " ^ fmt_types ^ "\\n" in
  let arg_ids =
    "comm" :: "probe"
    :: List.map (fun { identifier; _ } -> sprintf "args->%s" identifier) args
  in
  pp_fun ~name:fullname ~lines:Builtins.[ time; printf fmt arg_ids ]

let () =
  let f_path =
    try Sys.argv.(1) with _ -> failwith "Need to supply file path as argument"
  in
  let gen imd =
    Out_channel.with_open_bin "bpfgen.bt" (fun oc ->
        let ppf = Format.formatter_of_out_channel oc in
        let fun_list =
          entry "Tracing IO_uring ..." :: List.map transpile_function imd
        in
        pp_program ppf ~fun_list)
  in
  let t = Spec_reader.read_spec f_path in
  gen t
