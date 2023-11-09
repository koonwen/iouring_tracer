(lang dune 3.11)
(using dune_site 0.1)
(name iouring_tracer)

;(generate_opam_files true)

(source
 (github koonwen/iouring_tracer))

(maintainers "Koonwen")
(package
 (name iouring_tracer)
 (sites (share bpftrace_progs))
 (synopsis "Tracing tool using ebpf programs for IO-uring")
 (depends ocaml dune crunch eio_linux))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/dune-files.html#dune-project
