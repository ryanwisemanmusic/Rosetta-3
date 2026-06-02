#include <stdio.h>
#include "game/debug_runtime.h"
#include "win32/Zig/zig_bridge.h"

extern void rosetta3_run_win32_tetris(void);

int main(int argc, char **argv) {
    rosetta3_debug_bootstrap_from_argv((argc > 0) ? argv[0] : NULL);
    printf("Rosetta 3: Launching Win32 Tetris (emulated Game.asm layout)...\n");
    rosetta3_run_win32_tetris();
    return 0;
}
