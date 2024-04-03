WORKSPACE_ROOT=..
TEST_DIR=$(WORKSPACE_ROOT)/_build/default/test
BIN_DIR=$(WORKSPACE_ROOT)/_build/default/bin
READ_ASYNC=$(TEST_DIR)/test_read_async.exe
OBPF=$(BIN_DIR)/obpf.exe

build:
	dune build ./test_read_async.exe

sample.txt:
	fallocate -l 1G $@

test: build sample.txt
	sudo $(OBPF) trace -vv "$(READ_ASYNC) sample.txt sample.txt sample.txt"

async_read: build sample.txt
	sudo $(READ_ASYNC) sample.txt sample.txt sample.txt
