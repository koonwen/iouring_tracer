#include "vmlinux.h"
#include "uring.h"
#include <bpf/bpf_helpers.h>

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

static struct event *__init_event(enum tracepoint_t ty) {
  struct event *e;
  u64 id;

  /* Try to reserve space from BPF ringbuf */
  e = bpf_ringbuf_reserve(&rb, sizeof(*e), 0);
  if (!e) {
    __incr_counter();
    return NULL;
  }
  id = bpf_get_current_pid_tgid();
  e->ty = ty;
  e->pid = id >> 32;
  e->tid = id;
  e->ts = bpf_ktime_get_ns();
  bpf_get_current_comm(&e->comm, sizeof(e->comm));

  /* bpf_printk("(%d) %d:%d", t, e->pid, e->tid); */

  return e;
}

SEC("tp/io_uring/io_uring_create")
int handle_create(struct trace_event_raw_io_uring_create *ctx) {
  struct event *e;
  struct io_uring_create *extra;

  e = __init_event(IO_URING_CREATE);
  if (e == NULL)
    return 1;

  extra = &(e->io_uring_create);
  extra->fd = ctx->fd;
  extra->ctx = ctx->ctx;
  extra->sq_entries = ctx->sq_entries;
  extra->cq_entries = ctx->cq_entries;
  extra->flags = ctx->flags;

  bpf_ringbuf_submit(e, 0);
  return 0;
}

SEC("tp/io_uring/io_uring_register")
int handle_register(struct trace_event_raw_io_uring_register *ctx) {
  struct event *e;
  struct io_uring_register *extra;

  e = __init_event(IO_URING_REGISTER);
  if (e == NULL)
    return 1;

  extra = &(e->io_uring_register);
  extra->ctx = ctx->ctx;
  extra->opcode = ctx->opcode;
  extra->nr_files = ctx->nr_files;
  extra->ret = ctx->ret;

  bpf_ringbuf_submit(e, 0);
  return 0;
}

SEC("tp/io_uring/io_uring_file_get")
int handle_file_get(struct trace_event_raw_io_uring_file_get *ctx) {
  struct event *e;
  struct io_uring_file_get *extra;

  e = __init_event(IO_URING_FILE_GET);
  if (e == NULL)
    return 1;

  extra = &(e->io_uring_file_get);
  extra->ctx = ctx->ctx;
  extra->req = ctx->req;
  extra->fd = ctx->fd;

  bpf_ringbuf_submit(e, 0);
  return 0;
}

