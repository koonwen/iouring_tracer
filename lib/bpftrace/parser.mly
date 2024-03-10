%token <string> ID
%token NEWLINE
(* %token INDENT *)
%token ARG
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
%token DATA_LOC

%left UNSIGNED
%right NEWLINE

%start <Gen.Intermediate.t> parse
%%

parse: l = list(spec); EOF { l }

spec:
probe=ID; COLON; domain=ID; COLON; name=ID; arg_list = list(arg);
NEWLINE { Gen.Intermediate.{probe=probe; domain=domain; name=name; args = arg_list} };

arg:
| ARG; t = read_t; name = ID { (t, name) } ;

  read_t:
| t_ = read_t; STAR                         { Gen.Intermediate.Ptr (t_) }
| t_ = read_t; LEFT_BRACK; RIGHT_BRACK      { Gen.Intermediate.Array (t_) }
| UNSIGNED                                  { Gen.Intermediate.(Unsigned Int) }
| UNSIGNED; t_ = unsigned_t                 { t_ }
| CONST; t_ = read_t                        { t_ }
| DATA_LOC; t_ = read_t                     { t_ }
| t_ = t                                    { t_ };

  unsigned_t:
| INT     {Gen.Intermediate.(Unsigned Int)}
| INT8    {Gen.Intermediate.(Unsigned Int8)}
| INT16   {Gen.Intermediate.(Unsigned Int16)}
| INT32   {Gen.Intermediate.(Unsigned Int32)}
| INT64   {Gen.Intermediate.(Unsigned Int64)}
| SIZE_T  {Gen.Intermediate.(Unsigned Int64)}
| LONG    {Gen.Intermediate.(Unsigned Long)}
| LONGLONG {Gen.Intermediate.(Unsigned LongLong)}

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
  | STRUCT; name = ID {Gen.Intermediate.Struct (name, [])}
