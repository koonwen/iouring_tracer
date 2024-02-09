SHELL := /bin/bash
CC = gcc
CCFLAGS = -Wall
LIBS = -luring

all: run_async run_seq

run_async: read_async.bin sample.txt
	time ./read_async.bin sample.txt sample.txt sample.txt sample.txt sample.txt

read_async.bin : read_async.c
	$(CC) $(CCFLAGS) $^ -o $@ $(LIBS)

run_seq: read_seq.bin sample.txt
	time ./read_seq.bin sample.txt sample.txt sample.txt sample.txt sample.txt

read_seq.bin: read_seq.c
	$(CC) $(CCFLAGS) $^ -o $@

sample.txt:
	head -c 1G /dev/urandom > $@

clean:
	rm -rfv *.bin *.o
