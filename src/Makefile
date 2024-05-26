PROJECT_ROOT=..

rings: uring.bpf.o
	dune build ./trace_uring.exe
	sudo $(PROJECT_ROOT)/_build/default/src/trace_uring.exe
