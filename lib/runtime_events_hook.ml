open Runtime_events

type User.tag += Io_uring

let trace_file = "trace.txt"
let ic = In_channel.open_text trace_file

let ty =
  let encode bytes ev =
    let len = min (String.length ev) 1024 in
    Bytes.blit_string ev 0 bytes 0 len;
    len
  in
  let decode bytes sz = Bytes.sub_string bytes 0 sz in
  Type.register ~encode ~decode

let bpftrace_ev = User.register "io-uring" Io_uring ty

let rec get_events () =
  match In_channel.input_line ic with
  | None -> ()
  | Some ev ->
      User.write bpftrace_ev ev;
      get_events ()

let bpftrace_ev_handler _i _ts ty s =
  match User.tag ty with Io_uring -> Printf.printf "%s\n%!" s | _ -> ()

let read_poll cursor callbacks max_option =
  get_events ();
  Runtime_events.read_poll cursor callbacks max_option

let () =
  start ();
  let cursor = create_cursor None in
  let cb =
    Callbacks.create () |> Callbacks.add_user_event ty bpftrace_ev_handler
  in
  try
    while true do
      ignore (read_poll cursor cb None);
      Unix.sleepf 1.0
    done
  with _ ->
    free_cursor cursor;
    In_channel.close ic
