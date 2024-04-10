BUILD_DIR=../_build/default
SUDO=sudo env "PATH=$(PATH)"

interactive:
	dune build -- ../test/test_interactive.exe
	$(SUDO) $(BUILD_DIR)/test/test_interactive.exe

interactive_test:
	make -C ../test async_read

olly_test:
	make -C ../test olly

clean:
	dune clean
	rm -v *.events
