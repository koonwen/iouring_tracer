// SPDX-License-Identifier: GPL-2.0 OR BSD-3-Clause
/* Copyright (c) 2020 Andrii Nakryiko */
#include "defs.h"
/* #include "common.h" */
/* #include "vmlinux.h" */
#include <linux/types.h>
#include <time.h>
#include <linux/bpf.h>
#include <bpf/bpf_helpers.h>


char LICENSE[] SEC("license") = "Dual BSD/GPL";

/* BPF ringbuf map */
struct {
  __uint(type, BPF_MAP_TYPE_RINGBUF);
  __uint(max_entries, 256 * 1024 /* 256 KB */);
} rb SEC(".maps");

static inline int __ker_ev_handler(probe_t probe, int probe_id, span_t span) {
  struct event *e;

  e = bpf_ringbuf_reserve(&rb, sizeof(*e), 0);
  if (!e) {
      return 0;
  };
  __u64 id;

  id = bpf_get_current_pid_tgid();
  e->pid = id >> 32;
  e->tid = id;
  e->probe = probe;
  e->probe_id = probe_id;
  e->span = span;
  e->ktime_ns = bpf_ktime_get_ns();
  bpf_get_current_comm(&e->comm, sizeof(e->comm));

  /* Debug */
  if (probe == SYSCALL) {
    if (span == BEGIN)
      bpf_printk("BPF syscalls id %d OPEN triggered from PID %d.\n", probe_id,
                 e->pid);
    else
      bpf_printk("BPF syscalls id %d CLOSE triggered from PID %d.\n", probe_id,
                 e->pid);
  };

  bpf_ringbuf_submit(e, 0);
  return 0;
}

SEC("tp/io_uring/io_uring_complete")
int handle_complete(struct trace_event_io_uring_complete *ctx) {
  bpf_printk("io_uring_complete");
  return __ker_ev_handler(TRACEPOINT, IO_URING_COMPLETE, -1);
}

SEC("tp/io_uring/io_uring_cqe_overflow")
int handle_cqe_overflow(struct trace_event_io_uring_cqe_overflow *ctx) {
  bpf_printk("io_uring_cqe_overflow");
  return __ker_ev_handler(TRACEPOINT, IO_URING_CQE_OVERFLOW, -1);
}

SEC("tp/io_uring/io_uring_fail_link")
int handle_fail_link(struct trace_event_io_uring_fail_link *ctx) {
  bpf_printk("io_uring_fail_link");
  return __ker_ev_handler(TRACEPOINT, IO_URING_FAIL_LINK, -1);
}

SEC("tp/io_uring/io_uring_file_get")
int handle_file_get(struct trace_event_io_uring_file_get *ctx) {
  bpf_printk("io_uring_file_get");
  return __ker_ev_handler(TRACEPOINT, IO_URING_FILE_GET, -1);
}

SEC("tp/io_uring/io_uring_link")
int handle_link(struct trace_event_io_uring_link *ctx) {
  bpf_printk("io_uring_link");
  return __ker_ev_handler(TRACEPOINT, IO_URING_LINK, -1);
}

SEC("tp/io_uring/io_uring_local_work_run")
int handle_local_work_run(struct trace_event_io_uring_local_work_run *ctx) {
  bpf_printk("io_uring_local_work_run");
  return __ker_ev_handler(TRACEPOINT, IO_URING_LOCAL_WORK_RUN, -1);
}

SEC("tp/io_uring/io_uring_poll_arm")
int handle_poll_arm(struct trace_event_io_uring_poll_arm *ctx) {
  bpf_printk("io_uring_poll_arm");
  return __ker_ev_handler(TRACEPOINT, IO_URING_POLL_ARM, -1);
}

SEC("tp/io_uring/io_uring_queue_async_work")
int handle_queue_async_work(struct trace_event_io_uring_queue_async_work *ctx) {
  bpf_printk("io_uring_queue_async_work");
  return __ker_ev_handler(TRACEPOINT, IO_URING_QUEUE_ASYNC_WORK, -1);
}

SEC("tp/io_uring/io_uring_register")
int handle_register(struct trace_event_io_uring_register *ctx) {
  bpf_printk("io_uring_register");
  return __ker_ev_handler(TRACEPOINT, IO_URING_REGISTER, -1);
}

SEC("tp/io_uring/io_uring_req_failed")
int handle_req_failed(struct trace_event_io_uring_req_failed *ctx) {
  bpf_printk("io_uring_req_failed");
  return __ker_ev_handler(TRACEPOINT, IO_URING_REQ_FAILED, -1);
}

SEC("tp/io_uring/io_uring_short_write")
int handle_short_write(struct trace_event_io_uring_short_write *ctx) {
  bpf_printk("io_uring_short_write");
  return __ker_ev_handler(TRACEPOINT, IO_URING_SHORT_WRITE, -1);
}

SEC("tp/io_uring/io_uring_submit_sqe")
int handle_submit_sqe(struct trace_event_io_uring_submit_sqe *ctx) {
  bpf_printk("io_uring_submit_sqe");
  return __ker_ev_handler(TRACEPOINT, IO_URING_SUBMIT_SQE, -1);
}
SEC("tp/io_uring/io_uring_task_add")
int handle_task_add(struct trace_event_io_uring_task_add *ctx) {
  bpf_printk("io_uring_task_add");
  return __ker_ev_handler(TRACEPOINT, IO_URING_TASK_ADD, -1);
}
SEC("tp/io_uring/io_uring_task_work_run")
int handle_task_work_run(struct trace_event_io_uring_task_work_run *ctx) {
  bpf_printk("io_uring_task_work_run");
  return __ker_ev_handler(TRACEPOINT, IO_URING_TASK_WORK_RUN, -1);
}

SEC("tp/syscalls/sys_exit_io_uring_register")
int handle_sys_exit_io_uring_register(void *ctx) {
  bpf_printk("sys_exit_io_uring_register");
  return __ker_ev_handler(SYSCALL, SYS_IO_URING_REGISTER, END);
}

SEC("tp/syscalls/sys_enter_io_uring_register")
int handle_sys_enter_io_uring_register(void *ctx) {
  bpf_printk("sys_enter_io_uring_register");
  return __ker_ev_handler(SYSCALL, SYS_IO_URING_REGISTER, BEGIN);
}

SEC("tp/syscalls/sys_exit_io_uring_setup")
int handle_sys_exit_io_uring_setup(void *ctx) {
  bpf_printk("sys_exit_io_uring_setup");
  return __ker_ev_handler(SYSCALL, SYS_IO_URING_SETUP, END);
}

SEC("tp/syscalls/sys_enter_io_uring_setup")
int handle_sys_enter_io_uring_setup(void *ctx) {
  bpf_printk("sys_enter_io_uring_setup");
  return __ker_ev_handler(SYSCALL, SYS_IO_URING_SETUP, BEGIN);
}

SEC("tp/syscalls/sys_exit_io_uring_enter")
int handle_sys_exit_io_uring_enter(void *ctx) {
  bpf_printk("sys_exit_io_uring_enter");
  return __ker_ev_handler(SYSCALL, SYS_IO_URING_ENTER, END);
}

SEC("tp/syscalls/sys_enter_io_uring_enter")
int handle_sys_enter_io_uring_enter(void *ctx) {
  bpf_printk("sys_enter_io_uring_enter");
  return __ker_ev_handler(SYSCALL, SYS_IO_URING_ENTER, BEGIN);
}
