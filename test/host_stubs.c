#include <stddef.h>
#include <stdbool.h>

/* Debug/Runtime symbols */
int rosette_debug_enabled(void) { return 0; }
const char *rosette_debug_log_path(void) { return ""; }
int rosette_runtime_abi_fail_fast_enabled(void) { return 0; }
int rosette_debug_x86_disasm_enabled(void) { return 0; }
void rosette_runtime_abi_host_violation(const char *domain, const char *check, const char *detail) {
    (void)domain; (void)check; (void)detail;
}

/* CLI host symbols */
void rosette_cli_init(void) {}
void rosette_cli_deinit(void) {}
void rosette_cli_begin_frame(void) {}
void rosette_cli_end_frame(void) {}
void rosette_cli_clear(void) {}
void rosette_cli_move_cursor(int x, int y) { (void)x; (void)y; }
void rosette_cli_write_byte(unsigned char byte) { (void)byte; }
void rosette_cli_write_text(const char *text, int len) { (void)text; (void)len; }
int rosette_cli_get_key(void) { return -1; }

/* Graphics scene host symbols */
bool rosette_gfx_scene_is_available(void) { return false; }
void rosette_gfx_scene_set_canvas_size(unsigned int width, unsigned int height) { (void)width; (void)height; }
unsigned int rosette_gfx_scene_get_canvas_width(void) { return 0; }
unsigned int rosette_gfx_scene_get_canvas_height(void) { return 0; }
void rosette_gfx_scene_clear(void) {}
void rosette_gfx_scene_fill_rect(int x, int y, int width, int height, unsigned int color) {
    (void)x; (void)y; (void)width; (void)height; (void)color;
}
void rosette_gfx_scene_draw_text(int x, int y, unsigned int fg_color, unsigned int bg_color, const unsigned char *text_ptr, unsigned int len) {
    (void)x; (void)y; (void)fg_color; (void)bg_color; (void)text_ptr; (void)len;
}

/* Window configuration fallback symbols */
int rosette_window_width_or(int default_value) { return default_value; }
int rosette_window_height_or(int default_value) { return default_value; }
unsigned int rosette_canvas_width_or(unsigned int default_value) { return default_value; }
unsigned int rosette_canvas_height_or(unsigned int default_value) { return default_value; }
const char *rosette_window_title_or(const char *default_value) { return default_value; }

/* Windowed runner symbol */
void rosette_windowed_run(int grid_w, int grid_h,
                           int block_w, int block_h,
                           const char *title,
                           void (*game_func)(void *),
                           void *arg) {
    (void)grid_w; (void)grid_h; (void)block_w; (void)block_h; (void)title; (void)game_func; (void)arg;
}
