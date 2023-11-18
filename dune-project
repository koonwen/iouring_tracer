(lang dune 3.11)
(using dune_site 0.1)
(name obpftrace)

;(generate_opam_files true)

(source
 (github koonwen/iouring_tracer))

(maintainers "Koonwen")
(package
 (name obpftrace)
 (sites (share bpftrace_progs))
 (synopsis "Tracing library using bpftrace for IO-uring")
 (depends ocaml dune crunch eio_linux))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/dune-files.html#dune-project
