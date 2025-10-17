# Makefile for rest-gen.nvim

.PHONY: test deps clean

# Define a local directory for lazy.nvim to use during tests
LAZY_DIR := $(CURDIR)/.lazy

# This target removes the local lazy directory, ensuring a clean slate.
clean:
	@echo "Cleaning up testing dependencies..."
	@rm -rf $(LAZY_DIR)

# This target ensures all plugin dependencies are installed using lazy.nvim.
# It now uses the local LAZY_DIR for isolation.
deps:
	@echo "Installing testing dependencies..."
	@nvim --headless -u tests/minimal_init.lua -c "Lazy sync --path $(LAZY_DIR)" -c "qa"

# This command runs all tests.
# It now depends on the `deps` target to ensure dependencies are installed first.
test: deps
	@echo "Running tests..."
	@nvim -l tests/minimal_init.lua --minitest
