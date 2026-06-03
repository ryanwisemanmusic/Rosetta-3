#ifndef ROSETTA3_GAME_DEBUG_RUNTIME_H
#define ROSETTA3_GAME_DEBUG_RUNTIME_H

#ifdef __cplusplus
extern "C" {
#endif

void rosetta3_debug_bootstrap_from_argv(const char *argv0);
int rosetta3_debug_enabled(void);
int rosetta3_debug_x86_disasm_enabled(void);
int rosetta3_debug_graphics_enabled(void);
int rosetta3_debug_first_frame_dump_enabled(void);
const char *rosetta3_debug_log_path(void);
int rosetta3_runtime_abi_fail_fast_enabled(void);
void rosetta3_debug_log_host_call(const char *arch, const char *domain, const char *detail);
void rosetta3_runtime_abi_host_violation(const char *domain, const char *check, const char *detail);
int rosetta3_fb_logger_enabled(void);
const char *rosetta3_fb_logger_directory(void);
int rosetta3_window_width_or(int default_value);
int rosetta3_window_height_or(int default_value);
unsigned int rosetta3_canvas_width_or(unsigned int default_value);
unsigned int rosetta3_canvas_height_or(unsigned int default_value);
const char *rosetta3_window_title_or(const char *default_value);

#ifdef __cplusplus
}
#endif

#endif
