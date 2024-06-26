PROJECT_ROOT=..

.PHONY=build

build:
	dune build

rings: build uring.bpf.o
	sudo $(PROJECT_ROOT)/_build/default/src/trace_uring.exe
