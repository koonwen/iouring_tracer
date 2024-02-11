WORKSPACE_ROOT=..
TEST_DIR=$(WORKSPACE_ROOT)/_build/default/test
BIN_DIR=$(WORKSPACE_ROOT)/_build/default/bin
READ_ASYNC=$(TEST_DIR)/read_async.exe
OBPF=$(BIN_DIR)/obpf.exe

build:
	dune build

test: build
	sudo $(OBPF) trace $(READ_ASYNC)