SEC("tp/io_uring/io_uring_submit_sqe")
int handle_submit_sqe(struct trace_event_raw_io_uring_submit_sqe *ctx) {
  struct event *e;
  struct io_uring_submit_sqe *extra;
  struct io_kiocb *io_kiocb;
  unsigned op_str_off;

  e = __init_event(IO_URING_SUBMIT_SQE);
  if (e == NULL)
    return 1;

  extra = &(e->io_uring_submit_sqe);
  extra->ctx = ctx->ctx;
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
int handle_queue_async_work(
    struct trace_event_raw_io_uring_queue_async_work *ctx) {
  struct event *e;
  struct io_uring_queue_async_work *extra;
  unsigned op_str_off;

  e = __init_event(IO_URING_QUEUE_ASYNC_WORK);
  if (e == NULL)
    return 1;

  extra = &(e->io_uring_queue_async_work);
  extra->ctx = ctx->ctx;
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

SEC("tp/io_uring/io_uring_poll_arm")
int handle_poll_arm(struct trace_event_raw_io_uring_poll_arm *ctx) {
  struct event *e;
  struct io_uring_poll_arm *extra;
  unsigned op_str_off;

  e = __init_event(IO_URING_POLL_ARM);
  if (e == NULL)
    return 1;

  extra = &(e->io_uring_poll_arm);
  extra->ctx = ctx->ctx;
  extra->req = ctx->req;
  extra->opcode = ctx->opcode;
  extra->mask = ctx->mask;
  extra->events = ctx->events;
  op_str_off = ctx->__data_loc_op_str & 0xFFFF;
  bpf_probe_read_str(&(extra->op_str), sizeof(extra->op_str),
                     (void *)ctx + op_str_off);

  bpf_ringbuf_submit(e, 0);
  return 0;
}

SEC("tp/io_uring/io_uring_task_add")
int handle_task_add(struct trace_event_raw_io_uring_task_add *ctx) {
  struct event *e;
  struct io_uring_task_add *extra;
  unsigned op_str_off;

  e = __init_event(IO_URING_TASK_ADD);
  if (e == NULL)
    return 1;

  extra = &(e->io_uring_task_add);
  extra->ctx = ctx->ctx;
  extra->req = ctx->req;
  extra->mask = ctx->mask;
  extra->opcode = ctx->opcode;
  op_str_off = ctx->__data_loc_op_str & 0xFFFF;
  bpf_probe_read_str(&(extra->op_str), sizeof(extra->op_str),
                     (void *)ctx + op_str_off);

  bpf_ringbuf_submit(e, 0);
  return 0;
}

SEC("tp/io_uring/io_uring_task_work_run")
int handle_task_work_run(struct trace_event_raw_io_uring_task_work_run *ctx) {
  struct event *e;
  struct io_uring_task_work_run *extra;

  e = __init_event(IO_URING_TASK_WORK_RUN);
  if (e == NULL)
    return 1;

  extra = &(e->io_uring_task_work_run);
  extra->tctx = ctx->tctx;
  extra->count = ctx->count;
  extra->loops = ctx->loops;

  bpf_ringbuf_submit(e, 0);
  return 0;
}

SEC("tp/io_uring/io_uring_short_write")
int handle_short_write(struct trace_event_raw_io_uring_short_write *ctx) {
  struct event *e;
  struct io_uring_short_write *extra;

  e = __init_event(IO_URING_SHORT_WRITE);
  if (e == NULL)
    return 1;

  extra = &(e->io_uring_short_write);
  extra->ctx = ctx->ctx;
  extra->fpos = ctx->fpos;
  extra->wanted = ctx->wanted;
  extra->got = ctx->got;

  bpf_ringbuf_submit(e, 0);
  return 0;
}

SEC("tp/io_uring/io_uring_local_work_run")
int handle_local_work_run(struct trace_event_raw_io_uring_local_work_run *ctx) {
  struct event *e;
  struct io_uring_local_work_run *extra;

  e = __init_event(IO_URING_TASK_WORK_RUN);
  if (e == NULL)
    return 1;

  extra = &(e->io_uring_local_work_run);
  extra->ctx = ctx->ctx;
  extra->count = ctx->count;
  extra->loops = ctx->loops;

  bpf_ringbuf_submit(e, 0);
  return 0;
}

SEC("tp/io_uring/io_uring_defer")
int handle_defer(struct trace_event_raw_io_uring_defer *ctx) {
  struct event *e;
  struct io_uring_defer *extra;
  unsigned op_str_off;

  e = __init_event(IO_URING_DEFER);
  if (e == NULL)
    return 1;

  extra = &(e->io_uring_defer);
  extra->ctx = ctx->ctx;
  extra->req = ctx->req;
  extra->opcode = ctx->opcode;
  op_str_off = ctx->__data_loc_op_str & 0xFFFF;
  bpf_probe_read_str(&(extra->op_str), sizeof(extra->op_str),
                     (void *)ctx + op_str_off);

  bpf_ringbuf_submit(e, 0);
  return 0;
}

SEC("tp/io_uring/io_uring_link")
int handle_link(struct trace_event_raw_io_uring_link *ctx) {
  struct event *e;
  struct io_uring_link *extra;

  e = __init_event(IO_URING_LINK);
  if (e == NULL)
    return 1;

  extra = &(e->io_uring_link);
  extra->ctx = ctx->ctx;
  extra->req = ctx->req;
  extra->target_req = ctx->target_req;

  bpf_ringbuf_submit(e, 0);
  return 0;
}

SEC("tp/io_uring/io_uring_fail_link")
int handle_fail_link(struct trace_event_raw_io_uring_fail_link *ctx) {
  struct event *e;
  struct io_uring_fail_link *extra;
  unsigned op_str_off;

  e = __init_event(IO_URING_FAIL_LINK);
  if (e == NULL)
    return 1;

  extra = &(e->io_uring_fail_link);
  extra->ctx = ctx->ctx;
  extra->req = ctx->req;
  extra->opcode = ctx->opcode;
  extra->link = ctx->link;
  op_str_off = ctx->__data_loc_op_str & 0xFFFF;
  bpf_probe_read_str(&(extra->op_str), sizeof(extra->op_str),
                     (void *)ctx + op_str_off);

  bpf_ringbuf_submit(e, 0);
  return 0;
}

SEC("tp/io_uring/io_uring_cqring_wait")
int handle_cqring_wait(struct trace_event_raw_io_uring_cqring_wait *ctx) {
  struct event *e;
  struct io_uring_cqring_wait *extra;

  e = __init_event(IO_URING_CQRING_WAIT);
  if (e == NULL)
    return 1;

  extra = &(e->io_uring_cqring_wait);
  extra->ctx = ctx->ctx;
  extra->min_events = ctx->min_events;

  bpf_ringbuf_submit(e, 0);
  return 0;
}

SEC("tp/io_uring/io_uring_req_failed")
int handle_req_failed(struct trace_event_raw_io_uring_req_failed *ctx) {
  struct event *e;
  struct io_uring_req_failed *extra;
  unsigned op_str_off;

  e = __init_event(IO_URING_REQ_FAILED);
  if (e == NULL)
    return 1;

  extra = &(e->io_uring_req_failed);
  extra->ctx = ctx->ctx;
  extra->req = ctx->req;
  extra->opcode = ctx->opcode;
  extra->flags = ctx->flags;
  extra->ioprio = ctx->ioprio;
  extra->off = ctx->off;
  extra->addr = ctx->addr;
  extra->len = ctx->len;
  extra->op_flags = ctx->op_flags;
  extra->buf_index = ctx->buf_index;
  extra->personality = ctx->personality;
  extra->file_index = ctx->file_index;
  extra->pad1 = ctx->pad1;
  extra->addr3 = ctx->addr3;
  extra->error = ctx->error;
  op_str_off = ctx->__data_loc_op_str & 0xFFFF;
  bpf_probe_read_str(&(extra->op_str), sizeof(extra->op_str),
                     (void *)ctx + op_str_off);

  bpf_ringbuf_submit(e, 0);
  return 0;
}

SEC("tp/io_uring/io_uring_cqe_overflow")
int handle_cqe_overflow(struct trace_event_raw_io_uring_cqe_overflow *ctx) {
  struct event *e;
  struct io_uring_cqe_overflow *extra;
  unsigned op_str_off;

  e = __init_event(IO_URING_CQE_OVERFLOW);
  if (e == NULL)
    return 1;

  extra = &(e->io_uring_cqe_overflow);
  extra->ctx = ctx->ctx;
  extra->user_data = ctx->user_data;
  extra->res = ctx->res;
  extra->cflags = ctx->cflags;
  extra->ocqe = ctx->ocqe;

  bpf_ringbuf_submit(e, 0);
  return 0;
}

SEC("tp/io_uring/io_uring_complete")
int handle_complete(struct trace_event_raw_io_uring_complete *ctx) {
  struct event *e;
  struct io_uring_complete *extra;

  e = __init_event(IO_URING_COMPLETE);
  if (e == NULL)
    return 1;

  extra = &(e->io_uring_complete);
  extra->ctx = ctx->ctx;
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
  if (e == NULL)
    return 1;

  bpf_ringbuf_submit(e, 0);
  return 0;
}

SEC("tp/syscalls/sys_exit_io_uring_enter")
int handle_sys_exit_io_uring_enter(struct trace_event_raw_sys_enter *ctx) {
  struct event *e;

  e = __init_event(SYS_EXIT_IO_URING_ENTER);
  if (e == NULL)
    return 1;

  bpf_ringbuf_submit(e, 0);
  return 0;
}
