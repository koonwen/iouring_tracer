OBPF=_build/default/bin/obpf.exe
PROG_BINARY=_build/default/test/test_eio.exe
SUDO=sudo env "PATH=$(PATH)"

build:
	eval $(opam env)
	$(SUDO) dune build

gen: build
	$(SUDO) dune exec -- ./lib/bpftrace/test.exe _build/default/lib/bpftrace/bt/tracepoints.spec

test_trace:
	$(SUDO) dune exec -- obpf trace $(PROG_BINARY)

clean:
	$(SUDO) dune clean

switch:
	opam switch create . -y
	opam install . --depext-only
	eval $(opam env)
