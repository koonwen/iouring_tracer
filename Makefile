OBPF=_build/default/bin/obpf.exe
PROG_BINARY=_build/default/test/test_binary.exe

test_obpf:
	dune build
	sudo $(OBPF) $(PROG_BINARY)

test_k:
	dune build
	sudo _build/default/test/eio_kprobes.exe

test_t:
	dune build
	sudo _build/default/test/eio_tracepoints.exe

switch:
	opam switch create . -y
