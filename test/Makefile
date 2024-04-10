WORKSPACE_ROOT=..
TEST_DIR=$(WORKSPACE_ROOT)/_build/default/test
BIN_DIR=$(WORKSPACE_ROOT)/_build/default/bin
READ_ASYNC=$(TEST_DIR)/test_read_async.exe
OBPF=$(BIN_DIR)/obpf.exe
SUDO=sudo env "PATH=$(PATH)"

build:
	dune build .

sample.txt:
	fallocate -l 1G $@

test: build sample.txt
	sudo $(OBPF) trace -vv "$(READ_ASYNC) sample.txt sample.txt sample.txt"

async_read: build sample.txt
	sudo $(READ_ASYNC) sample.txt sample.txt sample.txt

olly: build
	$(SUDO) olly trace iouring.trace "$(TEST_DIR)/test_hook.exe"
