/**********/
/* preferences.h */
/**********/

/*
 * Configuration and preferences data structures
 * 
 * PREF structure stores all persistent game settings:
 * - Game difficulty and grid dimensions
 * - Window position
 * - Audio/UI preferences
 * - High score table (3 difficulty levels)
 * 
 * Registry key indices (iszPref constants):
 * - Numerical indices map to registry value names
 * - Used by ReadRegistryInteger/WriteRegistryInteger functions
 * - Ensures consistent access across load/save operations
 */

#define cchNameMax 32   /* Maximum player name length */

/*
 * Persistent configuration structure
 * 
 * Stored in registry under HKCU\Software\MinesweeperGame\Settings
 * All values validated on load with min/max clamping
 */
typedef struct
{
	WORD  wGameType;              /* Difficulty: 0=Beginner, 1=Inter, 2=Expert, 3=Custom */
	INT   Mines;                  /* Mine count (10-999) */
	INT   Height;                 /* Grid height (9-24) */
	INT   Width;                  /* Grid width (9-30) */
	INT   xWindow;                /* Window X position */
	INT   yWindow;                /* Window Y position */
	INT   fSound;                 /* Sound enabled (0=off, 3=on) */
	BOOL  fMark;                  /* Question marks enabled */
	BOOL  fTick;                  /* Tick sound enabled (unused) */
	BOOL  fMenu;                  /* Menu visibility mode */
	INT   rgTime[3];              /* High scores in seconds [Beginner, Inter, Expert] */
	TCHAR szBegin[cchNameMax];    /* Beginner high score name */
	TCHAR szInter[cchNameMax];    /* Intermediate high score name */
	TCHAR szExpert[cchNameMax];   /* Expert high score name */
} PREF;

/* Registry value name indices */
#define iszPrefGame    0          /* wGameType */
#define iszPrefMines   1          /* Mines */
#define iszPrefHeight  2          /* Height */
#define iszPrefWidth   3          /* Width */
#define iszPrefxWindow 4          /* xWindow */
#define iszPrefyWindow 5          /* yWindow */
#define iszPrefSound   6          /* fSound */
#define iszPrefMark    7          /* fMark */
#define iszPrefMenu    8          /* fMenu */
#define iszPrefTick    9          /* fTick */
#define iszPrefBeginTime   10     /* rgTime[0] */
#define iszPrefBeginName   11     /* szBegin */
#define iszPrefInterTime   12     /* rgTime[1] */
#define iszPrefInterName   13     /* szInter */
#define iszPrefExpertTime  14     /* rgTime[2] */
#define iszPrefExpertName  15     /* szExpert */
#define iszPrefMax 16             /* Total registry value count */


VOID LoadConfiguration(VOID);
VOID SaveConfiguration(VOID);
INT  ReadRegistryInteger(INT, INT, INT, INT);
VOID ReadRegistryString(INT, TCHAR FAR *);
