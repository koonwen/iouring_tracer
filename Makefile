OBPF=_build/default/bin/obpf.exe
PROG_BINARY=_build/default/test/test_eio.exe
SUDO=sudo env "PATH=$(PATH)"

build:
	eval $(opam env)
	$(SUDO) dune build

test_obpf:
	$(SUDO) dune exec -- obpf trace $(PROG_BINARY)

switch:
	opam switch create . -y
	opam install . --depext-only
	eval $(opam env)
