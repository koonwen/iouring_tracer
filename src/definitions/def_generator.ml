let c_headers = {|#include "defs.h"|}

let main () =
  let stubs_out = open_out "defs_stubs_gen.c" in
  let stubs_fmt = Format.formatter_of_out_channel stubs_out in
  Format.fprintf stubs_fmt "%s@\n" c_headers;
  Cstubs.Types.write_c stubs_fmt (module Defs.Bindings);
  Format.pp_print_flush stubs_fmt ();
  close_out stubs_out

let () = main ()
