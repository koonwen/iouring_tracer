SHELL := /bin/bash
CC = gcc
CCFLAGS = -Wall
LIBS = -luring
WORKSPACE_ROOT=..
BIN_DIR=$(WORKSPACE_ROOT)/_build/default/bin
OBPF=$(BIN_DIR)/obpf.exe

time: time_async time_seq

trace :
	dune build ..
	sudo ../_build/default/bin/obpf.exe trace -vv "./read_async.bin sample.txt sample.txt sample.txt"

time_async: read_async.bin sample.txt
	time ./read_async.bin sample.txt sample.txt sample.txt

read_async.bin : read_async.c
	$(CC) $(CCFLAGS) $^ -o $@ $(LIBS)

time_seq: read_seq.bin sample.txt
	time ./read_seq.bin sample.txt sample.txt sample.txt

read_seq.bin: read_seq.c
	$(CC) $(CCFLAGS) $^ -o $@

sample.txt:
	fallocate -l 1G $@

clean:
	rm -rfv *.bin *.o
