OBPF=_build/default/bin/obpf.exe
SLEEPER=_build/default/test/eio_sleep.exe

iou:
	dune build
	sudo $(OBPF) $(SLEEPER)

test_k:
	dune build
	sudo _build/default/test/eio_kprobes.exe

switch:
	opam switch create . -y
