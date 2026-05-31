/***********/
/* sound.c */
/***********/

/*
 * Audio subsystem - minimal implementation using Windows system sounds
 * 
 * Design philosophy:
 * - Uses PlaySound API with system sound aliases
 * - No custom WAV resources required
 * - Non-blocking playback (SND_ASYNC flag)
 * 
 * Sound mapping:
 * - TUNE_TICK: Disabled (would be too frequent and annoying)
 * - TUNE_WINGAME: SystemExclamation (upbeat notification)
 * - TUNE_LOSEGAME: SystemHand (error/stop sound)
 * 
 * Advantages:
 * - Respects user's system sound scheme
 * - No embedded audio resources to maintain
 * - Works even if user has custom sound themes
 * - Fails gracefully if sounds disabled system-wide
 */

#include <windows.h>
#include <windowsx.h>
#include <mmsystem.h>

#include "main.h"
#include "sound.h"
#include "game.h"
#include "preferences.h"

extern HANDLE g_AppInstance;
extern PREF g_GameConfig;



/****** F I N I T  T U N E S ******/

INT InitializeAudioSystem( VOID )
{
	/* Check if system can play sounds */
	if (PlaySound(NULL, NULL, SND_PURGE) == FALSE)
		return fsoundOff;

	return fsoundOn;
}



/****** E N D  T U N E S ******/

VOID ShutdownAudioSystem(VOID)
{
	/* Stop any currently playing sound */
	if (FSoundOn())
	{
		PlaySound(NULL, NULL, SND_PURGE);
	}
}



/****** P L A Y  T U N E ******/

VOID PlayGameSound(INT tune)
{
	if (!FSoundOn())
		return;

	/* Play Windows system sounds instead of custom WAV files */
	switch (tune)
	{
	case TUNE_TICK:
		/* No tick sound - too frequent, would be annoying */
		break;

	case TUNE_WINGAME:
		/* Play system exclamation sound for winning */
		PlaySoundW(L"SystemExclamation", NULL, SND_ALIAS | SND_ASYNC);
		break;

	case TUNE_LOSEGAME:
		/* Play system hand/error sound for losing */
		PlaySoundW(L"SystemHand", NULL, SND_ALIAS | SND_ASYNC);
		break;

	default:
#ifdef DEBUG
		Oops(TEXT("Invalid Tune"));
#endif
		break;
	}
}
