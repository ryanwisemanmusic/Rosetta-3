/*
 * C bridge for Rosetta 3 behavioral validation in Zig.
 *
 * This file includes the user-facing shim headers so that Zig's
 * translate-c can see the console I/O, Sleep, and other behavioral
 * function declarations and provide them to behavior.zig.
 *
 * Included shims:
 *   windows.h   – console functions (GetStdHandle, SetConsoleTextAttribute,
 *                 SetConsoleCursorPosition, SetConsoleCursorInfo),
 *                 handle/color constants, COORD, CONSOLE_CURSOR_INFO.
 *   conio.h     – kbhit(), getch() (declared but not called in non‑interactive
 *                 Zig tests).
 */
#ifndef ROSETTA3_BEHAVIOR_BRIDGE_H
#define ROSETTA3_BEHAVIOR_BRIDGE_H

#include "windows.h"
#include "conio.h"

#endif /* ROSETTA3_BEHAVIOR_BRIDGE_H */
