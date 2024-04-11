[@@@warning "-32"]

open Runtime_events

external bpf_uring_trace : unit -> unit = "caml_ml_bpf_uring_trace"

type User.tag += IO_URING_TRACEPOINT | IO_URING_SYSCALL
type probe_t = TRACEPOINT | SYSCALL [@@deriving enum, show]

(* May want to make this into a functor *)
module Tracepoints = struct
  type t =
    | IO_URING_COMPLETE
    | IO_URING_CQE_OVERFLOW
    | IO_URING_CQRING_WAIT
    | IO_URING_CREATE
    | IO_URING_DEFER
    | IO_URING_FAIL_LINK
    | IO_URING_FILE_GET
    | IO_URING_LINK
    | IO_URING_LOCAL_WORK_RUN
    | IO_URING_POLL_ARM
    | IO_URING_QUEUE_ASYNC_WORK
    | IO_URING_REGISTER
    | IO_URING_REQ_FAILED
    | IO_URING_SHORT_WRITE
    | IO_URING_SUBMIT_SQE
    | IO_URING_TASK_ADD
    | IO_URING_TASK_WORK_RUN
  [@@deriving enum, show { with_path = false }]

  let make_registra num_tracepoints =
    Array.init num_tracepoints (fun i ->
        match of_enum i with
        | None -> failwith "Can't make tracepoints registra"
        | Some t -> User.register (show t) IO_URING_TRACEPOINT Type.unit)

  let get_ev =
    let registra = make_registra 17 in
    fun t -> registra.(to_enum t)

  let cb_show rb_idx ts probe () =
    Printf.printf "[%Ld] rb_idx:%d (%s)\n%!" (Timestamp.to_int64 ts) rb_idx
      (User.name probe)
end

module Syscalls = struct
  type t =
    | SYS_IO_URING_SETUP
    | SYS_IO_URING_REGISTER
    | SYS_IO_URING_ENTER
  [@@deriving enum, show { with_path = false }]

  let make_registra num_tracepoints =
    Array.init num_tracepoints (fun i ->
        match of_enum i with
        | None -> failwith "Can't make syscalls registra"
        | Some t -> User.register (show t) IO_URING_SYSCALL Type.span)

  let get_ev =
    let registra = make_registra 3 in
    fun t -> registra.(to_enum t)

  let cb_show rb_idx ts probe (span : Type.span) =
    let span = match span with Begin -> "BEGIN" | End -> "END" in
    Printf.printf "[%Ld] rb_idx:%d (%s) %s\n%!" (Timestamp.to_int64 ts) rb_idx
      (User.name probe) span
end

let write_ev : int -> int -> int -> unit =
 fun probe_t probe_id span ->
  match probe_t_of_enum probe_t with
  | None -> failwith "Unknown probe_t"
  | Some TRACEPOINT -> (
      match Tracepoints.of_enum probe_id with
      | None -> failwith "Unknown tracepoints probe_id"
      | Some probe_id ->
          let value = Tracepoints.(get_ev probe_id) in
          User.write value ())
  | Some SYSCALL -> (
      match Syscalls.of_enum probe_id with
      | None -> failwith "Unknown syscalls probe_id"
      | Some probe_id ->
          let value = Syscalls.(get_ev probe_id) in
          User.write value
            (if span = 0 then Begin
             else if span = 1 then End
             else failwith "Unknown span"))

let _ = Callback.register "write_ev" write_ev

let interactive () =
  Runtime_events.start ();
  let _t = Thread.create bpf_uring_trace () in
  let cur = Runtime_events.create_cursor None in
  let cb =
    Runtime_events.Callbacks.create ()
    |> Callbacks.add_user_event Type.unit Tracepoints.cb_show
    |> Callbacks.add_user_event Type.span Syscalls.cb_show
  in
  while true do
    Runtime_events.read_poll cur cb None |> ignore;
    Unix.sleepf 1.0
  done;
  raise Thread.Exit

let run f =
  let _t = Thread.create bpf_uring_trace () in
  Thread.delay 1.0;
  (try f () with _ -> ());
  raise Thread.Exit

let spawn_c () = bpf_uring_trace ()
