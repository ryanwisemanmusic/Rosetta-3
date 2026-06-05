#include <stdio.h>
#include "game/debug_runtime.h"
#include "win32/Zig/zig_bridge.h"

extern void rosette_run_win32_tetris(void);

int main(int argc, char **argv) {
    rosette_debug_bootstrap_from_argv((argc > 0) ? argv[0] : NULL);
    printf("Rosette: Launching Win32 Tetris (emulated Game.asm layout)...\n");
    rosette_run_win32_tetris();
    return 0;
}
