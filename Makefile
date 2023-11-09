IOU=_build/default/bin/iou.exe
SLEEPER=_build/default/test/eio_sleep.exe

iou:
	dune build
	sudo $(IOU) $(SLEEPER)

test_k:
	dune build
	sudo _build/default/test/eio_kprobes.exe

switch:
	opam switch create .
