ROOT_DIR := $(CURDIR)
INCLUDE_DIR := $(ROOT_DIR)/include
SHIM_DIR := $(INCLUDE_DIR)/shims/win32
MACOS_SHIM_DIR := $(INCLUDE_DIR)/shims/macos
WIN32_DIR := $(INCLUDE_DIR)/win32

CC ?= clang
CFLAGS ?= -Wall -Wextra -Wno-ignored-attributes
ZIG_VERSION ?= 0.16.0

# On macOS, prepend the LLP64 override shim so it wins the include lookup
# for "win32/windows_base.h" over the upstream-mirrored shim/canonical.
ifeq ($(shell uname -s),Darwin)
MACOS_SHIM_INC := -I"$(MACOS_SHIM_DIR)"
else
MACOS_SHIM_INC :=
endif
export MACOS_SHIM_INC

.PHONY: all help check clean zig-build run prodder prodder-all prodder-build

all: headers-check zig-build test-run

help:
	@printf '%s\n' \
		'Rosetta 3 make targets:' \
		'  make              Run headers, Zig, and test checks' \
		'  make headers-check  Run header checks' \
		'  make zig-build    Build Zig sources under include/win32/Zig' \
		'  make run          Build and run test/main.c' \
		'  make prodder      Launch interactive test selector' \
		'  make prodder-all  Run all suites non-interactively (CI)' \
		'  make clean        Remove build artifacts'

# Include per-folder make fragments when present
-include include/shims/win32/shim.mk
-include include/win32/win32.mk
-include include/win32/Zig/zig.mk
-include test/test.mk

# Aggregate targets that call included fragments
.PHONY: headers-check
headers-check: shim-check-all win32-check-all

.PHONY: zig-build
zig-build: zig-build-all

check:
	@tmp="$$(mktemp /tmp/rosetta3.XXXXXX.c)"; \
	trap 'rm -f "$$tmp"' EXIT INT TERM; \
	printf '%s\n' '#include "win32/windows_base.h"' '#include "win32/atomic.h"' 'int main(void) { return 0; }' > "$$tmp"; \
	"$(CC)" $(CFLAGS) -fsyntax-only $(MACOS_SHIM_INC) -I"$(SHIM_DIR)" -I"$(INCLUDE_DIR)" "$$tmp"


clean:
	rm -f test_main lib*.dylib lib*.so

.PHONY: run
run: test-run-all

# ---------------------------------------------------------------------------
# Test Prodder — interactive and non-interactive suite selector
# ---------------------------------------------------------------------------

prodder-build:
	@"$(CC)" $(CFLAGS) -o tools/test_prodder tools/test_prodder.c

# Interactive menu: make prodder
# Run a specific suite: make prodder SUITE=win32
prodder:
	@$(MAKE) prodder-build
	@if [ -n "$(SUITE)" ]; then \
		./tools/test_prodder --suite "$(SUITE)"; \
	else \
		./tools/test_prodder; \
	fi

# Non-interactive: runs every suite (good for CI / make all)
prodder-all:
	@$(MAKE) prodder-build
	@./tools/test_prodder --all