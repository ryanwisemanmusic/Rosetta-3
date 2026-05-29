/*
 * Rosetta 3 shim for DOS / Win32 conio.h (console I/O).
 *
 * Two backends:
 *   1. Default — the reference implementation in
 *      .rosetta3/include/dos/conio.h (termios, ANSI escapes).
 *   2. ROSETTA_WINDOW_MODE — routes to the Objective‑C Cocoa window
 *      library.  Define ROSETTA_WINDOW_MODE before including this
 *      header and link librosetta_window.a.
 */
#ifndef ROSETTA3_SHIMS_WIN32_CONIO_H
#define ROSETTA3_SHIMS_WIN32_CONIO_H

#ifdef ROSETTA_WINDOW_MODE

/* The ObjC library provides these. */
int rosetta_kbhit(void);
int rosetta_getch(void);

#define kbhit rosetta_kbhit
#define getch rosetta_getch
#define getche rosetta_getch

#else

/* Default: redirect to the reference implementation. */
#include "../../../.rosetta3/include/dos/conio.h"

#endif /* ROSETTA_WINDOW_MODE */

#endif /* ROSETTA3_SHIMS_WIN32_CONIO_H */
