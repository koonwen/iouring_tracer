PROJECT_ROOT=..

run: trace_uring.bpf.o
	dune build .
	sudo $(PROJECT_ROOT)/_build/default/src/trace.exe

vmlinux.h:
	sudo bpftool btf dump file /sys/kernel/btf/vmlinux format c > vmlinux.h
