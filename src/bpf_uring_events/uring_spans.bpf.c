// SPDX-License-Identifier: GPL-2.0 OR BSD-3-Clause
/* Copyright (c) 2020 Andrii Nakryiko */
#include "vmlinux.h"
#include "uring_spans.h"
#include <bpf/bpf_helpers.h>

char LICENSE[] SEC("license") = "Dual BSD/GPL";

/* BPF ringbuf map */
struct {
    __uint(type, BPF_MAP_TYPE_RINGBUF);
    __uint(max_entries, 256 * 1024 /* 256 KB */);
} rb SEC(".maps");

static inline int __ker_ev_handler(syscalls_t probe, span_t span) {
    struct event *e;

    e = bpf_ringbuf_reserve(&rb, sizeof(*e), 0);
    if (!e)
        return 0;
    __u64 id;

    id = bpf_get_current_pid_tgid();
    e->pid = id >> 32;
    e->tid = id;
    e->probe = probe;
    e->span = span;
    e->ktime_ns = bpf_ktime_get_ns();
    bpf_get_current_comm(&e->comm, sizeof(e->comm));

    bpf_ringbuf_submit(e, 0);
    return 0;
}
SEC("tp/syscalls/sys_exit_io_uring_register")
int handle_sys_exit_io_uring_register(void *ctx) {
  bpf_printk("sys_exit_io_uring_register");
  return __ker_ev_handler(SYS_IO_URING_REGISTER, END);
}

SEC("tp/syscalls/sys_enter_io_uring_register")
int handle_sys_enter_io_uring_register(void *ctx) {
  bpf_printk("sys_enter_io_uring_register");
  return __ker_ev_handler(SYS_IO_URING_REGISTER, BEGIN);
}

SEC("tp/syscalls/sys_exit_io_uring_setup")
int handle_sys_exit_io_uring_setup(void *ctx) {
  bpf_printk("sys_exit_io_uring_setup");
  return __ker_ev_handler(SYS_IO_URING_SETUP, END);
}

SEC("tp/syscalls/sys_enter_io_uring_setup")
int handle_sys_enter_io_uring_setup(void *ctx) {
  bpf_printk("sys_enter_io_uring_setup");
  return __ker_ev_handler(SYS_IO_URING_SETUP, BEGIN);
}

SEC("tp/syscalls/sys_exit_io_uring_enter")
int handle_sys_exit_io_uring_enter(void *ctx) {
  bpf_printk("sys_exit_io_uring_enter");
  return __ker_ev_handler(SYS_IO_URING_ENTER, END);
}

SEC("tp/syscalls/sys_enter_io_uring_enter")
int handle_sys_enter_io_uring_enter(void *ctx) {
  bpf_printk("sys_enter_io_uring_enter");
  return __ker_ev_handler(SYS_IO_URING_ENTER, BEGIN);
}
