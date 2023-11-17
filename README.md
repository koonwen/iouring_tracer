# iouring_tracer
Tracing tool for Linux IO-uring leveraging
[`bpftrace`](https://github.com/iovisor/bpftrace) to generate a trace
log.

# Features
- [ ] `iou` binary that runs loads the tracer and spawns the target
      program
- [ ] `iouring_tracer` library for directly attaching the tracer to
      programs that can't be run through the binary.
- [ ] TBC: OCaml API's for writing and generating custom eBPF programs.

# Install
``` shell
git clone git@github.com:koonwen/iouring_tracer.git
cd iouring_tracer
make switch
```

# Test
``` shell
make test_k
```
