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

(* let ty_bytes = *)
(*   let encode bytes ev = *)
(*     Bytes.blit ev 0 bytes 0 1024; *)
(*     1024 *)
(*   in *)
(*   let decode bytes _sz = bytes in *)
(*   Type.register ~encode ~decode *)

let bpftrace_ev = User.register "io-uring" Io_uring ty
let pos = ref 0

(* let get_events_bytes ic = *)
(*   let buf = Bytes.create 1024 in *)
(*   In_channel.seek ic (Int64.of_int !pos); *)
(*   let res = In_channel.input ic buf 0 1024 in *)
(*   if res = 0 then () else User.write bpftrace_ev buf; *)
(*   pos := !pos + res *)

let get_events ic =
  match In_channel.input_line ic with
  | None -> ()
  | Some ev -> User.write bpftrace_ev ev

let bpftrace_ev_handler _i _ts ty s =
  match User.tag ty with Io_uring -> Printf.printf "%s\n%!" s | _ -> ()

let trace_poll filename alive =
  In_channel.with_open_text filename (fun ic ->
      start ();
      let cursor = create_cursor None in
      let cb =
        Callbacks.create () |> Callbacks.add_user_event ty bpftrace_ev_handler
      in
      while alive () do
        get_events ic;
        ignore (read_poll cursor cb None);
        Unix.sleepf 0.1
      done;
      (* In case something was missed *)
      ignore (read_poll cursor cb None);
      free_cursor cursor)
