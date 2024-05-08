/* SPDX-License-Identifier: (LGPL-2.1 OR BSD-2-Clause) */
/* Copyright (c) 2020 Andrii Nakryiko, 2024 Koonwen Lee */

#ifndef __URING_SPANS_H
#define __URING_SPANS_H
/* #include <stddef.h> */

typedef enum {
    SYS_IO_URING_SETUP,
    SYS_IO_URING_REGISTER,
    SYS_IO_URING_ENTER,
} syscalls_t;

typedef enum {
    BEGIN,
    END
} span_t;

#define TASK_COMM_LEN 16
/* definition of a sample sent to user-space from BPF program */
struct event {
    int pid;
    int tid;
    syscalls_t probe;
    span_t span;
    unsigned long ktime_ns;
    char comm[TASK_COMM_LEN];
};

#endif
