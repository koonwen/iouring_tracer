include Runtime_events

type User.tag += Io_uring

(** Could be made more efficient by using Bytes*)
let ty =
  let encode bytes ev =
    let len = min (String.length ev) 1024 in
    Bytes.blit_string ev 0 bytes 0 len;
    len
  in
  let decode bytes sz = Bytes.sub_string bytes 0 sz in
  Type.register ~encode ~decode

let bpftrace_ev = User.register "io-uring" Io_uring ty

let get_events ic =
  match In_channel.input_line ic with
  | None -> ()
  | Some ev -> User.write bpftrace_ev ev

let bpftrace_ev_handler _i _ts ty s =
  match User.tag ty with Io_uring -> Printf.printf "%s\n%!" s | _ -> ()

let trace_poll ?ev_handler_op filename =
  let ev_handler = Option.value ~default:bpftrace_ev_handler ev_handler_op in
  In_channel.with_open_text filename (fun ic ->
      start ();
      let cursor = create_cursor None in
      let cb = Callbacks.create () |> Callbacks.add_user_event ty ev_handler in
      while true do
        get_events ic;
        ignore (read_poll cursor cb None);
        Unix.sleepf 0.1
      done;
      (* In case something was missed *)
      ignore (read_poll cursor cb None);
      free_cursor cursor)
