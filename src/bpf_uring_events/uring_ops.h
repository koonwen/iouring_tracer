#ifndef __URING_IO_H
#define __URING_IO_H

#include <stdbool.h>
#define TASK_COMM_LEN  16
#define MAX_OP_STR_LEN 127

enum tracepoint_t {
    IO_URING_SUBMIT_SQE,
    IO_URING_COMPLETE
};

struct io_uring_submit_sqe {
    void * req;
    unsigned char opcode;
    unsigned int flags;
    bool force_nonblock;
    bool sq_thread;
    char op_str[MAX_OP_STR_LEN];
};

struct io_uring_complete {
    void * req;
    int res;
    unsigned cflags;
};

struct event {
    enum tracepoint_t t;
    int pid;
    int tid;
    unsigned long long ts;
    char comm[TASK_COMM_LEN];
    union extra {
        struct io_uring_complete io_uring_complete;
        struct io_uring_submit_sqe io_uring_submit_sqe;
    } extra;
};

#endif
