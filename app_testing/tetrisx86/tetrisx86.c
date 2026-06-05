#include <stdio.h>
#include "game/debug_runtime.h"
#include "win32/Zig/zig_bridge.h"

extern void rosette_run_tetrisx86(void);

int main(int argc, char **argv) {
    rosette_debug_bootstrap_from_argv((argc > 0) ? argv[0] : NULL);
    printf("Rosette: Launching tetrisx86 (x86 ASM translated to Zig)...\n");
    rosette_run_tetrisx86();
    return 0;
}
