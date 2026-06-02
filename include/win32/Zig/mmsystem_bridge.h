/*
 * C bridge for Rosetta 3 MMSystem (mmsystem.h) ABI validation in Zig.
 *
 * This file includes the mmsystem.h shim so that Zig's translate-c
 * can see the PlaySound, mciSendString declarations, MMRESULT typedef,
 * and all SND_* / MCI_* constants.
 *
 * Included shims:
 *   mmsystem.h  – PlaySoundA/W, mciSendStringA/W, MMRESULT, constants.
 */
#ifndef ROSETTA3_MMSYSTEM_BRIDGE_H
#define ROSETTA3_MMSYSTEM_BRIDGE_H

#include "mmsystem.h"

#endif /* ROSETTA3_MMSYSTEM_BRIDGE_H */
