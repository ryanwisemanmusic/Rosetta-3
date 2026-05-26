/*
 * Local intrinsics shim for non-MSVC toolchains.
 * This keeps Windows headers parseable on macOS while the project grows.
 */
#ifndef ROSETTA3_SHIMS_WIN32_INTRIN_H
#define ROSETTA3_SHIMS_WIN32_INTRIN_H

#ifndef _MSC_VER
#if !defined(_ReadWriteBarrier)
#define _ReadWriteBarrier() __atomic_signal_fence(__ATOMIC_SEQ_CST)
#endif

#if !defined(_mm_pause)
#define _mm_pause() __asm__ __volatile__("pause")
#endif

#endif

#endif /* ROSETTA3_SHIMS_WIN32_INTRIN_H */
