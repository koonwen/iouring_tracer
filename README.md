# iouring_tracer
Tracing tool for Linux IO-uring leveraging
[`bpftrace`](https://github.com/iovisor/bpftrace) to generate a trace
log.

# Features
- [ ] `obpf` is a convenient executable that loads the tracer and
      spawns the target program program
- [ ] `obpftrace` library for directly attaching the tracer to
      programs that can't be run through the binary.
- [ ] TBC: OCaml API's for writing and generating custom eBPF programs.

# Install
``` shell
git clone git@github.com:koonwen/iouring_tracer.git
cd iouring_tracer
make switch
```

# Usage
``` shell
obpf <path to program>
```

Or as a library

``` ocaml
let main () = <program logic>
let () = Obpftrace.Driver.tracepoints main
```
You can find trace log in `trace.txt`

# Sample trace

``` shell
Attaching 25 probes...
[17:37:53]: Tracing IO_uring kprobes...
[17:37:53]: kprobe:io_uring_setup eio_kprobes.exe
[17:37:53]: kprobe:io_uring_alloc_task_context eio_kprobes.exe
[17:37:53]: kprobe:io_uring_mmu_get_unmapped_area eio_kprobes.exe
[17:37:53]: kprobe:io_uring_validate_mmap_request.isra.0 eio_kprobes.exe
[17:37:53]: kprobe:io_uring_mmap eio_kprobes.exe
[17:37:53]: kprobe:io_uring_validate_mmap_request.isra.0 eio_kprobes.exe
[17:37:53]: kprobe:io_uring_mmu_get_unmapped_area eio_kprobes.exe
[17:37:53]: kprobe:io_uring_validate_mmap_request.isra.0 eio_kprobes.exe
[17:37:53]: kprobe:io_uring_mmap eio_kprobes.exe
[17:37:53]: kprobe:io_uring_validate_mmap_request.isra.0 eio_kprobes.exe
[17:37:56]: kprobe:io_uring_get_socket Xwayland
[17:37:56]: kprobe:io_uring_get_socket Xwayland
[17:37:56]: kprobe:io_uring_get_socket Xwayland
[17:37:56]: kprobe:io_uring_get_socket gnome-shell
[17:37:56]: kprobe:io_uring_get_socket gnome-shell
[17:37:56]: kprobe:io_uring_get_socket gnome-shell
[17:37:59]: kprobe:io_uring_release eio_kprobes.exe
[17:37:59]: kprobe:io_uring_try_cancel_requests kworker/u16:9
[17:37:59]: kprobe:io_uring_del_tctx_node eio_kprobes.exe
[17:38:01]: kprobe:io_uring_unreg_ringfd eio_kprobes.exe
[17:38:01]: kprobe:io_uring_cancel_generic eio_kprobes.exe
[17:38:01]: kprobe:io_uring_drop_tctx_refs eio_kprobes.exe
[17:38:01]: kprobe:io_uring_clean_tctx eio_kprobes.exe


@reads[kprobe:io_uring_alloc_task_context]: 1
@reads[kprobe:io_uring_try_cancel_requests]: 1
@reads[kprobe:io_uring_clean_tctx]: 1
@reads[kprobe:io_uring_cancel_generic]: 1
@reads[kprobe:io_uring_unreg_ringfd]: 1
@reads[kprobe:io_uring_release]: 1
@reads[kprobe:io_uring_del_tctx_node]: 1
@reads[kprobe:io_uring_drop_tctx_refs]: 1
@reads[kprobe:io_uring_setup]: 1
@reads[kprobe:io_uring_mmu_get_unmapped_area]: 2
@reads[kprobe:io_uring_mmap]: 2
@reads[kprobe:io_uring_validate_mmap_request.isra.0]: 4
@reads[kprobe:io_uring_get_socket]: 6
```
