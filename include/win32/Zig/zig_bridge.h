#ifndef ZIG_BRIDGE_H
#define ZIG_BRIDGE_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Return: 0=unknown, 1=x86_64, 2=aarch64 */
uint32_t zig_arch(void);

void        rosetta3_print_abi_report(void);
int         rosetta3_validate_abi(void);
const char *rosetta3_abi_failure_name(int code);

void        rosetta3_print_sysinfo_report(void);
int         rosetta3_validate_sysinfo(void);
const char *rosetta3_sysinfo_failure_name(int code);

void        rosetta3_print_behavior_report(void);
int         rosetta3_validate_behavior(void);
const char *rosetta3_behavior_failure_name(int code);

void        rosetta3_gfx_scene_set_canvas_size(uint32_t width, uint32_t height);

#ifdef __cplusplus
}
#endif

#endif /* ZIG_BRIDGE_H */
