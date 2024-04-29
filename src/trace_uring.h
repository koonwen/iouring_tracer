/* SPDX-License-Identifier: (LGPL-2.1 OR BSD-2-Clause) */
/* Copyright (c) 2020 Andrii Nakryiko, 2024 Koonwen Lee */

#ifndef __TRACE_URING_H
#define __TRACE_URING_H
#include <stddef.h>

int run(int (*handle_event)(void*, void*, size_t));

typedef enum {
  IO_URING_COMPLETE,
  IO_URING_CQE_OVERFLOW,
  IO_URING_CQRING_WAIT,
  IO_URING_CREATE,
  IO_URING_DEFER,
  IO_URING_FAIL_LINK,
  IO_URING_FILE_GET,
  IO_URING_LINK,
  IO_URING_LOCAL_WORK_RUN,
  IO_URING_POLL_ARM,
  IO_URING_QUEUE_ASYNC_WORK,
  IO_URING_REGISTER,
  IO_URING_REQ_FAILED,
  IO_URING_SHORT_WRITE,
  IO_URING_SUBMIT_SQE,
  IO_URING_TASK_ADD,
  IO_URING_TASK_WORK_RUN
} tracepoint_t;

typedef enum {
  SYS_IO_URING_SETUP,
  SYS_IO_URING_REGISTER,
  SYS_IO_URING_ENTER,
} syscalls_t;

typedef enum {
  TRACEPOINT,
  SYSCALLS,
} probe_t;

typedef enum {
    BEGIN,
    END
} span_t;

struct trace_entry {
  short unsigned int type;
  unsigned char flags;
  unsigned char preempt_count;
  int pid;
};

struct trace_event_io_uring_complete {
  struct trace_entry ent;
  void *ctx;
  void *req;
  long user_data;
  int res;
  unsigned cflags;
  long extra1;
  long extra2;
};

struct trace_event_io_uring_cqe_overflow {
  struct trace_entry ent;
  void *ctx;
  unsigned long long user_data;
  int res;
  unsigned int cflags;
  void *ocqe;
};

struct trace_event_io_uring_cqring_wait {
  struct trace_entry ent;
  void *ctx;
  int main_events;
};

struct trace_event_io_uring_create {
  struct trace_entry ent;
  int fd;
  void *ctx;
  unsigned int sq_entries;
  unsigned int cq_entries;
  unsigned int flags;
};
/* print fmt: "ring %p, fd %d sq size %d, cq size %d, flags 0x%x", REC->ctx,
 * REC->fd, REC->sq_entries, REC->cq_entries, REC->flags */

struct trace_event_io_uring_defer {
  struct trace_entry ent;
  void *ctx;
  void *req;
  unsigned long long data;
  unsigned char opcode;
  char *opstr;
};

struct trace_event_io_uring_fail_link {
  struct trace_entry ent;
  void *ctx;
  void *req;
  unsigned long long user_data;
  unsigned char opcode;
  void *link;
  char *op_str;
};

struct trace_event_io_uring_file_get {
  struct trace_entry ent;
  void *ctx;
  void *req;
  unsigned long user_data;
  int fd;
};

struct trace_event_io_uring_link {
  struct trace_entry ent;
  void *ctx;
  void *req;
  void *target_req;
};

struct trace_event_io_uring_local_work_run {
  struct trace_entry ent;
  void *ctx;
  int count;
  unsigned int loops;
};

struct trace_event_io_uring_poll_arm {
  struct trace_entry ent;
  void *ctx;
  void *req;
  unsigned long long user_data;
  unsigned char opcode;
  int mask;
  int events;
  char *op_str;
};

struct trace_event_io_uring_queue_async_work {
  struct trace_entry ent;
  void *ctx;
  void *req;
  unsigned long user_data;
  unsigned char opcode;
  unsigned int flags;
  /* struct io_wq_work *work; */
  int rw;
  char *op_str;
};

struct trace_event_io_uring_register {
  struct trace_entry ent;
  void *ctx;
  unsigned int opcode;
  unsigned int nr_files;
  unsigned nr_bufs;
  long ret;
};

struct trace_event_io_uring_req_failed {
  struct trace_entry ent;
  void *ctx;
  void *req;
  unsigned long long user_data;
  unsigned char opcode;
  unsigned char flags;
  unsigned char ioprio;
  unsigned long off;
  unsigned long addr;
  unsigned int len;
  unsigned int op_flags;
  unsigned short buf_index;
  unsigned short personality;
  unsigned int file_index;
  unsigned long pad1;
  unsigned long addr3;
  int error;
  char *op_str;
};

struct trace_event_io_uring_short_write {
  struct trace_entry ent;
  void *ctx;
  unsigned long fpos;
  unsigned long wanted;
  unsigned long got;
};

struct trace_event_io_uring_submit_sqe {
  struct trace_entry ent;
  void *ctx;
  void *req;
  unsigned long long user_data;
  unsigned char opcode;
  unsigned int flags;
  char force_nonblock;
  char sq_thread;
  char *op_str;
};

struct trace_event_io_uring_task_add {
  struct trace_entry ent;
  void *ctx;
  void *req;
  unsigned long long user_data;
  unsigned short opcode;
  int mask;
  char *op_str;
};

struct trace_event_io_uring_task_work_run {
  struct trace_entry ent;
  void *tctx;
  unsigned int count;
  unsigned int loops;
};

#define TASK_COMM_LEN 16
/* definition of a sample sent to user-space from BPF program */
struct event {
  int pid;
  probe_t probe;
  int probe_id;
  span_t span;
  long ktime_ns;
  char comm[TASK_COMM_LEN];
};

#endif
