.PHONY: shim-check
shim-check:
	@echo "Checking shim headers...";
	@tmpdir=$$(mktemp -d /tmp/rosetta3_shim.XXXXXX); \
	tmp="$$tmpdir/check.c"; \
	printf '%s\n' '#include "shims/win32/intrin.h"' 'int main(void){return 0;}' > "$$tmp"; \
	clang -fsyntax-only -I"include/shims/win32" -I".rosetta3/include" -I"include" "$$tmp" || true; \
	rm -rf "$$tmpdir"

.PHONY: shim-check-all
shim-check-all:
	@echo "Checking all shim headers recursively...";
	@for header in $$(find include/shims/win32 -type f -name '*.h' | sort); do \
		tmpdir=$$(mktemp -d /tmp/rosetta3_shim_header.XXXXXX); \
		tmp="$$tmpdir/check.c"; \
		printf '%s\n' '#include "'"$${header#include/}"'"' 'int main(void){return 0;}' > "$$tmp"; \
		clang -fsyntax-only -I"include/shims/win32" -I".rosetta3/include" -I"include" "$$tmp" || exit $$?; \
		rm -rf "$$tmpdir"; \
	done
