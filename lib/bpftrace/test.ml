[@@@warning "-32"]
open Core
open Lexing

let print_position outx lexbuf =
  let pos = lexbuf.lex_curr_p in
  fprintf outx "%s:lnum %d:cnum %d" pos.pos_fname pos.pos_lnum
    (pos.pos_cnum - pos.pos_bol + 1)

let lex filename =
  In_channel.with_file filename ~f:(fun ic ->
      let lexbuf = Lexing.from_channel ic in
      let reader l =
        let rec aux l =
          let token = Lexer.read lexbuf in
          match token with EOF as x -> x :: l | x -> aux (x :: l)
        in
        List.rev (aux l)
      in
      reader [])

let parse filename =
  In_channel.with_file filename ~f:(fun ic ->
      let lexbuf = Lexing.from_channel ic in
      let output () =
        try Parser.parse Lexer.read lexbuf with
        | Lexer.SyntaxError msg ->
            fprintf stderr "%a: %s\n" print_position lexbuf msg;
            []
        | Parser.Error ->
            fprintf stderr "%a: syntax error\n" print_position lexbuf;
            []
      in
      output ())

let print filename =
  let t = parse filename in
  Gen.Intermediate.write_program t

let () =
  let f_path =
    try (Sys.get_argv ()).(1)
    with _ -> failwith "Need to supply file path as argument"
  in
  print f_path
