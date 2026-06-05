/*
 * tetrisx86_windowed.c
 * Windowed entry point for tetrisx86 (Tetris) game.
 *
 * Creates a Cocoa console window via extern_window.m and runs the
 * tetris game core on a background thread.
 */

#include <stdio.h>
#include "game/debug_runtime.h"
#include "win32/Zig/zig_bridge.h"

#ifdef __cplusplus
extern "C" {
#endif
extern void rosette_run_tetrisx86_core(void);
extern void rosette_gfx_scene_set_canvas_size(unsigned int width, unsigned int height);
extern void rosette_windowed_run(int grid_w, int grid_h,
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
    rosette_run_tetrisx86_core();
}

int main(int argc, char **argv)
{
    rosette_debug_bootstrap_from_argv((argc > 0) ? argv[0] : NULL);
    printf("Rosette: Launching tetrisx86 windowed...\n");
    rosette_gfx_scene_set_canvas_size(520, 400);
    /* This title renders through the scene path; forcing the legacy block
     * framebuffer here causes unstable startup on macOS. */
    rosette_windowed_run(40, 32, 0, 0, "Tetris (Windowed)", game_thread, NULL);
    return 0;
}
