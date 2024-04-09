#include "caml/callback.h"
#include "caml/mlvalues.h"
#include "caml/threads.h"
#include "trace_uring.h"
#include <time.h>

/* This happens often and is expensive, might want to buffer these calls */
void cb_write_ev(probe_t probe, int probe_id, span_t span) {

  /* Threads must hold the runtime lock when writing to shared
   * memory */
  caml_acquire_runtime_system();
  static const value *write_ev_closure = NULL;
  if (write_ev_closure == NULL)
    write_ev_closure = caml_named_value("write_ev");
  caml_callback3(*write_ev_closure, Val_int(probe), Val_int(probe_id), Val_int(span));
  caml_release_runtime_system();
  return;
}

int handle_event(void *ctx, void *data, size_t data_sz) {
  const struct event *e = data;

  cb_write_ev(e->probe, e->probe_id, e->span);

  return 0;
}

CAMLprim value caml_ml_bpf_uring_trace(void) {
  CAMLparam0();

  /* release the lock so that this can run start running in parallel */
  caml_release_runtime_system();

  run(handle_event);

  CAMLreturn(Val_unit);
}
