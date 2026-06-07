ROOT_DIR := $(CURDIR)
INCLUDE_DIR := $(ROOT_DIR)/include
SHIM_DIR := $(INCLUDE_DIR)/shims/win32
MACOS_SHIM_DIR := $(INCLUDE_DIR)/shims/macos
WIN32_DIR := $(INCLUDE_DIR)/win32

CC ?= clang
CXX ?= clang++
CFLAGS ?= -Wall -Wextra -Wno-ignored-attributes
ZIG_VERSION ?= 0.16.0
ZIG_LIB := zig-out/lib/librosette_zig.a
EXE_RUNNER_SRC := rosette_exe_runner.zig
EXE_RUNNER_BIN := zig-out/bin/rosette_exe_runner
APP_EXE_BUILDER_SRC := rosette_app_exe.zig
APP_EXE_BUILDER_BIN := zig-out/bin/rosette_app_exe
EXE ?= assets/exe_examples/Notepad.exe
EXE_LOG ?= assets/exe_examples/$(basename $(notdir $(EXE))).trace.log
APP_SUITE ?= basic_snake
APP_HOST_BIN ?= app_testing/$(APP_SUITE)/$(APP_SUITE).host
APP_EXE ?= assets/exe_examples/$(APP_SUITE).exe
APP_TRACE ?= assets/exe_examples/$(APP_SUITE).trace.log

# Entitlements for codesigning (JIT, unsigned-executable-memory, etc.)
ENTITLEMENTS := build/rosette.entitlements
CODESIGN_IDENTITY ?= -

# On macOS, prepend the LLP64 override shim so it wins the include lookup
# for "win32/windows_base.h" over the upstream-mirrored shim/canonical.
ifeq ($(shell uname -s),Darwin)
MACOS_SHIM_INC := -Iinclude/shims/macos
else
MACOS_SHIM_INC :=
endif
# Reference header path (the canonical win32 headers mirrored upstream)
REFERENCE_INC := -I.rosette/include
SHIM_INC := -Iinclude/shims/win32 $(REFERENCE_INC)
INCLUDE_INC := -Iinclude
export MACOS_SHIM_INC

# ---------------------------------------------------------------------------
# Objective-C / C++ window library and CLI bridge library
# ---------------------------------------------------------------------------
OBJC_SRC      := src/graphics/Objective_C/window_main.m
OBJC_GDI_SRC  := src/graphics/Objective_C/window_gdi.m
OBJCXX_SRC    := src/graphics/Objective_C/cout_bridge.cpp
DEFAULT_SRC    := src/graphics/Objective_C/default_main.cpp
CLI_C_SRC      := src/graphics/CLI/window_main.c
EXT_WIN_SRC   := src/graphics/CLI/extern_window.m
DEBUG_RUNTIME_SRC := src/graphics/common/debug_runtime.c
KEYBOARD_SRC := src/graphics/common/keyboard/rosette_keyboard.m
FB_LOGGER_SRC := src/graphics/fb-logger/fb_logger.m
OBJC_LIB      := librosette_window.a
CLI_LIB       := librosette_cli.a
OBJC_OBJ      := window_main.m.o
OBJC_GDI_OBJ  := window_gdi.o
OBJCXX_OBJ    := cout_bridge.o
DEFAULT_OBJ    := default_main.o
CLI_OBJ       := window_main.cli.o
EXT_WIN_OBJ   := extern_window.o
DEBUG_RUNTIME_OBJ := debug_runtime.o
KEYBOARD_OBJ := rosette_keyboard.o
FB_LOGGER_OBJ := fb_logger.o
OBJC_FLAGS := -fobjc-arc -fmodules
OBJC_FRAMEWORKS := -framework Cocoa -framework Foundation

.PHONY: all help check clean zig-build run prodder prodder-all prodder-build window-lib cli-lib snake-window exe-list exe-runner-build exe-run exe-export app-exe-builder-build app-suite-binary app-exe app-exe-run app-exe-parse app-wrapper installer uninstaller app-all

all: headers-check zig-build test-run

