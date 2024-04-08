#include "caml/callback.h"
#include "caml/mlvalues.h"
#include "caml/threads.h"
#include "trace_uring.h"
#include <time.h>

/* This happens often and is expensive, might want to buffer these calls */
void cb_write_ev(tracepoint_t i) {

  /* Threads must hold the runtime lock when writing to shared
   * memory */
  caml_acquire_runtime_system();
  static const value *write_ev_closure = NULL;
  if (write_ev_closure == NULL)
    write_ev_closure = caml_named_value("write_ev");
  caml_callback(*write_ev_closure, Val_int(i));
  caml_release_runtime_system();
  return;
}

int handle_event(void *ctx, void *data, size_t data_sz) {
  const struct event *e = data;

  cb_write_ev(e->tracepoint);

  return 0;
}

CAMLprim value caml_ml_bpf_uring_trace(void) {
  CAMLparam0();

  /* release the lock so that this can run start running in parallel */
  caml_release_runtime_system();

  run(handle_event);

  CAMLreturn(Val_unit);
}
