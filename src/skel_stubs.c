#include <caml/alloc.h>
#include <caml/custom.h>
#include <caml/memory.h>
#include <caml/mlvalues.h>
#include <uring.skel.h>

/* Create an OCaml value encapsulating the pointer p */
static value val_of_uring_bpf_ptr(struct uring_bpf *p) {
  value v = caml_alloc(1, Abstract_tag);
  *((struct uring_bpf **)Data_abstract_val(v)) = p;
  return v;
}

/* Extract the pointer encapsulated in the given OCaml value */
static struct uring_bpf *uring_bpf_ptr_of_val(value v) {
  return *((struct uring_bpf **)Data_abstract_val(v));
}

CAMLprim value caml_uring_bpf__open_and_load(value unit) {
  CAMLparam1(unit);
  struct uring_bpf *p = uring_bpf__open_and_load();
  /* Return an option */
  if (!p) {
    fprintf(stderr, "Failed to open and load BPF skeleton\n");
    return 1;
  }
  CAMLreturn(val_of_uring_bpf_ptr(p));
}

CAMLprim value caml_uring_bpf__destroy(value uring_bpf) {
  CAMLparam1(uring_bpf);
  uring_bpf__destroy(uring_bpf_ptr_of_val(uring_bpf));
  CAMLreturn(Val_unit);
}

CAMLprim value caml_uring_bpf__attach(value uring_bpf) {
  CAMLparam1(uring_bpf);
  int ret = uring_bpf__attach(uring_bpf_ptr_of_val(uring_bpf));
  CAMLreturn(Val_int(ret));
}

CAMLprim value caml_uring_bpf__get_rb(value uring_bpf) {
  CAMLparam1 (uring_bpf);
  struct uring_bpf *p = uring_bpf_ptr_of_val(uring_bpf);
  struct bpf_map *map = p->maps.rb;
  value v = caml_alloc(1, Abstract_tag);
  *((struct bpf_map **)Data_abstract_val(v)) = map;
  CAMLreturn (v);
}