help:
	@printf '%s\n' \
		'Rosette make targets:' \
		'  make              Run headers, Zig, and test checks' \
		'  make headers-check  Run header checks' \
		'  make zig-build    Build Zig sources under include/win32/Zig' \
		'  make run          Build and run test/main.c' \
		'  make prodder      Launch interactive test selector' \
		'  make prodder-all  Run all suites non-interactively (CI)' \
		'  make exe-list     List .exe files available under assets/exe_examples/' \
		'  make exe-run EXE=assets/exe_examples/Notepad.exe  Parse/log one .exe intake session' \
		'  make exe-export SRC_EXE=/path/to/file.exe [OUT_EXE=assets/exe_examples/Game.exe]' \
		'  make app-exe APP_SUITE=basic_snake      Build a Rosette .exe wrapper for one app_testing suite' \
		'  make app-exe-parse APP_SUITE=basic_snake Build and parse one app_testing suite wrapper without launching it' \
		'  make app-exe-run APP_SUITE=basic_snake  Build, parse, and launch one app_testing suite via .exe intake' \
		'  make cli-lib     Build native CLI bridge library (librosette_cli.a)' \
		'  make window-lib  Build native Cocoa console-emulation window library (librosette_window.a)' \
		'  make snake-window Build snake game with native Cocoa window' \
		'  make clean        Remove build artifacts'

# Include per-folder make fragments when present
-include include/shims/win32/shim.mk
-include include/win32/Zig/zig.mk
-include test/test.mk
# Reference-only win32 header checks (requires .rosette/include/win32)
ifneq ($(wildcard .rosette/include/win32/win32.mk),)
-include .rosette/include/win32/win32.mk
endif

# Aggregate targets that call included fragments
.PHONY: headers-check
headers-check: shim-check-all
ifneq ($(wildcard .rosette/include/win32/win32.mk),)
headers-check: win32-check-all
endif

.PHONY: zig-build
zig-build: zig-build-all

check:
	@tmp="$$(mktemp /tmp/rosette.XXXXXX.c)"; \
	trap 'rm -f "$$tmp"' EXIT INT TERM; \
	printf '%s\n' '#include "win32/windows_base.h"' 'int main(void) { return 0; }' > "$$tmp"; \
	"$(CC)" $(CFLAGS) -fsyntax-only $(MACOS_SHIM_INC) $(SHIM_INC) $(INCLUDE_INC) "$$tmp"


clean:
	rm -f test_main lib*.dylib lib*.so $(OBJC_OBJ) $(OBJCXX_OBJ) $(DEFAULT_OBJ) $(EXT_WIN_OBJ) $(CLI_OBJ) $(OBJC_LIB) $(CLI_LIB)
	rm -rf zig-out
	rm -f snake_game app_testing/basic_snake/snake_game

# ---------------------------------------------------------------------------
# Rosette macOS .app bundle, DMG installer, and system uninstaller
# Outputs land in program/ tree at the project root.
# ---------------------------------------------------------------------------
.PHONY: app-wrapper
app-wrapper:
	@mkdir -p program/app
	@echo "Building Rosette.app bundle..."
	@zig build bundle --build-file app/bundling/build.zig --cache-dir build/.zig-cache --global-cache-dir build/.zig-cache/global 2>&1
	@rm -rf program/app/Rosette.app
	@cp -R app/bundling/zig-out/Rosette.app program/app/
	@echo "Created: program/app/Rosette.app"

.PHONY: installer
installer: app-wrapper
	@mkdir -p program/installer
	@echo "Building Rosette Installer.app..."
	@zig build bundle --build-file app/dmg/installer/build.zig --cache-dir build/.zig-cache --global-cache-dir build/.zig-cache/global -Dpayload-app=program/app/Rosette.app 2>&1
	@rm -rf /tmp/rosette-installer-dmg
	@mkdir -p /tmp/rosette-installer-dmg
	@cp -R "app/dmg/installer/zig-out/Rosette Installer.app" /tmp/rosette-installer-dmg/
	@echo "Building Rosette DMG installer..."
	@rm -f program/installer/RosetteInstaller.dmg
	@hdiutil create -srcfolder /tmp/rosette-installer-dmg \
		-volname "Rosette Installer" \
		-fs HFS+ -format UDZO \
		-o program/installer/RosetteInstaller.dmg 2>&1
	@rm -rf /tmp/rosette-installer-dmg
	@echo "Created: program/installer/RosetteInstaller.dmg"

.PHONY: uninstaller
uninstaller:
	@mkdir -p program/uninstaller
	@echo "Building Rosette Uninstaller.app..."
	@zig build bundle --build-file app/dmg/uninstaller/build.zig --cache-dir build/.zig-cache --global-cache-dir build/.zig-cache/global 2>&1
	@rm -rf /tmp/rosette-uninstaller-dmg
	@mkdir -p /tmp/rosette-uninstaller-dmg
	@cp -R "app/dmg/uninstaller/zig-out/Rosette Uninstaller.app" /tmp/rosette-uninstaller-dmg/
	@rm -f program/uninstaller/RosetteUninstaller.dmg
	@hdiutil create -srcfolder /tmp/rosette-uninstaller-dmg \
		-volname "Rosette Uninstaller" \
		-fs HFS+ -format UDZO \
		-o program/uninstaller/RosetteUninstaller.dmg 2>&1
	@rm -rf /tmp/rosette-uninstaller-dmg
	@echo "Created: program/uninstaller/RosetteUninstaller.dmg"

