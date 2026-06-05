/*
 * Rosette shim for DOS / Win32 conio.h (console I/O).
 *
 * Two backends:
 *   1. Default — the reference implementation in
 *      .rosette/include/dos/conio.h (termios, ANSI escapes).
 *   2. ROSETTE_WINDOW_MODE — routes to the Objective‑C Cocoa window
 *      library.  Define ROSETTE_WINDOW_MODE before including this
 *      header and link librosette_window.a.
 */
#ifndef ROSETTE_SHIMS_WIN32_CONIO_H
#define ROSETTE_SHIMS_WIN32_CONIO_H

#ifdef ROSETTE_WINDOW_MODE

/* The ObjC library provides these (C linkage — defined in window_main.m). */
#ifdef __cplusplus
extern "C" {
#endif
int rosette_kbhit(void);
int rosette_getch(void);
#ifdef __cplusplus
}
#endif

#define kbhit rosette_kbhit
#define getch rosette_getch
#define getche rosette_getch

#else

/* Default: redirect to the reference implementation. */
#include "../../../.rosette/include/dos/conio.h"

#endif /* ROSETTE_WINDOW_MODE */

#endif /* ROSETTE_SHIMS_WIN32_CONIO_H */
