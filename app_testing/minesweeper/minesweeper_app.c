/*
 * minesweeper_app.c
 * Rosetta 3 single-translation-unit compile wrapper for Minesweeper.
 */

#include "src/utilities.c"
#include "src/preferences.c"
#include "src/sound.c"
#include "src/game.c"
#include "src/graphics.c"
#include "src/minesweeper.c"

int rosetta_game_main(void)
{
    HINSTANCE hInstance = GetModuleHandleW(NULL);
    LPSTR lpCmdLine = GetCommandLineA();
    STARTUPINFOA si;
    INT nCmdShow = SW_SHOWDEFAULT;
    si.cb = sizeof(si);
    GetStartupInfoA(&si);
    if (si.dwFlags & STARTF_USESHOWWINDOW)
        nCmdShow = si.wShowWindow;
    return WinMineApp(hInstance, NULL, lpCmdLine, nCmdShow);
}
__asm__(".globl __Z17rosetta_game_mainv\n__Z17rosetta_game_mainv = _rosetta_game_main");
