%token <string> ID
%token NEWLINE
%token INDENT
%token LEFT_BRACK
%token RIGHT_BRACK
%token COLON
%token EOF

(* ATTR  *)
%token STRUCT
%token CONST
%token UNSIGNED
%token STAR
(* TYPES *)
%token VOID
%token BOOL
%token CHAR
%token INT
%token INT8
%token INT16
%token INT32
%token INT64
%token LONG
%token LONGLONG
%token SIZE_T
%token UINT
%token UINT8
%token UINT16
%token UINT32
%token UINT64

%start <Gen.Intermediate.t> parse
%%

parse: l = list(spec); EOF { l }

spec:
  probe=ID; COLON; domain=ID; COLON; name=ID; arg_list = list(arg); NEWLINE
  { Gen.Intermediate.{probe=probe; domain=domain; name=name; args = arg_list} };

arg:
| NEWLINE; INDENT; t = read_t; name = ID { (t, name) } ;

  read_t:
| STRUCT; name = ID; _t = read_t            { Gen.Intermediate.Struct (name, [])}
| t_ = read_t; STAR                         { Gen.Intermediate.Ptr (t_) }
| t_ = read_t; LEFT_BRACK; RIGHT_BRACK      { Gen.Intermediate.Array (t_) }
| t_ = t                                    { t_ };

t:
  | VOID    {Gen.Intermediate.(Void)}
  | BOOL    {Gen.Intermediate.(Bool)}
  | CHAR    {Gen.Intermediate.(Char)}
  | INT     {Gen.Intermediate.(Signed Int)}
  | INT8    {Gen.Intermediate.(Signed Int8)}
  | INT16   {Gen.Intermediate.(Signed Int16)}
  | INT32   {Gen.Intermediate.(Signed Int32)}
  | INT64   {Gen.Intermediate.(Signed Int64)}
  | SIZE_T  {Gen.Intermediate.(Signed Int64)}
  | LONG    {Gen.Intermediate.(Signed Long)}
  | LONGLONG {Gen.Intermediate.(Signed LongLong)}
  | UINT    {Gen.Intermediate.(Unsigned (Int))}
  | UINT8   {Gen.Intermediate.(Unsigned (Int8))}
  | UINT16  {Gen.Intermediate.(Unsigned (Int16))}
  | UINT32  {Gen.Intermediate.(Unsigned (Int32))}
  | UINT64  {Gen.Intermediate.(Unsigned (Int64))}
