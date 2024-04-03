#include "caml/callback.h"
#include "caml/mlvalues.h"
#include "caml/threads.h"
#include "trace_uring.h"
#include <stdio.h>

void hello(value cb);

CAMLprim value caml_ml_bpf_uring_trace(value cb) {
  CAMLparam1(cb);
  hello(cb);
  CAMLreturn(Val_unit);
}

void hello(value cb) {
    caml_release_runtime_system();

    run(handle_event);

    caml_acquire_runtime_system();

    caml_callback(cb, Val_unit);
}
