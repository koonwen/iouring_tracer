let parse_name s =
  match String.split_on_char ':' s with
  | [ probe; domain; name ] -> Some (probe, domain, name)
  | _ -> None

let parse_arg line : Intermediate.arg =
  let open Intermediate in
  let rec parse arg = function
    (* Match quantifiers *)
    | "const" :: next -> match_ty { arg with const = true } next
    | "unsigned" :: next -> match_ty { arg with unsigned = true } next
    | ty -> match_ty arg ty
  and match_ty arg = function
    (* Match on types *)
    | "bool" :: next -> match_ty { arg with ty = Bool } next
    | "char[]" :: next -> match_ty { arg with ty = Array Char } next
    | "int" :: next -> match_ty { arg with ty = Int } next
    | "u8" :: next -> match_ty { arg with unsigned = true; ty = Int8 } next
    | "u16" :: next -> match_ty { arg with unsigned = true; ty = Int16 } next
    | "u32" :: next -> match_ty { arg with unsigned = true; ty = Int32 } next
    | "u64" :: next -> match_ty { arg with unsigned = true; ty = Int64 } next
    | "s32" :: next -> match_ty { arg with ty = Int32 } next
    | "size_t" :: next -> match_ty { arg with ty = Size_t } next
    | "long" :: next ->
        let ty = if arg.ty = Long then LongLong else Long in
        match_ty { arg with ty } next
    | "struct" :: name :: next -> match_ty { arg with ty = Struct name } next
    | "void" :: next -> match_ty arg next
    | "__data_loc" :: next -> match_ty arg next
    | "*" :: next -> match_ty { arg with ty = Ptr arg.ty } next
    | "[]" :: next -> match_ty { arg with ty = Array arg.ty } next
    | [ identifier ] -> { arg with identifier }
    | e ->
        let e' = String.concat "|" ("Not sure how to handle:" :: e) in
        raise (Invalid_argument e')
  in
  let empty_arg =
    make_arg ~const:false ~unsigned:false ~ty:Void ~identifier:""
  in
  parse empty_arg line

let parse lines : Intermediate.spec list =
  let rec aux spec = function
    | [] -> []
    | l :: tl -> (
        match parse_name l with
        | Some (probe, domain, name) ->
            let new_spec = Intermediate.{ probe; domain; name; args = [] } in
            Intermediate.{ spec with args = List.rev spec.args }
            :: aux new_spec tl
        | None ->
            let l' = String.trim l |> String.split_on_char ' ' in
            let args = parse_arg l' :: spec.args in
            aux { spec with args } tl)
  in
  let empty_spec = Intermediate.make_spec ~probe:"" ~domain:"" ~name:"" () in
  match aux empty_spec lines with
  | [] -> failwith "Bad parse"
  | _ :: tl -> List.rev tl

let read_spec filename : Intermediate.t =
  In_channel.with_open_text filename (fun ic ->
      let lines = In_channel.input_lines ic in
      parse lines)
