/*
 * C bridge for Rosette MMSystem (mmsystem.h) ABI validation in Zig.
 *
 * This file includes the mmsystem.h shim so that Zig's translate-c
 * can see the PlaySound, mciSendString declarations, MMRESULT typedef,
 * and all SND_* / MCI_* constants.
 *
 * Included shims:
 *   mmsystem.h  – PlaySoundA/W, mciSendStringA/W, MMRESULT, constants.
 */
#ifndef ROSETTE_MMSYSTEM_BRIDGE_H
#define ROSETTE_MMSYSTEM_BRIDGE_H

#include "mmsystem.h"

#endif /* ROSETTE_MMSYSTEM_BRIDGE_H */
