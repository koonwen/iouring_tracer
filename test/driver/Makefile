WORKSPACE_ROOT=../..
OBPF=$(WORKSPACE_ROOT)/_opam/bin/obpf
TEST_PROG=$(WORKSPACE_ROOT)/_build/default/test/driver/test_prog_err.exe

test:
	sudo $(OBPF) trace -pinvalid.bt $(TEST_PROG)
