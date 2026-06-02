/*
 * snax86_windowed.c
 * Windowed entry point for snax86 (Snake) game.
 *
 * Creates a Cocoa console window via extern_window.m and runs the
 * snake game core on a background thread.
 */

#include <stdio.h>
#include "game/debug_runtime.h"
#include "win32/Zig/zig_bridge.h"

#ifdef __cplusplus
extern "C" {
#endif
extern void rosetta3_run_snax86_core(void);
extern void rosetta3_windowed_run(int grid_w, int grid_h,
                                   int block_w, int block_h,
                                   const char *title,
                                   void (*game_func)(void *),
                                   void *arg);
#ifdef __cplusplus
}
#endif

static void game_thread(void *arg)
{
    (void)arg;
    rosetta3_run_snax86_core();
}

int main(int argc, char **argv)
{
    rosetta3_debug_bootstrap_from_argv((argc > 0) ? argv[0] : NULL);
    printf("Rosetta 3: Launching snax86 windowed...\n");
    /* Screen is 60 columns x 20 rows defined by the game */
    rosetta3_windowed_run(60, 20, 0, 0, "Snake (Windowed)", game_thread, NULL);
    return 0;
}
