/*
 * ARM compatibility helpers for non-MSVC toolchains.
 * These bridge Windows-style integer spellings that clang and Zig do not
 * expose by default.
 */
#ifndef WINDOWS_ARM_COMPAT_H
#define WINDOWS_ARM_COMPAT_H

#if !defined(_MSC_VER)
#ifndef __int64
#define __int64 long long
#endif

#ifndef __uint64
#define __uint64 unsigned long long
#endif
#endif

#endif /* WINDOWS_ARM_COMPAT_H */