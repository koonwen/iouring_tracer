WORKSPACE_ROOT=../..
OBPF=$(WORKSPACE_ROOT)/_build/default/bin/obpf.exe
TEST_PROG=$(WORKSPACE_ROOT)/_build/default/test/driver/test_prog_err.exe

test:
	dune build $(WORKSPACE_ROOT)
	sudo $(OBPF) ---p=invalid.bt $(TEST_PROG)
	sudo $(WORKSPACE_ROOT)/_build/default/test/driver/test_prog_err.exe
