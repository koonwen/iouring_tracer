module W = Fxt.Write

type ptr = nativeint

type t = { pid_tbl : (int64, ring_tbl) Hashtbl.t; fxt : W.t }
and ring_tbl = { tid_tbl : (ptr, ring) Hashtbl.t }
and ring = { fd : int; tid_tbl : (int64, track) Hashtbl.t }
and track = W.thread

let make fxt = { pid_tbl = Hashtbl.create 8; fxt }

(* Helper function to find the track from the tree data structure if
   it exists register if it doesn't. Returns None in the case where
   ring hasn't been registered for tracking *)
let get_track_opt t ~pid ~(ring_ctx : ptr) ~tid ~comm =
  match Hashtbl.find_opt t.pid_tbl pid with
  | None ->
      Printf.eprintf "No pid found for %Ld%!" pid;
      None (* No PID found for this event *)
  | Some ring_tbl -> (
      match Hashtbl.find_opt ring_tbl.tid_tbl ring_ctx with
      | None ->
          Printf.eprintf "No ring_ctx found for %nd\n%!" ring_ctx;
          None (* No ring_ctx found for this event *)
      | Some { tid_tbl; _ } ->
          (* Register track if it doesn't exist *)
          let track' = W.{ pid; tid } in
          Hashtbl.add tid_tbl tid track';

          let name = Printf.sprintf "%s" comm in
          (* Write to perfetto kernel object metadata *)
          W.kernel_object t.fxt
            ~args:[ ("process", `Koid pid) ]
            ~name `Thread tid;
          Some track')

(* ==================== TRACEPOINTS ==================== *)
(* When io_uring_create tracepoint is hit, we dynamically register
   this process and uring instance to trace, all subsequent
   tracepoints will validate it's ring_ctx to check if it needs to be
   traced or will be dropped. This work could be offloaded later to
   bpf code for better filtering *)
let create_event ?args t ~ring_fd ~ring_ctx ~pid ~tid ~name ~comm ~ts =
  let ring_tbl =
    match Hashtbl.find_opt t.pid_tbl pid with
    | Some v -> v
    | None ->
        Printf.printf "Registering %Ld pid\n%!" pid;
        (* Register pid if it doesn't exist *)
        let ring_tbl' = { tid_tbl = Hashtbl.create 8 } in
        Hashtbl.add t.pid_tbl pid ring_tbl';
        ring_tbl'
  in
  (match Hashtbl.find_opt ring_tbl.tid_tbl ring_ctx with
  | Some _ -> failwith "Ring already registered"
  | None ->
      let open Ctypes in
      Printf.printf "Registering %s ring_ctx\n%!"
        (string_of (ptr void) (ptr_of_raw_address ring_ctx));
      (* Register new ring ctx to track *)
      let tid_tbl' = { fd = ring_fd; tid_tbl = Hashtbl.create 10 } in
      Hashtbl.add ring_tbl.tid_tbl ring_ctx tid_tbl');
  match get_track_opt t ~pid ~ring_ctx ~tid ~comm with
  | None -> failwith "Impossible"
  | Some track ->
      W.instant_event t.fxt ?args ~name ~thread:track ~category:"uring" ~ts

let submission_event ?args t ~pid ~ring_ctx ~tid ~name ~comm ~ts ~correlation_id
    =
  match get_track_opt t ~pid ~ring_ctx ~tid ~comm with
  | None -> Printf.printf "No track found\n%!\n"
  | Some track ->
      W.duration_begin t.fxt ?args ~name ~thread:track ~category:"uring" ~ts;
      W.flow_begin t.fxt ~correlation_id ?args ~name ~thread:track
        ~category:"uring" ~ts;
      W.duration_end t.fxt ?args ~name ~thread:track ~category:"uring" ~ts

let flow_event ?args t ~pid ~ring_ctx ~tid ~name ~comm ~ts ~correlation_id =
  match get_track_opt t ~pid ~ring_ctx ~tid ~comm with
  | None -> ()
  | Some track ->
      W.duration_begin t.fxt ?args ~name ~thread:track ~category:"uring" ~ts;
      W.flow_step t.fxt ~correlation_id ?args ~name ~thread:track
        ~category:"uring" ~ts;
      W.duration_end t.fxt ?args ~name ~thread:track ~category:"uring" ~ts

let completion_event ?args t ~pid ~ring_ctx ~tid ~name ~comm ~ts ~correlation_id
    =
  match get_track_opt t ~pid ~ring_ctx ~tid ~comm with
  | None -> ()
  | Some track ->
      W.duration_begin t.fxt ?args ~name ~thread:track ~category:"uring" ~ts;
      W.flow_end t.fxt ~correlation_id ?args ~name ~thread:track
        ~category:"uring" ~ts;
      W.duration_end t.fxt ?args ~name ~thread:track ~category:"uring" ~ts
