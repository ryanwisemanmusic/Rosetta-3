#include <stdio.h>
#include "game/debug_runtime.h"
#include "win32/Zig/zig_bridge.h"

extern void rosette_run_pacman_text_runner(void);

int main(int argc, char **argv) {
    rosette_debug_bootstrap_from_argv((argc > 0) ? argv[0] : NULL);
    printf("Rosette: Launching PACMAN-x86 (JWasm Irvine32 translated to Zig) with ABI validation...\n");
    rosette_run_pacman_text_runner();
    return 0;
}
