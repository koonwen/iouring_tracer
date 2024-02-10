WORKSPACE_ROOT=../..
OBPF=$(WORKSPACE_ROOT)/_opam/bin/obpf
TEST_PROG_ERR=$(WORKSPACE_ROOT)/_build/default/test/driver/test_prog_err.exe
TEST_BT_ERR=$(WORKSPACE_ROOT)/_build/default/test/driver/test_bt_err.exe

test:
	dune build
	sudo $(OBPF) trace -pvalid.bt $(TEST_PROG_ERR)
	sudo $(OBPF) trace -pinvalid.bt $(TEST_BT_ERR)
