#include "vmlinux.h"
#include <bpf/bpf_helpers.h>
#include "uring_ops.h"

char LICENSE[] SEC("license") = "Dual BSD/GPL";

/* BPF ringbuf map */
struct {
  __uint(type, BPF_MAP_TYPE_RINGBUF);
  __uint(max_entries, 256 * 1024 /* 256 KB */);
} rb SEC(".maps");

static inline int __init_event(struct event *e, enum tracepoint_t t) {
  u64 id, ts;
  /* reserve sample from BPF ringbuf */
  e = bpf_ringbuf_reserve(&rb, sizeof(*e), 0);
  if (!e)
    return 1;

  id = bpf_get_current_pid_tgid();
  ts = bpf_ktime_get_ns();

  e->t = t;
  e->pid = id >> 32;
  e->tid = id;
  e->ts = ts;
  bpf_get_current_comm(&e->comm, sizeof(e->comm));
  return 0;
}

SEC("tp/io_uring/io_uring_submit_sqe")
int handle_submit(struct trace_event_raw_io_uring_submit_sqe *ctx) {
  struct event *e;
  struct io_uring_submit_sqe *extra;
  unsigned op_str_off;

  /* if (__init_event(e, IO_URING_SUBMIT_SQE)) return 1; */
  u64 id, ts;
  /* reserve sample from BPF ringbuf */
  e = bpf_ringbuf_reserve(&rb, sizeof(*e), 0);
  if (!e)
    return 1;

  extra = &(e->extra.io_uring_submit_sqe);

  id = bpf_get_current_pid_tgid();
  ts = bpf_ktime_get_ns();

  e->t = IO_URING_SUBMIT_SQE;
  e->pid = id >> 32;
  e->tid = id;
  e->ts = ts;
  bpf_get_current_comm(&e->comm, sizeof(e->comm));

  extra->req = ctx->req;
  extra->opcode = ctx->opcode;
  extra->flags = ctx->flags;
  extra->force_nonblock = ctx->force_nonblock;
  extra->sq_thread = ctx->sq_thread;
  op_str_off = ctx->__data_loc_op_str & 0xFFFF;
  bpf_probe_read_str(&(extra->op_str), sizeof(extra->op_str),
                     (void *)ctx + op_str_off);
  bpf_printk(
      "req = 0x%llx, opcode = %u, flags 0x%x, force_nonblock %d, sq_thread "
      "%d, op %s",
      extra->req, extra->opcode, extra->flags, extra->force_nonblock,
      extra->sq_thread, extra->op_str);

  bpf_ringbuf_submit(e, 0);
  return 0;
}

SEC("tp/io_uring/io_uring_complete")
int handle_complete(struct trace_event_raw_io_uring_complete *ctx) {
  struct event *e;
  struct io_uring_complete *extra;

  u64 id, ts;
  /* reserve sample from BPF ringbuf */
  e = bpf_ringbuf_reserve(&rb, sizeof(*e), 0);
  if (!e)
    return 1;

  extra = &(e->extra.io_uring_complete);

  id = bpf_get_current_pid_tgid();
  ts = bpf_ktime_get_ns();

  e->t = IO_URING_COMPLETE;
  e->pid = id >> 32;
  e->tid = id;
  e->ts = ts;
  bpf_get_current_comm(&e->comm, sizeof(e->comm));

  extra->req = ctx->req;
  extra->res = ctx->res;
  extra->cflags = ctx->cflags;
  bpf_printk("req = 0x%llx, res = %d, cflags = %ud", extra->req, extra->res,
             extra->cflags);

  bpf_ringbuf_submit(e, 0);
  return 0;
}
