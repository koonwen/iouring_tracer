(lang dune 3.13)

(name bpf_uring_trace)

(generate_opam_files true)

(source
 (github koonwen/iouring_tracer))

(authors "Lee Koonwen")

(maintainers "Lee Koonwen")

(package
 (allow_empty)
 (name bpf_uring_trace)
 (synopsis "IO-uring tracing tool using eBPF probes")
 (depends ocaml dune ocaml_libbpf ctypes eio_linux))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/dune-files.html#dune-project
