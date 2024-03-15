OBPF=_build/default/bin/obpf.exe
PROG_BINARY=_build/default/test/test_eio.exe
TRACEPOINT_GEN=_build/default/lib/bpftrace/bt/tracepoints_gen.bt
SUDO=sudo env "PATH=$(PATH)"

build:
	eval $(opam env)
	$(SUDO) dune build

gen: build
	$(SUDO) dune exec -- ./lib/bpftrace/gen.exe _build/default/lib/bpftrace/bt/tracepoints.spec bpfgen.bt
	cat bpfgen.bt

test_trace:
	$(SUDO) dune exec -- obpf trace $(PROG_BINARY)

test_gen_trace_eio:
	$(SUDO) dune exec -- obpf trace -p$(TRACEPOINT_GEN) $(PROG_BINARY)

clean:
	$(SUDO) dune clean
	rm -rfv *.events

switch:
	opam switch create . -y
	opam install . --depext-only
	eval $(opam env)
