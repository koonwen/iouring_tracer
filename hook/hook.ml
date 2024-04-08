[@@@warning "-32"]

open Runtime_events

external bpf_uring_trace : unit -> unit = "caml_ml_bpf_uring_trace"

type tracepoints =
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
[@@deriving enum, show]

type User.tag += IO_URING_TRACEPOINT

let bpf_ev = User.register "io-uring" IO_URING_TRACEPOINT Type.int
let write_ev : int -> unit = fun i -> User.write bpf_ev i
let _ = Callback.register "write_ev" write_ev

let spawn () =
  Runtime_events.start ();
  let t = Thread.create bpf_uring_trace () in
  let cur = Runtime_events.create_cursor None in
  let cb =
    Runtime_events.Callbacks.create ()
    |> Callbacks.add_user_event Type.int (fun _ _ _ i ->
           let ev_name =
             tracepoints_of_enum i |> Option.get |> show_tracepoints
           in
           Printf.printf "got %s\n%!" ev_name)
  in
  while true do
    Unix.sleepf 0.5;
    Runtime_events.read_poll cur cb None |> ignore
  done;
  Thread.join t
