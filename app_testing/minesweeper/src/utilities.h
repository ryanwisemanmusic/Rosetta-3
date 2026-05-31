/**********/
/* utilities.h */
/**********/

/*
 * Utility function prototypes and helper macros
 * 
 * Functions provided:
 * - Initialization (constants, system metrics caching)
 * - String resource loading with error handling
 * - Random number generation (modulo-based PRNG)
 * - Dialog input validation and retrieval
 * - Menu management (checkmarks, visibility)
 * - About dialog display
 * 
 * ARRAYSIZE macro:
 * - Safe compile-time array size calculation
 * - Prevents buffer overruns in string operations
 */

#ifndef ARRAYSIZE
#define ARRAYSIZE(x) (sizeof(x) / sizeof(x[0]))
#endif

VOID InitializeConstants(VOID);
VOID LoadStringResource(WORD, TCHAR *, DWORD);
VOID DisplayErrorMessage(WORD);
INT  GenerateRandomNumber(INT);

INT  GetDialogInteger(HWND, INT, INT, INT);

VOID ShowAboutDialog(VOID);

VOID SetMenuCheckmark(WORD, BOOL);
VOID SetMenuVisibility(INT);

/* Helper functions to replace wsprintf/CRT */
VOID FormatTime(TCHAR* buf, INT time);
VOID FormatError(TCHAR* buf, const TCHAR* fmt, INT code);
