open Obpftrace
open Eio.Std

let bpftrace_ev_handler _i _ts ty s =
  match Runtime_events.User.tag ty with
  | Runtime_events_hook.Io_uring -> traceln "%s\n%!" s
  | _ -> ()

let () =
  Driver.start ();
  Runtime_events.start ();
  let cur = Runtime_events.create_cursor None in
  let cb =
    Runtime_events.Callbacks.create ()
    |> Runtime_events.Callbacks.add_user_event Runtime_events_hook.ty
         bpftrace_ev_handler
  in
  Eio_linux.run @@ fun env ->
  Switch.run (fun sw ->
      Fiber.fork ~sw (fun () ->
          for i = 1 to 2 do
            ignore (Runtime_events.read_poll cur cb None);
            traceln "Fiber Sleeping, iteration %d" i;
            Eio.Time.sleep (Eio.Stdenv.clock env) 2.0
          done));
  Runtime_events.free_cursor cur
