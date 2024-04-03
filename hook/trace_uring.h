#line 1 "hook/bpf_uring_events/src/trace_uring.h"
int handle_event(void *ctx, void *data, size_t data_sz);
int run(int (*handle_event)(void*, void*, size_t));
