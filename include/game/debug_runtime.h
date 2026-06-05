#ifndef ROSETTE_GAME_DEBUG_RUNTIME_H
#define ROSETTE_GAME_DEBUG_RUNTIME_H

#ifdef __cplusplus
extern "C" {
#endif

void rosette_debug_bootstrap_from_argv(const char *argv0);
int rosette_debug_enabled(void);
int rosette_debug_x86_disasm_enabled(void);
int rosette_debug_graphics_enabled(void);
int rosette_debug_first_frame_dump_enabled(void);
const char *rosette_debug_log_path(void);
int rosette_runtime_abi_fail_fast_enabled(void);
void rosette_debug_log_host_call(const char *arch, const char *domain, const char *detail);
void rosette_runtime_abi_host_violation(const char *domain, const char *check, const char *detail);
int rosette_fb_logger_enabled(void);
const char *rosette_fb_logger_directory(void);
int rosette_window_width_or(int default_value);
int rosette_window_height_or(int default_value);
unsigned int rosette_canvas_width_or(unsigned int default_value);
unsigned int rosette_canvas_height_or(unsigned int default_value);
const char *rosette_window_title_or(const char *default_value);

#ifdef __cplusplus
}
#endif

#endif
