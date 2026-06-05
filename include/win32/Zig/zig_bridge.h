#ifndef ZIG_BRIDGE_H
#define ZIG_BRIDGE_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Return: 0=unknown, 1=x86_64, 2=aarch64 */
uint32_t zig_arch(void);

void        rosette_print_abi_report(void);
int         rosette_validate_abi(void);
const char *rosette_abi_failure_name(int code);

void        rosette_print_sysinfo_report(void);
int         rosette_validate_sysinfo(void);
const char *rosette_sysinfo_failure_name(int code);

void        rosette_print_behavior_report(void);
int         rosette_validate_behavior(void);
const char *rosette_behavior_failure_name(int code);

void        rosette_print_console_window_abi_report(void);
int         rosette_validate_console_window_abi(void);
const char *rosette_console_window_abi_failure_name(int code);

void        rosette_print_mmsystem_report(void);
int         rosette_validate_mmsystem(void);
const char *rosette_mmsystem_failure_name(int code);

void        rosette_print_atomic_report(void);
int         rosette_validate_atomic(void);
const char *rosette_atomic_failure_name(int code);

void        rosette_print_dbghelp_report(void);
int         rosette_validate_dbghelp(void);
const char *rosette_dbghelp_failure_name(int code);

void        rosette_print_dds_report(void);
int         rosette_validate_dds(void);
const char *rosette_dds_failure_name(int code);

void        rosette_print_fiber_report(void);
int         rosette_validate_fiber(void);
const char *rosette_fiber_failure_name(int code);

void        rosette_print_file_report(void);
int         rosette_validate_file(void);
const char *rosette_file_failure_name(int code);

void        rosette_print_gdi_report(void);
int         rosette_validate_gdi(void);
const char *rosette_gdi_failure_name(int code);

void        rosette_print_intrin_report(void);
int         rosette_validate_intrin(void);
const char *rosette_intrin_failure_name(int code);

void        rosette_print_io_report(void);
int         rosette_validate_io(void);
const char *rosette_io_failure_name(int code);

void        rosette_print_process_report(void);
int         rosette_validate_process(void);
const char *rosette_process_failure_name(int code);

void        rosette_print_synchapi_report(void);
int         rosette_validate_synchapi(void);
const char *rosette_synchapi_failure_name(int code);

void        rosette_print_threads_report(void);
int         rosette_validate_threads(void);
const char *rosette_threads_failure_name(int code);

void        rosette_print_window_report(void);
int         rosette_validate_window(void);
const char *rosette_window_failure_name(int code);

void        rosette_print_shim_surface_report(void);
int         rosette_validate_shim_surface(void);
const char *rosette_shim_surface_failure_name(int code);

void        rosette_print_handshake_suite_report(void);
int         rosette_validate_handshake_suite(void);
const char *rosette_handshake_suite_failure_name(int code);

void        rosette_gfx_scene_set_canvas_size(uint32_t width, uint32_t height);

#ifdef __cplusplus
}
#endif

#endif /* ZIG_BRIDGE_H */
