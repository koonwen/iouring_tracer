[@@@warning "-26"]

(* This should replace Gen.Intermediate *)
type ty =
  | Void
  | Bool
  | Char
  | Int
  | Int8
  | Int16
  | Int32
  | Int64
  | Long
  | LongLong
  | Size_t
  | Struct of string
  | Ptr of ty
  | Array of ty
[@@deriving show { with_path = false }]

type arg = { const : bool; unsigned : bool; ty : ty; identifier : string }
[@@deriving show { with_path = false }, make]

type spec = { probe : string; domain : string; name : string; args : arg list }
[@@deriving show { with_path = false }, make]

type t = spec list
[@@deriving show { with_path = false }]

let fmt_spec ({ unsigned; ty; _ } : arg) =
  match ty with
  | Char -> "%c"
  | Bool | Int | Int8 | Int16 -> if unsigned then "%u" else "%d"
  | Int32 | Int64 | Long | Size_t -> if unsigned then "%lu" else "%ld"
  | LongLong -> if unsigned then "%llu" else "%lld"
  | Void | Struct _ | Ptr _ | Array _ -> "0x%llx"
