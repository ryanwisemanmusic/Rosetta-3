.PHONY: win32-check
win32-check:
	@echo "Checking win32 headers...";
	@tmpdir=$$(mktemp -d /tmp/rosetta3_win32.XXXXXX); \
	tmp="$$tmpdir/check.c"; \
	printf '%s\n' '#include "win32/windows_base.h"' '#include "win32/atomic.h"' 'int main(void){return 0;}' > "$$tmp"; \
	clang -fsyntax-only -I"include/shims/win32" -I"include" "$$tmp" || true; \
	rm -rf "$$tmpdir"

.PHONY: win32-check-all
win32-check-all:
	@echo "Checking all win32 headers recursively...";
	@for header in $$(find include/win32 -type f -name '*.h' | sort); do \
		tmpdir=$$(mktemp -d /tmp/rosetta3_header.XXXXXX); \
		tmp="$$tmpdir/check.c"; \
		printf '%s\n' '#include "'"$${header#include/}"'"' 'int main(void){return 0;}' > "$$tmp"; \
		clang -fsyntax-only -I"include/shims/win32" -I"include" "$$tmp" || exit $$?; \
		rm -rf "$$tmpdir"; \
	done
