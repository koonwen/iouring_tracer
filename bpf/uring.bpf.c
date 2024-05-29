#include "vmlinux.h"
#include <bpf/bpf_helpers.h>
#include "uring.h"

char LICENSE[] SEC("license") = "Dual BSD/GPL";

/* BPF ringbuf map */
struct {
  __uint(type, BPF_MAP_TYPE_RINGBUF);
  __uint(max_entries, 256 * 4096 /* 256 KB */);
} rb SEC(".maps");

/* Create an array with 1 entry instead of a global variable
 * which does not work with older kernels */
struct {
  __uint(type, BPF_MAP_TYPE_ARRAY);
  __uint(max_entries, 1);
  __type(key, int);
  __type(value, long);
} globals SEC(".maps");

int counter_index = 0;
long counter = 0;

static void __incr_counter(void) {
  long *value;
  value = bpf_map_lookup_elem(&globals, &counter_index);
  if (value == NULL) {
    bpf_printk("Error got NULL");
    return;
  };
  (*value)++;
  bpf_map_update_elem(&globals, &counter_index, value, 0);
}

/* Figure out how to use this static functions */
static struct event* __init_event(enum tracepoint_t t) {
  struct event* e;
  u64 id;

  /* Try to reserve space from BPF ringbuf */
  e = bpf_ringbuf_reserve(&rb, sizeof(*e), 0);
  if (!e) {
    __incr_counter();
    return NULL;
  }
  id = bpf_get_current_pid_tgid();
  e->t = t;
  e->pid = id >> 32;
  e->tid = id;
  e->ts = bpf_ktime_get_ns();
  bpf_get_current_comm(&e->comm, sizeof(e->comm));
  return e;
}

SEC("tp/io_uring/io_uring_submit_sqe")
int handle_submit(struct trace_event_raw_io_uring_submit_sqe *ctx) {
  struct event *e;
  struct io_uring_submit_sqe *extra;
  unsigned op_str_off;

  e = __init_event(IO_URING_SUBMIT_SQE);
  if (e == NULL) return 1;

  extra = &(e->extra.io_uring_submit_sqe);
  extra->req = ctx->req;
  extra->opcode = ctx->opcode;
  extra->flags = ctx->flags;
  extra->force_nonblock = ctx->force_nonblock;
  extra->sq_thread = ctx->sq_thread;
  op_str_off = ctx->__data_loc_op_str & 0xFFFF;
  bpf_probe_read_str(&(extra->op_str), sizeof(extra->op_str),
                     (void *)ctx + op_str_off);

  bpf_ringbuf_submit(e, 0);
  return 0;
}

SEC("tp/io_uring/io_uring_queue_async_work")
int handle_queue_async_work(struct trace_event_raw_io_uring_queue_async_work *ctx) {
  struct event *e;
  struct io_uring_queue_async_work *extra;
  unsigned op_str_off;

  e = __init_event(IO_URING_QUEUE_ASYNC_WORK);
  if (e == NULL) return 1;


  extra = &(e->extra.io_uring_queue_async_work);
  extra->req = ctx->req;
  extra->opcode = ctx->opcode;
  extra->flags = ctx->flags;
  extra->work = ctx->work;
    op_str_off = ctx->__data_loc_op_str & 0xFFFF;
  bpf_probe_read_str(&(extra->op_str), sizeof(extra->op_str),
                     (void *)ctx + op_str_off);

  bpf_ringbuf_submit(e, 0);
  return 0;
}

SEC("tp/io_uring/io_uring_complete")
int handle_complete(struct trace_event_raw_io_uring_complete *ctx) {
  struct event *e;
  struct io_uring_complete *extra;

  e = __init_event(IO_URING_COMPLETE);
  if (e == NULL) return 1;

  extra = &(e->extra.io_uring_complete);
  extra->req = ctx->req;
  extra->res = ctx->res;
  extra->cflags = ctx->cflags;

  bpf_ringbuf_submit(e, 0);
  return 0;
}

SEC("tp/syscalls/sys_enter_io_uring_enter")
int handle_sys_enter_io_uring_enter(struct trace_event_raw_sys_enter *ctx) {
  struct event *e;

  e = __init_event(SYS_ENTER_IO_URING_ENTER);
  if (e == NULL) return 1;

  bpf_ringbuf_submit(e, 0);
  return 0;
}

SEC("tp/syscalls/sys_exit_io_uring_enter")
int handle_sys_exit_io_uring_enter(struct trace_event_raw_sys_enter *ctx) {
  struct event *e;

  e = __init_event(SYS_EXIT_IO_URING_ENTER);
  if (e == NULL) return 1;

  bpf_ringbuf_submit(e, 0);
  return 0;
}
