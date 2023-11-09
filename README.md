# iouring_tracer
High-level tracing tool for Linux IO-uring based on eBPF technology
and leveraging [`bpftrace`](https://github.com/iovisor/bpftrace) to
output a trace log.

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
