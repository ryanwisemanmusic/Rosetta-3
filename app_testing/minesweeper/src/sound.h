/*****************/
/* file: sound.h */
/*****************/

/*
 * Audio subsystem interface
 * 
 * Sound event constants:
 * - TUNE_TICK: Timer tick (currently disabled)
 * - TUNE_WINGAME: Victory sound
 * - TUNE_LOSEGAME: Defeat sound
 * 
 * Sound state flags:
 * - fsoundOn (3): Audio enabled and functional
 * - fsoundOff (2): Audio disabled
 * 
 * Design notes:
 * - Uses Windows system sounds (no embedded WAV files)
 * - Non-blocking playback via SND_ASYNC flag
 * - Respects user's system sound scheme preferences
 */

#define TUNE_TICK      1
#define TUNE_WINGAME   2
#define TUNE_LOSEGAME  3

#define fsoundOn  3
#define fsoundOff 2

/* Sound configuration testing macros */
#define FSoundSwitchable()  (g_GameConfig.fSound > 1)
#define FSoundOn()          (g_GameConfig.fSound == fsoundOn)

INT  InitializeAudioSystem(VOID);
VOID PlayGameSound(INT);
VOID ShutdownAudioSystem(VOID);
