# iouring_tracer

Low impact tracing tool for visualizing workloads under
Linux's asynchronous IO-uring runtime. This tracer leverages eBPF
probes ([`ocaml_libbpf`](https://github.com/koonwen/ocaml_libbpf)) to
extract information from the kernel. Traces are generated in fuchsia
format to be displayed on [Perfetto](https://ui.perfetto.dev/).

### The Mental Model (taken from this [blog](https://blog.cloudflare.com/missing-manuals-io_uring-worker-pool))

![Flow of requests through uring](assets/uring-visual.png)

### Example trace

![gif of trace](assets/Recording.gif)

### Motivation

The current best way to gain some observability into io-uring is to
use `perf` to sample your program. Whilst this works, it can be hard
to get a mental picture of how your program flows since perf reports a
linear history of the tracepoints it managed to collect. Our tool on
the other hand, traces requests as they go through io-uring
and provide an idiomatic way to understand how your IO-requests are handled as they go
through the kernel. Under the hood, this tracer uses eBPF technology to hook into
kernel tracepoints. Unlike perf, it is much more versatile to be extended to
hook into arbritrary points in the kernel to support future
enhancements to tracing.

  Visualization features:

- Path of IO requests from submission to completion
- Syscall time slices
- Kernel spawned IO-worker's timeline
- Multiple rings support

## Path of IO request from submission to completion

The io-uring runtime makes several decisions on how your request
should be processed asynchronously. In particular, there are 3
pathways that can happen in the `io_issue_sqe` kernel call:

1. Direct Submission (fast path): If the operation can be started
   immediately and is likely to complete quickly (and asynchronously),
   `io_issue_sqe` will directly submit the I/O operation to the device
   driver or appropriate subsystem. This is done in a way that does
   not block the submitting process.

2. Deferred Execution (slow path): In some cases, operations may not
   be able to start immediately or require more complex
   setup. `io_issue_sqe` can queue these operations internally within
   io_uring or hand them off to other parts of the kernel that will
   handle them asynchronously. This deferral is crucial for
   maintaining the non-blocking nature of io_uring. [Goes to the workqueue?]

3. Arm a poll?

This feature allows users to visualize the path a request takes in the
kernel. The lifetime of a request starts from a submission into the
SQring to a completion on the CQring. When you click on a request,
perfetto will draw arrows to show the path of an request. It also
shows linked requests to show the ordering expected by the program and
also ideally when the request is finally reaped by the users program.

## Syscall time slices

From the users perspective, io-uring is a performance win because
users can reduce the number of syscalls their program uses and
thereby - the overhead of context switch from user to kernel
modes. One way to see if your program is really benefitting from this
is to visualize the syscalls made.

You could use `strace` tool to get the numbers but that adds overhead
to your running program. This tool shows syscalls in the form of
timeslices so that you can see how much time your code spends from the
point of entry to exit of your syscall. This may provide more
information on how to tune your program.

## IO-worker tracks

io-uring internally uses something like a kernel workqueue to run your
IO request asynchronously. It's not obvious how many workers are
involved in processing the request and what worker might be blocked
for a long time. This tool shows each spawned io-worker as a track and the uring
instance it is associated to. The io-worker display's when it picked up a completion
for an io operation.

## Multiple uring instance support

Programs may intentionally use multiple rings. This tool supports
multiple visualization of multiple rings and organizes them in a
idiomatic way.

# Current support

- [-] Path of IO request from submission to completion
  - [ ] Tracepoint visualisation support set
    - [X] tracepoint:io_uring:io_uring_complete
    - [ ] tracepoint:io_uring:io_uring_cqe_overflow
    - [X] tracepoint:io_uring:io_uring_cqring_wait
    - [X] tracepoint:io_uring:io_uring_create
    - [ ] tracepoint:io_uring:io_uring_defer
    - [ ] tracepoint:io_uring:io_uring_fail_link
    - [ ] tracepoint:io_uring:io_uring_file_get
    - [ ] tracepoint:io_uring:io_uring_link
    - [ ] tracepoint:io_uring:io_uring_local_work_run
    - [ ] tracepoint:io_uring:io_uring_poll_arm
    - [X] tracepoint:io_uring:io_uring_queue_async_work
    - [ ] tracepoint:io_uring:io_uring_register
    - [ ] tracepoint:io_uring:io_uring_req_failed
    - [ ] tracepoint:io_uring:io_uring_short_write
    - [X] tracepoint:io_uring:io_uring_submit_sqe
    - [ ] tracepoint:io_uring:io_uring_task_add
    - [ ] tracepoint:io_uring:io_uring_task_work_run
    - [X] tracepoint:syscalls:sys_enter_io_uring_enter
    - [X] tracepoint:syscalls:sys_enter_io_uring_register
    - [X] tracepoint:syscalls:sys_enter_io_uring_setup
    - [X] tracepoint:syscalls:sys_exit_io_uring_enter
    - [X] tracepoint:syscalls:sys_exit_io_uring_register
    - [X] tracepoint:syscalls:sys_exit_io_uring_setup

  - [ ] Trace flow when event flags set IO-uring SQE link to see user enforced ordering of events.
  - [ ] We probably want to trace when the user picks up the completion so that we can see the ring filling/freeing up

- [X] Syscall track
  - [X] io_uring_setup
  - [X] io_uring_register
  - [X] io_uring_enter

- [X] IO-worker tracks
  - [X] Show number of workers and their work associated to rings
  - [X] Connect to flows

- [X] Multiple uring instance support
  - [X] Add each uring instance as a "process" track
  - [X] Add associated tracks under "threads" track

- [ ] Suggestions
  - [ ] Track for Fixed buffer?
  - [ ] Find out if Uring can have parallel syscalls in flight, figure
    out how to account for this
  - [ ] Implement some kind of sampling of syscalls instead of tracing everything

# Undesirable Behaviours
This tool reads events through a shared ring buffer with the kernel. As such
there is a possibility that events are overwritten before they are read and processed
when tracing busy workloads. This can result in trace visualizations with missing 
events that look strange. To workaround this, the tracing tool has a sampling parameter
that can be tuned to trace only a percentage of the requests coming in.

# Discussion

Tracing vs Profiling

- The opaque and asynchronous nature of the uring runtime motivates
  tracing to give a picture of a programs execution to visualize where
  bottlenecks could be.
- Currently, it seems that the only way to get data from bpf programs
  is through a shared ring buffer, this is prone to overflows and lost
  events for high-throughput workloads.
- One solution would be to do sampling instead of full-blown tracing
  but this is fairly involved as we will need our program to implement
  some kind of rate limitting of requests so that flows can be
  properly recorded.
  - Per event ring buffer and global hashmap to filter seen req?
