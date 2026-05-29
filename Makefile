ROOT_DIR := $(CURDIR)
INCLUDE_DIR := $(ROOT_DIR)/include
SHIM_DIR := $(INCLUDE_DIR)/shims/win32
MACOS_SHIM_DIR := $(INCLUDE_DIR)/shims/macos
WIN32_DIR := $(INCLUDE_DIR)/win32

CC ?= clang
CXX ?= clang++
CFLAGS ?= -Wall -Wextra -Wno-ignored-attributes
ZIG_VERSION ?= 0.16.0
ZIG_LIB := zig-out/lib/librosetta3_zig.a

# Entitlements for codesigning (JIT, unsigned-executable-memory, etc.)
ENTITLEMENTS := rosetta3.entitlements
CODESIGN_IDENTITY ?= -

# On macOS, prepend the LLP64 override shim so it wins the include lookup
# for "win32/windows_base.h" over the upstream-mirrored shim/canonical.
ifeq ($(shell uname -s),Darwin)
MACOS_SHIM_INC := -Iinclude/shims/macos
else
MACOS_SHIM_INC :=
endif
# Reference header path (the canonical win32 headers mirrored upstream)
REFERENCE_INC := -I.rosetta3/include
SHIM_INC := -Iinclude/shims/win32 $(REFERENCE_INC)
INCLUDE_INC := -Iinclude
export MACOS_SHIM_INC

# ---------------------------------------------------------------------------
# Objective-C window library
# ---------------------------------------------------------------------------
OBJC_SRC := src/graphics/Objective_C/window_main.m
OBJC_LIB := librosetta_window.a
OBJC_OBJ := window_main.o
OBJC_FLAGS := -fobjc-arc -fmodules
OBJC_FRAMEWORKS := -framework Cocoa -framework Foundation

.PHONY: all help check clean zig-build run prodder prodder-all prodder-build window-lib snake-window

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
		'  make window-lib   Build native Cocoa console-emulation window library' \
		'  make snake-window Build snake game with native Cocoa window' \
		'  make clean        Remove build artifacts'

# Include per-folder make fragments when present
-include include/shims/win32/shim.mk
-include include/win32/Zig/zig.mk
-include test/test.mk
# Reference-only win32 header checks (requires .rosetta3/include/win32)
ifneq ($(wildcard .rosetta3/include/win32/win32.mk),)
-include .rosetta3/include/win32/win32.mk
endif

# Aggregate targets that call included fragments
.PHONY: headers-check
headers-check: shim-check-all
ifneq ($(wildcard .rosetta3/include/win32/win32.mk),)
headers-check: win32-check-all
endif

.PHONY: zig-build
zig-build: zig-build-all

check:
	@tmp="$$(mktemp /tmp/rosetta3.XXXXXX.c)"; \
	trap 'rm -f "$$tmp"' EXIT INT TERM; \
	printf '%s\n' '#include "win32/windows_base.h"' 'int main(void) { return 0; }' > "$$tmp"; \
	"$(CC)" $(CFLAGS) -fsyntax-only $(MACOS_SHIM_INC) $(SHIM_INC) $(INCLUDE_INC) "$$tmp"


clean:
	rm -f test_main lib*.dylib lib*.so $(OBJC_OBJ) $(OBJC_LIB)
	rm -rf zig-out
	rm -f snake_game

# ---------------------------------------------------------------------------
# Codesigning — required for JIT and unsigned-executable-memory entitlements
# ---------------------------------------------------------------------------
.PHONY: codesign
codesign:
	@if [ -d zig-out ]; then \
		echo "Codesigning zig-out artifacts with $(ENTITLEMENTS)..."; \
		find zig-out -type f \( -name '*.dylib' -o -name '*.so' -o -name '*.a' \) -exec codesign --entitlements "$(ENTITLEMENTS)" --force -s "$(CODESIGN_IDENTITY)" {} \; 2>/dev/null || echo "  (codesign skipped or not applicable)"; \
	else \
		echo "No zig-out directory found; run 'make zig-lib' first."; \
	fi
	@if [ -f "$(ZIG_LIB)" ]; then \
		codesign --entitlements "$(ENTITLEMENTS)" --force -s "$(CODESIGN_IDENTITY)" "$(ZIG_LIB)" 2>/dev/null || true; \
	fi

# ---------------------------------------------------------------------------
# Objective-C window library — native Cocoa console-emulation window
# ---------------------------------------------------------------------------
.PHONY: window-lib
window-lib: $(OBJC_LIB)

$(OBJC_OBJ): $(OBJC_SRC)
	@"$(CC)" $(OBJC_FLAGS) $(MACOS_SHIM_INC) $(SHIM_INC) $(INCLUDE_INC) \
		-c "$<" -o "$@" 2>&1

$(OBJC_LIB): $(OBJC_OBJ)
	@ar rcs "$@" "$<"
	@echo "Built $(OBJC_LIB)"

# ---------------------------------------------------------------------------
# Snake game with native Cocoa window (demo)
# ---------------------------------------------------------------------------
# The ObjC++ wrapper (window_main.mm) #include-s snake.c after redirecting
# its console I/O to the Cocoa window library.
SNAKE_WRAPPER := app_testing/basic_snake/window_main.mm
SNAKE_BIN := snake_game

snake-window: $(ZIG_LIB) $(OBJC_LIB)
	@"$(CXX)" -std=c++11 \
		$(MACOS_SHIM_INC) $(SHIM_INC) $(INCLUDE_INC) \
		-c "$(SNAKE_WRAPPER)" -o $(SNAKE_BIN).o 2>&1
	@"$(CXX)" $(SNAKE_BIN).o $(OBJC_LIB) $(ZIG_LIB) \
		$(OBJC_FRAMEWORKS) -o "$(SNAKE_BIN)" 2>&1
	@echo "Built $(SNAKE_BIN) — run with ./$(SNAKE_BIN)"
	@rm -f $(SNAKE_BIN).o

.PHONY: run
run: test-run-all

# ---------------------------------------------------------------------------
# Test Prodder — interactive and non-interactive suite selector
# ---------------------------------------------------------------------------

prodder-build:
	@"$(CC)" $(CFLAGS) -o tools/test_prodder tools/test_prodder.c

# Interactive menu: make prodder
# Run a specific suite: make prodder SUITE=win32
prodder: window-lib
	@$(MAKE) prodder-build
	@if [ -n "$(SUITE)" ]; then \
		./tools/test_prodder --suite "$(SUITE)"; \
	else \
		./tools/test_prodder; \
	fi

# Non-interactive: runs every suite (good for CI / make all)
prodder-all: window-lib
	@$(MAKE) prodder-build
	@./tools/test_prodder --all