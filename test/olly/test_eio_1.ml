let () =
  Eio_linux.run @@ fun env ->
  let ( / ) = Eio.Path.( / ) in
  let path = env#cwd / "test3.data" in
  Eio.Path.with_open_out path ~create:(`Exclusive 0o600) @@ fun file ->
  Eio.Flow.copy_string "hello" file;
  Eio.Flow.copy_string "+" file
