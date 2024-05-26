PROJECT_ROOT=..

rings: uring.bpf.o
	dune build ./trace_rings.exe
	sudo $(PROJECT_ROOT)/_build/default/src/trace_rings.exe
