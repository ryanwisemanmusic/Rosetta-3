#include <stdio.h>
#include "game/debug_runtime.h"
#include "win32/Zig/zig_bridge.h"

extern void rosetta3_run_pacman_text_runner(void);

int main(int argc, char **argv) {
    rosetta3_debug_bootstrap_from_argv((argc > 0) ? argv[0] : NULL);
    printf("Rosetta 3: Launching PACMAN-x86 (JWasm Irvine32 translated to Zig) with ABI validation...\n");
    rosetta3_run_pacman_text_runner();
    return 0;
}
