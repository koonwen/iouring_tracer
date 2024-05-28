#include "vmlinux.h"
#include "uring.h"
#include <bpf/bpf_helpers.h>

char LICENSE[] SEC("license") = "Dual BSD/GPL";

/* BPF ringbuf map */
struct {
  __uint(type, BPF_MAP_TYPE_RINGBUF);
  __uint(max_entries, 256 * 1024 /* 256 KB */);
} rb SEC(".maps");

/* Create an array with 1 entry instead of a global variable
 * which does not work with older kernels */
struct {
  __uint(type, BPF_MAP_TYPE_ARRAY);
  __uint(max_entries, 1);
  __type(key, int);
  __type(value, long);
} global_counter SEC(".maps");

int global_counter_index = 0;
long v = 0;
long *value;
/* Figure out how to use this static functions */
/* static inline int __init_event(struct event *e, enum tracepoint_t t) { */
/*   u64 id, ts; */

/*   id = bpf_get_current_pid_tgid(); */
/*   ts = bpf_ktime_get_ns(); */

/*   e->t = t; */
/*   e->pid = id >> 32; */
/*   e->tid = id; */
/*   e->ts = ts; */
/*   bpf_get_current_comm(&e->comm, sizeof(e->comm)); */
/*   return 0; */
/* } */

static inline void __incr_counter(void) {
    long *value;
    value = bpf_map_lookup_elem(&global_counter, &global_counter_index);
    if (value == NULL) {
      bpf_printk("Error got NULL");
      value = &v;
    };
    v = *value + 1;
    bpf_map_update_elem(&global_counter, &global_counter_index, &v, 0);
}

SEC("tp/io_uring/io_uring_submit_sqe")
int handle_submit(struct trace_event_raw_io_uring_submit_sqe *ctx) {
  struct event *e;
  struct io_uring_submit_sqe *extra;
  unsigned op_str_off;

  u64 id, ts;
  /* reserve sample from BPF ringbuf */
  e = bpf_ringbuf_reserve(&rb, sizeof(*e), 0);
  if (!e) {
    __incr_counter();
    return 1;
  }

  id = bpf_get_current_pid_tgid();
  ts = bpf_ktime_get_ns();

  e->t = IO_URING_SUBMIT_SQE;
  e->pid = id >> 32;
  e->tid = id;
  e->ts = ts;
  bpf_get_current_comm(&e->comm, sizeof(e->comm));

  extra = &(e->extra.io_uring_submit_sqe);
  extra->req = ctx->req;
  extra->opcode = ctx->opcode;
  extra->flags = ctx->flags;
  extra->force_nonblock = ctx->force_nonblock;
  extra->sq_thread = ctx->sq_thread;
  op_str_off = ctx->__data_loc_op_str & 0xFFFF;
  bpf_probe_read_str(&(extra->op_str), sizeof(extra->op_str),
                     (void *)ctx + op_str_off);
  /* bpf_printk( */
  /*     "req = 0x%llx, opcode = %u, flags 0x%x, force_nonblock %d, sq_thread "
   */
  /*     "%d, op %s", */
  /*     extra->req, extra->opcode, extra->flags, extra->force_nonblock, */
  /*     extra->sq_thread, extra->op_str); */

  bpf_ringbuf_submit(e, 0);
  return 0;
}

SEC("tp/io_uring/io_uring_complete")
int handle_complete(struct trace_event_raw_io_uring_complete *ctx) {
  struct event *e;
  struct io_uring_complete *extra;

  u64 id, ts;
  /* reserve sample from BPF ringbuf */
  if (!e) {
    __incr_counter();
    return 1;
  }

  id = bpf_get_current_pid_tgid();
  ts = bpf_ktime_get_ns();

  e->t = IO_URING_COMPLETE;
  e->pid = id >> 32;
  e->tid = id;
  e->ts = ts;
  bpf_get_current_comm(&e->comm, sizeof(e->comm));

  extra = &(e->extra.io_uring_complete);
  extra->req = ctx->req;
  extra->res = ctx->res;
  extra->cflags = ctx->cflags;
  /* bpf_printk("req = 0x%llx, res = %d, cflags = %ud", extra->req, extra->res,
   */
  /*            extra->cflags); */

  bpf_ringbuf_submit(e, 0);
  return 0;
}

SEC("tp/syscalls/sys_enter_io_uring_enter")
int handle_sys_enter_io_uring_enter(struct trace_event_raw_sys_enter *ctx) {
  struct event *e;

  u64 id, ts;
  /* reserve sample from BPF ringbuf */
  e = bpf_ringbuf_reserve(&rb, sizeof(*e), 0);

  if (!e) {
    __incr_counter();
    return 1;
  }

  id = bpf_get_current_pid_tgid();
  ts = bpf_ktime_get_ns();

  e->t = SYS_ENTER_IO_URING_ENTER;
  e->pid = id >> 32;
  e->tid = id;
  e->ts = ts;
  bpf_get_current_comm(&e->comm, sizeof(e->comm));

  bpf_ringbuf_submit(e, 0);
  return 0;
}

SEC("tp/syscalls/sys_exit_io_uring_enter")
int handle_sys_exit_io_uring_enter(struct trace_event_raw_sys_enter *ctx) {
  struct event *e;

  u64 id, ts;
  /* reserve sample from BPF ringbuf */
  e = bpf_ringbuf_reserve(&rb, sizeof(*e), 0);
  if (!e) {
    __incr_counter();
    return 1;
  }

  id = bpf_get_current_pid_tgid();
  ts = bpf_ktime_get_ns();

  e->t = SYS_EXIT_IO_URING_ENTER;
  e->pid = id >> 32;
  e->tid = id;
  e->ts = ts;
  bpf_get_current_comm(&e->comm, sizeof(e->comm));

  bpf_ringbuf_submit(e, 0);
  return 0;
}
