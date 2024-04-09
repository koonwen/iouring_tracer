[@@@warning "-32"]

open Runtime_events

external bpf_uring_trace : unit -> unit = "caml_ml_bpf_uring_trace"

type User.tag += IO_URING_TRACEPOINT | IO_URING_SYSCALL
type probe_t = TRACEPOINT | SYSCALL [@@deriving enum, show]

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

  let registra =
    List.fold_left
      (fun tbl t ->
        let ev = User.register (show t) IO_URING_TRACEPOINT Type.unit in
        Hashtbl.add tbl t ev;
        tbl)
      (Hashtbl.create 20)
      [
        IO_URING_COMPLETE;
        IO_URING_CQE_OVERFLOW;
        IO_URING_CQRING_WAIT;
        IO_URING_CREATE;
        IO_URING_DEFER;
        IO_URING_FAIL_LINK;
        IO_URING_FILE_GET;
        IO_URING_LINK;
        IO_URING_LOCAL_WORK_RUN;
        IO_URING_POLL_ARM;
        IO_URING_QUEUE_ASYNC_WORK;
        IO_URING_REGISTER;
        IO_URING_REQ_FAILED;
        IO_URING_SHORT_WRITE;
        IO_URING_SUBMIT_SQE;
        IO_URING_TASK_ADD;
        IO_URING_TASK_WORK_RUN;
      ]
end

module Syscalls = struct
  type t =
    | SYS_EXIT_IO_URING_REGISTER
    | SYS_ENTER_IO_URING_REGISTER
    | SYS_EXIT_IO_URING_SETUP
    | SYS_ENTER_IO_URING_SETUP
    | SYS_EXIT_IO_URING_ENTER
    | SYS_ENTER_IO_URING_ENTER
  [@@deriving enum, show { with_path = false }]

  let registra =
    List.fold_left
      (fun tbl t ->
        let ev = User.register (show t) IO_URING_SYSCALL Type.span in
        Hashtbl.add tbl t ev;
        tbl)
      (Hashtbl.create 6)
      [
        SYS_EXIT_IO_URING_REGISTER;
        SYS_ENTER_IO_URING_REGISTER;
        SYS_EXIT_IO_URING_SETUP;
        SYS_ENTER_IO_URING_SETUP;
        SYS_EXIT_IO_URING_ENTER;
        SYS_ENTER_IO_URING_ENTER;
      ]
end

let write_ev : int -> int -> int -> unit =
 fun probe_t probe_id span ->
  match probe_t_of_enum probe_t with
  | None -> failwith "Unknown probe_t"
  | Some TRACEPOINT ->
      let value =
        Hashtbl.find Tracepoints.registra
          (Tracepoints.of_enum probe_id |> Option.get)
      in
      User.write value ()
  | Some SYSCALL ->
      let value =
        Hashtbl.find Syscalls.registra (Syscalls.of_enum probe_id |> Option.get)
      in
      User.write value
        (if span = 0 then Begin
         else if span = 1 then End
         else failwith "Unknown span")

let _ = Callback.register "write_ev" write_ev

let spawn f =
  Runtime_events.start ();
  let _t = Thread.create bpf_uring_trace () in
  let cur = Runtime_events.create_cursor None in
  let cb =
    Runtime_events.Callbacks.create ()
    |> Callbacks.add_user_event Type.int (fun _ _ _ i ->
           let ev_name =
             Tracepoints.of_enum i |> Option.get |> Tracepoints.show
           in
           Printf.printf "got %s\n%!" ev_name)
  in
  f ();
  Runtime_events.read_poll cur cb None |> ignore;
  raise Thread.Exit

let run f =
  let _t = Thread.create bpf_uring_trace () in
  Thread.delay 1.0;
  (try f () with _ -> ());
  raise Thread.Exit

let spawn_c () = bpf_uring_trace ()