app-all: app-wrapper installer uninstaller
	@echo "All Rosette app artifacts built."

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
.PHONY: window-lib cli-lib
window-lib: $(OBJC_LIB)
cli-lib: $(CLI_LIB)

$(OBJC_OBJ): $(OBJC_SRC)
	@"$(CC)" $(OBJC_FLAGS) $(MACOS_SHIM_INC) $(SHIM_INC) $(INCLUDE_INC) \
		-c "$<" -o "$@" 2>&1

$(OBJC_GDI_OBJ): $(OBJC_GDI_SRC)
	@"$(CC)" $(OBJC_FLAGS) $(MACOS_SHIM_INC) $(SHIM_INC) $(INCLUDE_INC) \
		-c "$<" -o "$@" 2>&1

$(OBJCXX_OBJ): $(OBJCXX_SRC)
	@"$(CXX)" -std=c++11 $(MACOS_SHIM_INC) $(SHIM_INC) $(INCLUDE_INC) \
		-c "$<" -o "$@" 2>&1

$(DEFAULT_OBJ): $(DEFAULT_SRC)
	@"$(CXX)" -std=c++11 $(MACOS_SHIM_INC) $(SHIM_INC) $(INCLUDE_INC) \
		-c "$<" -o "$@" 2>&1

$(EXT_WIN_OBJ): $(EXT_WIN_SRC)
	@"$(CC)" -fobjc-arc $(MACOS_SHIM_INC) $(SHIM_INC) $(INCLUDE_INC) \
		-c "$<" -o "$@" 2>&1

$(FB_LOGGER_OBJ): $(FB_LOGGER_SRC)
	@"$(CC)" -fobjc-arc $(MACOS_SHIM_INC) $(SHIM_INC) $(INCLUDE_INC) \
		-c "$<" -o "$@" 2>&1

$(CLI_OBJ): $(CLI_C_SRC)
	@"$(CC)" -std=c11 $(MACOS_SHIM_INC) $(SHIM_INC) $(INCLUDE_INC) \
		-c "$<" -o "$@" 2>&1

$(DEBUG_RUNTIME_OBJ): $(DEBUG_RUNTIME_SRC)
	@"$(CC)" -std=c11 $(MACOS_SHIM_INC) $(SHIM_INC) $(INCLUDE_INC) \
		-c "$<" -o "$@" 2>&1

$(KEYBOARD_OBJ): $(KEYBOARD_SRC)
	@"$(CC)" -fobjc-arc $(MACOS_SHIM_INC) $(SHIM_INC) $(INCLUDE_INC) \
		-c "$<" -o "$@" 2>&1

$(OBJC_LIB): $(OBJC_OBJ) $(OBJC_GDI_OBJ) $(OBJCXX_OBJ) $(EXT_WIN_OBJ) $(DEBUG_RUNTIME_OBJ) $(KEYBOARD_OBJ) $(FB_LOGGER_OBJ)
	@ar rcs "$@" $^
	@echo "Built $(OBJC_LIB)"

$(CLI_LIB): $(CLI_OBJ) $(DEBUG_RUNTIME_OBJ)
	@ar rcs "$@" $^
	@echo "Built $(CLI_LIB)"

# ---------------------------------------------------------------------------
# Snake game with native Cocoa window (demo)
# ---------------------------------------------------------------------------
# snake.cpp is compiled directly with -Dmain=rosette_game_main so the
# library's default_main.cpp provides the real main() entry point.
# The binary is placed in the game directory so it finds game.toml.
SNAKE_DIR := app_testing/basic_snake
SNAKE_BIN := snake_game
SNAKE_OUT := $(SNAKE_DIR)/$(SNAKE_BIN)

