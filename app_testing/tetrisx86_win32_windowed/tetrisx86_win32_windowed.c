/*
 * tetrisx86_win32_windowed.c
 * Windowed entry point for the Win32 TetrisX86 translation path.
 */

#include <stdio.h>
#include "game/debug_runtime.h"
#include "win32/Zig/zig_bridge.h"

#ifdef __cplusplus
extern "C" {
#endif
extern void rosetta3_run_win32_tetris_core(void);
extern void rosetta3_gfx_scene_set_canvas_size(unsigned int width, unsigned int height);
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
    rosetta3_run_win32_tetris_core();
}

int main(int argc, char **argv)
{
    rosetta3_debug_bootstrap_from_argv((argc > 0) ? argv[0] : NULL);
    printf("Rosetta 3: Launching Win32 Tetris windowed...\n");
    rosetta3_gfx_scene_set_canvas_size(520, 400);
    /* Scene-driven Win32 Tetris: no legacy block framebuffer, only direct scene composition. */
    rosetta3_windowed_run(40, 32, 0, 0, "Tetris (Win32 Windowed)", game_thread, NULL);
    return 0;
}
