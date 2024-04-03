external bpf_uring_trace : (unit -> unit) -> unit = "caml_ml_bpf_uring_trace"

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
  | IO_URING_TASK_WORK_RUN [@@deriving enum]


let write_ev : int -> unit = fun _i -> failwith "Not implemented"
[@@warning "-32"]

let spawn () =
  let t =
    Thread.create bpf_uring_trace (fun () ->
        Printf.printf "hello from OCaml callback\n")
  in
  Thread.join t
