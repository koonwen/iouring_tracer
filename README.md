# iouring_tracer
A tracing tool to help visualize how your workload performs under
Linux's asynchronous IO-uring runtime. This tracer leverages eBPF
probes ([`ocaml_libbpf`](https://github.com/koonwen/ocaml_libbpf)) to
extract information from the kernel. Traces are generated in fuchsia
format to be displayed on [Perfetto](https://ui.perfetto.dev/).

### Motivation
The current best way to gain some observability into io-uring is to
use `perf` to sample your program. Whilst this works, it can be hard
to get a mental picture of how your program flows since perf reports a
linear history of the tracepoints it managed to collect. Our tool on
the other hand, tries to trace requests as they go through io-uring
and provide an idiomatic way to understand your IO-requests as they go
through the kernel. Our tracer also uses eBPF technology to hook into
the kernel, unlike perf it is much more versatile to be extended to
hook into arbritrary points in the kernel to support future
enhancements to tracing.

  Features:
  - Path of IO requests from submission to completion
  - Syscall tracks
  - IO-worker tracks
  - Multiple rings support

## Path of IO request from submission to completion
The io-uring runtime makes several decisions on how your request
should be processed asynchronously. In particular, there are 3
pathways that happen in the `io_issue_sqe` kernel call:

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

## Syscall track
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
for a long time. This tool shows an io-worker as a track and the uring
instance it is associated to. The io-worker display's the timeslice of
the IO task that it ran.

## Multiple uring instance support
Programs may intentionally use multiple rings. This tool supports
multiple visualization of multiple rings and organizes them in a
idiomatic way.

# Current support
  -  Path of IO request from submission to completion
    - [X] Submission & Completion Ring Tracks
    - [ ] Trace flow to completion
	  - [X] io_uring_submit
	  - [ ] io_uring_queue_async_work
	  - [ ] io_uring_poll_arm
	  - [X] io_uring_complete
    - [ ] Trace flow when event flags set IO-uring SQE link to see user enforced ordering of events.
    - [ ] We probably want to trace when the user picks up the completion so that we can see the ring filling/freeing up

      io_uring_submit tracepoint is part of kernel io_uring:io_submit_sqe, this happens after io_uring_enter
      io_uring_complete tracepoint happens in kernel io_uring:io_fill_cqe_aux

  - [-] Syscall track
    - [ ] io_uring_setup
    - [ ] io_uring_register
    - [X] io_uring_enter
    - [ ] How to view context switches?

  - [ ] IO-worker tracks
    - [ ] Show number of workers and their work associated to rings
    - [ ] Connect to flows

  - [ ] Multiple uring instance support
	- [ ] Add each uring instance as a "process" track
	- [ ] Add associated tracks under "threads" track

  - [ ] Suggestions
    - [ ] Track for Fixed buffer?
    - [ ] Find out if Uring can have parallel syscalls in flight, figure
    out how to account for this
    - [ ] Implement some kind of sampling of syscalls instead of tracing everything

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