snake-window: $(ZIG_LIB) $(OBJC_LIB) $(DEFAULT_OBJ)
	@"$(CXX)" -std=c++11 \
		-DROSETTE_WINDOW_MODE -Dmain=rosette_game_main \
		$(MACOS_SHIM_INC) $(SHIM_INC) $(INCLUDE_INC) \
		-c "$(SNAKE_DIR)/snake.cpp" -o "$(SNAKE_DIR)/$(SNAKE_BIN).o" 2>&1
	@"$(CXX)" "$(SNAKE_DIR)/$(SNAKE_BIN).o" $(DEFAULT_OBJ) $(OBJC_LIB) $(ZIG_LIB) \
		$(OBJC_FRAMEWORKS) -o "$(SNAKE_OUT)" 2>&1
	@echo "Built $(SNAKE_OUT) — run with ./$(SNAKE_OUT)"
	@rm -f "$(SNAKE_DIR)/$(SNAKE_BIN).o"

.PHONY: run
run: test-run-all

# ---------------------------------------------------------------------------
# Test Prodder — interactive and non-interactive suite selector
# ---------------------------------------------------------------------------

prodder-build:
	@"$(CC)" $(CFLAGS) -o tools/test_prodder tools/test_prodder.c

# Interactive menu: make prodder
# Run a specific suite: make prodder SUITE=win32
prodder: window-lib cli-lib
	@$(MAKE) prodder-build
	@if [ -n "$(SUITE)" ]; then \
		./tools/test_prodder --suite "$(SUITE)"; \
	else \
		./tools/test_prodder; \
	fi

# Non-interactive: runs every suite (good for CI / make all)
prodder-all: window-lib cli-lib
	@$(MAKE) prodder-build
	@./tools/test_prodder --all

exe-list:
	@find assets/exe_examples -maxdepth 1 -type f \( -name '*.exe' -o -name '*.EXE' \) | sort

exe-runner-build:
	@mkdir -p zig-out/bin
	@zig build-exe "$(EXE_RUNNER_SRC)" -femit-bin="$(EXE_RUNNER_BIN)"

app-exe-builder-build:
	@mkdir -p zig-out/bin
	@zig build-exe "$(APP_EXE_BUILDER_SRC)" -femit-bin="$(APP_EXE_BUILDER_BIN)"

exe-run: exe-runner-build
	@if [ ! -f "$(EXE)" ]; then \
		echo "EXE not found: $(EXE)"; \
		exit 1; \
	fi
	@"$(EXE_RUNNER_BIN)" "$(EXE)" "$(EXE_LOG)"

exe-export: exe-runner-build
	@src="$(SRC_EXE)"; \
	if [ -z "$$src" ] && [ -n "$(SUITE)" ]; then \
		matches=$$(find "app_testing/$(SUITE)" -type f \( -name '*.exe' -o -name '*.EXE' \) | sort); \
		count=$$(printf '%s\n' "$$matches" | sed '/^$$/d' | wc -l | tr -d ' '); \
		if [ "$$count" -eq 1 ]; then \
			src="$$matches"; \
		elif [ "$$count" -gt 1 ]; then \
			echo "Multiple .exe files found for suite $(SUITE); pass SRC_EXE explicitly."; \
			printf '%s\n' "$$matches"; \
			exit 1; \
		fi; \
	fi; \
	if [ -z "$$src" ]; then \
		echo "Pass SRC_EXE=/path/to/file.exe or SUITE=<suite-with-one-exe>."; \
		exit 1; \
	fi; \
	out="$(OUT_EXE)"; \
	if [ -z "$$out" ]; then \
		out="assets/exe_examples/$$(basename "$$src")"; \
	fi; \
	mkdir -p "$$(dirname "$$out")"; \
	cp "$$src" "$$out"; \
	echo "Exported $$src -> $$out"; \
	"$(EXE_RUNNER_BIN)" "$$out" "$$out.trace.log"

app-suite-binary: window-lib cli-lib
	@./tools/build_suite_binary.sh "$(APP_SUITE)" "$(APP_HOST_BIN)"

app-exe: app-suite-binary app-exe-builder-build
	@mkdir -p "$$(dirname "$(APP_EXE)")"
	@"$(APP_EXE_BUILDER_BIN)" "$(APP_SUITE)" "$(ROOT_DIR)/$(APP_HOST_BIN)" "$(ROOT_DIR)/app_testing/$(APP_SUITE)" "$(APP_EXE)"
	@echo "Packaged $(APP_SUITE) -> $(APP_EXE)"

app-exe-parse: app-exe exe-runner-build
	@"$(EXE_RUNNER_BIN)" "$(APP_EXE)" "$(APP_TRACE)" --parse-only

app-exe-run: app-exe exe-runner-build
	@"$(EXE_RUNNER_BIN)" "$(APP_EXE)" "$(APP_TRACE)"
