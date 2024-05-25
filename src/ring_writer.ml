module W = Fxt.Write

type t = {
  sqring : W.thread;
  cqring : W.thread;
  syscalls : W.thread;
  fxt : W.t;
}

let submission_event ?args t ~name ~ts ~correlation_id =
  W.duration_begin t.fxt ?args ~name ~thread:t.sqring ~category:"uring" ~ts;
  W.flow_begin t.fxt ~correlation_id ?args ~name ~thread:t.sqring
    ~category:"uring" ~ts;
  W.duration_end t.fxt ?args ~name ~thread:t.sqring ~category:"uring" ~ts

let completion_event ~correlation_id ?args t ~name ~ts =
  W.duration_begin t.fxt ?args ~name ~thread:t.cqring ~category:"uring" ~ts;
  W.flow_end t.fxt ~correlation_id ?args ~name ~thread:t.cqring
    ~category:"uring" ~ts;
  W.duration_end t.fxt ?args ~name ~thread:t.cqring ~category:"uring" ~ts

let make fxt =
  let pid = Int64.of_int (Unix.getpid ()) in
  let t =
    {
      syscalls = W.{ pid; tid = 0L };
      sqring = W.{ pid; tid = 1L };
      cqring = W.{ pid; tid = 2L };
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
  t
