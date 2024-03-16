open Runtime_events

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

let rec get_events ic =
  match In_channel.input_line ic with
  | None -> ()
  | Some ev ->
    User.write bpftrace_ev ev;
    get_events ic

let trace_poll filename =
  In_channel.with_open_text filename (fun ic ->
      while true do
        get_events ic;
        Unix.sleepf 0.1
      done)
