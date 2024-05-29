module W = Fxt.Write

type track = W.thread
type thread_tbl = (int64, track) Hashtbl.t
type t = { pid_tbl : (int64, thread_tbl) Hashtbl.t; fxt : W.t }

let make fxt = { pid_tbl = Hashtbl.create 8; fxt }

(* Helper function to find the track from the tree data structure and
   register if it doesn't exist *)
let get_track t ~pid ~tid ~comm =
  let thread_tbl =
    match Hashtbl.find_opt t.pid_tbl pid with
    | Some v -> v
    | None ->
        (* Register thread_map if it doesn't exist *)
        let thread_tbl' = Hashtbl.create 10 in
        Hashtbl.add t.pid_tbl pid thread_tbl';
        thread_tbl'
  in

  match Hashtbl.find_opt thread_tbl tid with
  | Some v -> v
  | None ->
      (* Register track if it doesn't exist *)
      let track' =  W.{ pid; tid } in
      Hashtbl.add thread_tbl tid track';

      (* Write to perfetto kernel object metadata *)
      W.kernel_object t.fxt
        ~args:[ ("process", `Koid pid) ]
        ~name:comm `Thread tid;
      track'

let sys_enter_start_event ?args t ~pid ~tid ~name ~comm ~ts =
  let track = get_track t ~pid ~tid ~comm in
  W.duration_begin ?args t.fxt ~name ~thread:track ~category:"uring" ~ts

let sys_enter_end_event ?args t ~pid ~tid ~name ~comm ~ts =
  let track = get_track t ~pid ~tid ~comm in
  W.duration_end ?args t.fxt ~name ~thread:track ~category:"uring" ~ts

let submission_event ?args t ~pid ~tid ~name ~comm ~ts ~correlation_id =
  let track = get_track t ~pid ~tid ~comm in
  W.duration_begin t.fxt ?args ~name ~thread:track ~category:"uring" ~ts;
  W.flow_begin t.fxt ~correlation_id ?args ~name ~thread:track
    ~category:"uring" ~ts;
  W.duration_end t.fxt ?args ~name ~thread:track ~category:"uring" ~ts

let async_work_event ?args t ~pid ~tid ~name ~comm ~ts ~correlation_id =
  let track = get_track t ~pid ~tid ~comm in
  W.duration_begin t.fxt ?args ~name ~thread:track ~category:"uring" ~ts;
  W.flow_step t.fxt ~correlation_id ?args ~name ~thread:track
    ~category:"uring" ~ts;
  W.duration_end t.fxt ?args ~name ~thread:track ~category:"uring" ~ts

let completion_event ?args t ~pid ~tid ~name ~comm ~ts ~correlation_id =
  let track = get_track t ~pid ~tid ~comm in
  W.duration_begin t.fxt ?args ~name ~thread:track ~category:"uring" ~ts;
  W.flow_end t.fxt ~correlation_id ?args ~name ~thread:track
    ~category:"uring" ~ts;
  W.duration_end t.fxt ?args ~name ~thread:track ~category:"uring" ~ts
