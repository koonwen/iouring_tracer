open Eio.Std

let concurrent () =
  Eio_linux.run @@ fun _env ->
  Fiber.both
    (fun () ->
      for x = 1 to 3 do
        traceln "x = %d" x;
        Fiber.yield ()
      done)
    (fun () ->
      for y = 1 to 3 do
        traceln "y = %d" y;
        Fiber.yield ()
      done)

let sleeper ~env ~sw fibers iters =
  for id = 1 to fibers do
    Fiber.fork ~sw (fun () ->
        for i = 1 to iters do
          traceln "Fiber %d Sleeping, iteration %d" id i;
          Eio.Time.sleep (Eio.Stdenv.clock env) 2.0
        done)
  done

let single_sleeper () =
  Eio_linux.run @@ fun env -> Switch.run (fun sw -> sleeper ~env ~sw 1 3)

let double_sleeper () =
  Eio_linux.run @@ fun env -> Switch.run (fun sw -> sleeper ~env ~sw 2 3)
