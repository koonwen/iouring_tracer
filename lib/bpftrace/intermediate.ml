[@@@warning "-32"]

(* This should replace Gen.Intermediate *)
type types =
  | Void
  | Bool
  | Char
  | Ints of bool * ints (* Boolean determines if int is unsigned *)
  | Struct of string * args
  | Ptr of types
  | Array of types

and ints = Int | Int8 | Int16 | Int32 | Int64 | Long | LongLong | Size_t
[@@deriving show { with_path = false }]

and args = (types * string) list

type spec = { probe : string; domain : string; name : string; args : args }
type t = spec list

let fmt_spec type' =
  let fmt_int_spec = function
    | Int | Int8 | Int16 -> "d"
    | Int32 | Int64 | Long | Size_t -> "l"
    | LongLong -> "ll"
  in
  match type' with
  | Bool -> "%b"
  | Char -> "%c"
  | Ints (unsigned, i) ->
      if unsigned then "%u" ^ fmt_int_spec i else "%" ^ fmt_int_spec i
  | Struct (_, _) -> failwith "Not implemented"
  | Void | Ptr _ | Array _ -> "0x%llx"

let transpile_printf_args args =
  let types =
    String.concat ", " ((List.map (fun (type', _) -> fmt_spec type')) args)
  in
  let args = String.concat ", " (List.map snd args) in
  let s = Format.sprintf "\"%s\", %s;" types args in
  Gen.Builtins.printf s

let transpile_function { name; args; _ } =
  Gen.pp_fun ~name ~lines:[ Gen.Builtins.time; transpile_printf_args args ]

(* Stub just to work with what we know *)
let handleable imd =
  let can_handle spec =
    let handleable_args =
      List.filter
        (fun (t, _) -> match t with Struct _ -> false | _ -> true)
        spec.args
    in
    { spec with args = handleable_args }
  in
  List.map can_handle imd

let write_program imd =
  let handleable = handleable imd in
  List.iter (fun i -> Printf.printf "%s\n" (transpile_function i)) handleable
