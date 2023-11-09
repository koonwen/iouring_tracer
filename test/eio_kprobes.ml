open Eio.Std

let main () =
  Eio_linux.run @@ fun env ->
  while true do
    traceln "Sleeping";
    Eio.Time.sleep (Eio.Stdenv.clock env) 2.0
  done

let () = Iouring_tracer.kprobes main
