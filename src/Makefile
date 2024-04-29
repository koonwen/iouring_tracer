PROJECT_ROOT=..

run: trace_uring_primative.bpf.o
	dune build .
	sudo $(PROJECT_ROOT)/_build/default/src/trace.exe
