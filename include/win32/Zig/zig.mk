.PHONY: zig-build-local
zig-build-local:
	@echo "Zig build: running 'zig build check' for include/win32/Zig sources...";
	@if ! command -v zig >/dev/null 2>&1; then echo "zig not found in PATH"; exit 1; fi
	@if [ ! -f build.zig ]; then echo "no build.zig at repo root; nothing to build"; exit 0; fi
	@zig build check || exit $$?; \
	echo "Zig build complete"

.PHONY: zig-build-all
zig-build-all: zig-build-local
