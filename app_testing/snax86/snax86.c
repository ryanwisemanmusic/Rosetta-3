#include <stdio.h>
#include "game/debug_runtime.h"
#include "win32/Zig/zig_bridge.h"

// This will be exported from our Zig implementation
extern void rosetta3_run_snax86(void);

int main(int argc, char **argv) {
    rosetta3_debug_bootstrap_from_argv((argc > 0) ? argv[0] : NULL);
    printf("Rosetta 3: Launching snax86 (x86 ASM translated to Zig)...\n");
    rosetta3_run_snax86();
    return 0;
}
