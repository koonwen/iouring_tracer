let name_headers_bindings =
  [
    ( "defs_stubs_gen.c",
      {|#include "defs.h"|},
      (module Defs.Uring_trace.Bindings : Cstubs.Types.BINDINGS) );
    ( "uring_spans_stubs_gen.c",
      {|#include "uring_spans.h"|},
      (module Defs.Uring_spans.Bindings) );
    ( "uring_ops_stubs_gen.c",
      {|#include "uring_ops.h"|},
      (module Defs.Uring_ops.Bindings) );
  ]

let () =
  List.iter
    (fun (name, c_headers, bindings) ->
      let stubs_out = open_out name in
      let stubs_fmt = Format.formatter_of_out_channel stubs_out in
      Format.fprintf stubs_fmt "%s@\n" c_headers;
      Cstubs.Types.write_c stubs_fmt bindings;
      Format.pp_print_flush stubs_fmt ();
      close_out stubs_out)
    name_headers_bindings
