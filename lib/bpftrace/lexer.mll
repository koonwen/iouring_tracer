{
open Parser

exception SyntaxError of string
}

let white = [ ' ' ] +
let newline = '\r' | '\n' | "\r\n"
let id = ['a'-'z' 'A'-'Z' '_'] ['a'-'z' 'A'-'Z' '0'-'9' '_']*
let indent = "    " | '\t'

rule read =
  parse
  | white       { read lexbuf }
  | newline     { Lexing.new_line lexbuf; NEWLINE }
  | indent      { INDENT }

  | "struct"           { STRUCT }
  | "const"            { CONST }
  | "void"             { VOID }
  | "bool"             { BOOL }
  | "char"             { CHAR }
  | "int"              { INT }
  | "int8"             { INT8 }
  | "int16"            { INT16 }
  | "int32" | "s32"    { INT32 }
  | "int64"            { INT64 }
  | "long"             { LONG }
  | "long long"        { LONGLONG }
  | "size_t"           { SIZE_T }
  | "u8"               { UINT8 }
  | "u16"              { UINT16 }
  | "u32"              { UINT32 }
  | "u64"              { UINT64 }
  | "unsigned"         { UNSIGNED }

  | id         { ID (Lexing.lexeme lexbuf) }
  | '*'        { STAR }
  | ':'        { COLON }
  | '['        { LEFT_BRACK }
  | ']'        { RIGHT_BRACK }
  | _          { raise (SyntaxError ("Unexpected char: " ^ Lexing.lexeme lexbuf)) }
  | eof        { EOF }
