BUILD_DIR=../../_build/default
TEST_DIR=$(BUILD_DIR)/test/olly
SUDO=sudo env "PATH=$(PATH)"

SOURCES= test_eio_1.ml
build: $(SOURCES)
	dune build .

test_eio_1: build
	$(SUDO) olly trace test_eio_1.trace $(TEST_DIR)/test_eio_1.exe

clean:
	sudo rm -vi *.trace *.data
