module W = Fxt.Write

type t = {
  syscalls : W.thread;
  sqring : W.thread;
  cqring : W.thread;
  io_worker : W.thread;
  fxt : W.t;
}

let submission_event ?args t ~name ~ts ~correlation_id =
  W.duration_begin t.fxt ?args ~name ~thread:t.sqring ~category:"uring" ~ts;
  W.flow_begin t.fxt ~correlation_id ?args ~name ~thread:t.sqring
    ~category:"uring" ~ts;
  W.duration_end t.fxt ?args ~name ~thread:t.sqring ~category:"uring" ~ts

let completion_event ?args t ~name ~ts ~correlation_id =
  W.duration_begin t.fxt ?args ~name ~thread:t.cqring ~category:"uring" ~ts;
  W.flow_end t.fxt ~correlation_id ?args ~name ~thread:t.cqring
    ~category:"uring" ~ts;
  W.duration_end t.fxt ?args ~name ~thread:t.cqring ~category:"uring" ~ts

let async_work_event ?args t ~name ~ts ~correlation_id =
  W.duration_begin t.fxt ?args ~name ~thread:t.io_worker ~category:"uring" ~ts;
  W.flow_step t.fxt ~correlation_id ?args ~name ~thread:t.io_worker
    ~category:"uring" ~ts;
  W.duration_end t.fxt ?args ~name ~thread:t.io_worker ~category:"uring" ~ts

let make fxt =
  let pid = Int64.of_int (Unix.getpid ()) in
  let t =
    {
      syscalls = W.{ pid; tid = 0L };
      sqring = W.{ pid; tid = 1L };
      cqring = W.{ pid; tid = 2L };
      io_worker = W.{ pid; tid = 3L };
      fxt;
    }
  in
  W.kernel_object fxt
    ~args:[ ("process", `Koid pid) ]
    ~name:"SYSCALLS" `Thread t.syscalls.tid;
  W.kernel_object fxt
    ~args:[ ("process", `Koid pid) ]
    ~name:"SQRING" `Thread t.sqring.tid;
  W.kernel_object fxt
    ~args:[ ("process", `Koid pid) ]
    ~name:"CQRING" `Thread t.cqring.tid;
  W.kernel_object fxt
    ~args:[ ("process", `Koid pid) ]
    ~name:"IO-WORKER" `Thread t.io_worker.tid;

  t
