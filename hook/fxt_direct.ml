external bpf_uring_trace_fxt : unit -> unit = "caml_ml_bpf_uring_trace_fxt"

type tag = IO_URING_TRACEPOINT | IO_URING_SYSCALL
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
end

module Syscalls = struct
  type t = SYS_IO_URING_SETUP | SYS_IO_URING_REGISTER | SYS_IO_URING_ENTER
  [@@deriving enum, show { with_path = false }]
end

type t = { f : Faraday.t; fxt : Fxt.Write.t; thread : Fxt.Write.thread }

let t =
  let f = Faraday.create 4096 in
  let fxt = Fxt.Write.of_writer f in
  let thread =
    Fxt.Write.{ pid = Unix.getpid () |> Int64.of_int; tid = Int64.zero }
  in
  { f; fxt; thread }

let write_ev_fxt : int -> int -> int -> unit =
  fun probe_t probe_id span ->
  let ts = Sys.time () |> Int64.of_float in
  match probe_t_of_enum probe_t with
  | None -> failwith "Unknown probe_t"
  | Some TRACEPOINT -> (
      match Tracepoints.of_enum probe_id with
      | None -> failwith "Unknown tracepoints probe_id"
      | Some probe_id ->
          Fxt.Write.instant_event t.fxt
            ~name:(Tracepoints.show probe_id)
            ~thread:t.thread ~category:"bpf" ~ts)
  | Some SYSCALL -> (
      match Syscalls.of_enum probe_id with
      | None -> failwith "Unknown syscalls probe_id"
      | Some probe_id ->
          if span = 0 then
            Fxt.Write.duration_begin t.fxt ~name:(Syscalls.show probe_id)
              ~thread:t.thread ~category:"bpf" ~ts
          else if span = 1 then
            Fxt.Write.duration_end t.fxt ~name:(Syscalls.show probe_id)
              ~thread:t.thread ~category:"bpf" ~ts
          else failwith "Unknown span")

let _ = Callback.register "write_ev_fxt" write_ev_fxt

let run () =
  let _t = Thread.create bpf_uring_trace_fxt () in
  Lwt_main.run (
    let fd = Unix.openfile "trace.fxt" [ O_WRONLY; O_CREAT ] 0o666 in
    let writev = Faraday_lwt_unix.writev_of_fd (Lwt_unix.of_unix_file_descr fd) in
    let yield _t = Lwt.pause () in
    Faraday_lwt.serialize t.f ~yield ~writev)
