BUILD_DIR=../_build/default
SUDO=sudo env "PATH=$(PATH)"

interactive:
	$(SUDO) dune exec -- ../test/test_interactive.exe

trace:
	dune build ../test/test_hook.exe
	$(SUDO) olly trace --format=json iouring.trace '$(BUILD_DIR)/test/test_hook.exe'

run:
	dune build ../test/test_hook.exe
	sudo $(BUILD_DIR)/test/test_hook.exe

test_prog:
	make -C ../test async_read
