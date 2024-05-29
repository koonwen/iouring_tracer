module W = Fxt.Write

let uid_gen = ref 0

type track_type = SYSCALLS | SQRING | CQRING | IO_WORKER

type track = {
  name : string;
  (* This "thread" field doesn't actually hold true pid/tid, it is
     just used to reference arbritrary tracks for nice displaying on
     Perfetto *)
  thread : W.thread;
}

type thread_tbl = {
  syscalls : (int64, track) Hashtbl.t;
  sqring : (int64, track) Hashtbl.t;
  cqring : (int64, track) Hashtbl.t;
  io_worker : (int64, track) Hashtbl.t;
}

type t = { pid_tbl : (int64, thread_tbl) Hashtbl.t; fxt : W.t }

let make_thread_tbl () =
  {
    syscalls = Hashtbl.create 1;
    sqring = Hashtbl.create 1;
    cqring = Hashtbl.create 1;
    io_worker = Hashtbl.create 20;
  }

let make fxt = { pid_tbl = Hashtbl.create 8; fxt }

(* Helper function to find the track from the tree data structure and
   register if it doesn't exist *)
let get_track t ~pid ~tid ~comm:_ ~track_type =
  let thread_tbl =
    match Hashtbl.find_opt t.pid_tbl pid with
    | Some v -> v
    | None ->
        (* Register thread_map if it doesn't exist *)
        let thread_tbl' = make_thread_tbl () in
        Hashtbl.add t.pid_tbl pid thread_tbl';
        thread_tbl'
  in

  let open Printf in
  let track_tbl, name =
    match track_type with
    | SYSCALLS -> (thread_tbl.syscalls, sprintf "SYSCALLS-%Ld" tid)
    | SQRING -> (thread_tbl.sqring, sprintf "SQRING-%Ld" tid)
    | CQRING -> (thread_tbl.cqring, sprintf "CQRING-%Ld" tid)
    | IO_WORKER -> (thread_tbl.io_worker, sprintf "IO_WORKER-%Ld" tid)
  in

  match Hashtbl.find_opt track_tbl tid with
  | Some v -> v
  | None ->
      (* Register track if it doesn't exist *)
      let uid = !uid_gen |> Int64.of_int in
      incr uid_gen;

      let track' = { name; thread = W.{ pid; tid = uid } } in
      Hashtbl.add track_tbl tid track';

      (* Write to perfetto kernel object metadata *)
      W.kernel_object t.fxt ~args:[ ("process", `Koid pid) ] ~name `Thread uid;
      track'

let sys_enter_start_event ?args t ~pid ~tid ~name ~comm ~ts =
  let track = get_track t ~pid ~tid ~comm ~track_type:SYSCALLS in
  W.duration_begin ?args t.fxt ~name ~thread:track.thread ~category:"uring" ~ts

let sys_enter_end_event ?args t ~pid ~tid ~name ~comm ~ts =
  let track = get_track t ~pid ~tid ~comm ~track_type:SYSCALLS in
  W.duration_end ?args t.fxt ~name ~thread:track.thread ~category:"uring" ~ts

let submission_event ?args t ~pid ~tid ~name ~comm ~ts ~correlation_id =
  let track = get_track t ~pid ~tid ~comm ~track_type:SQRING in
  W.duration_begin t.fxt ?args ~name ~thread:track.thread ~category:"uring" ~ts;
  W.flow_begin t.fxt ~correlation_id ?args ~name ~thread:track.thread
    ~category:"uring" ~ts;
  W.duration_end t.fxt ?args ~name ~thread:track.thread ~category:"uring" ~ts

let async_work_event ?args t ~pid ~tid ~name ~comm ~ts ~correlation_id =
  let track = get_track t ~pid ~tid ~comm ~track_type:IO_WORKER in
  W.duration_begin t.fxt ?args ~name ~thread:track.thread ~category:"uring" ~ts;
  W.flow_step t.fxt ~correlation_id ?args ~name ~thread:track.thread
    ~category:"uring" ~ts;
  W.duration_end t.fxt ?args ~name ~thread:track.thread ~category:"uring" ~ts

let completion_event ?args t ~pid ~tid ~name ~comm ~ts ~correlation_id =
  let track = get_track t ~pid ~tid ~comm ~track_type:CQRING in
  W.duration_begin t.fxt ?args ~name ~thread:track.thread ~category:"uring" ~ts;
  W.flow_end t.fxt ~correlation_id ?args ~name ~thread:track.thread
    ~category:"uring" ~ts;
  W.duration_end t.fxt ?args ~name ~thread:track.thread ~category:"uring" ~ts
