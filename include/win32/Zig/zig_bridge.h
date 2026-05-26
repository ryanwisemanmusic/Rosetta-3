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

#ifdef __cplusplus
}
#endif

#endif /* ZIG_BRIDGE_H */