/*
 * window_main.mm — Snake game demo for the Rosetta 3 Cocoa console window.
 *
 * Compile with ROSETTA_WINDOW_MODE defined and link against
 * librosetta_window.a + librosetta3_zig.a.
 *
 * Build:
 *   clang++ -std=c++11 -DROSETTA_WINDOW_MODE \
 *           -Iinclude/shims/macos -Iinclude/shims/win32 -I.rosetta3/include -Iinclude \
 *           app_testing/basic_snake/window_main.mm \
 *           librosetta_window.a zig-out/lib/librosetta3_zig.a \
 *           -framework Cocoa -framework Foundation \
 *           -o snake_game
 */

#include <iostream>
#include <vector>
#include <algorithm>
#include <time.h>
#include <cstring>

/* ---- ObjC / Cocoa must be imported before Win32 headers so that the   */
/* platform defines for BOOL, interface, etc. are seen first and the      */
/* shim guards (#ifndef BOOL, #ifndef __OBJC__) fire correctly.           */
#ifdef __OBJC__
#import <Cocoa/Cocoa.h>
#endif

/* ---- Route Win32 console calls to the Cocoa window -------------------- */
#define ROSETTA_WINDOW_MODE
#include <windows.h>
#include <synchapi.h>
#include <conio.h>

/* ---- ObjC window library ---------------------------------------------- */
extern "C" void rosetta_window_run(int width, int height,
                                   void (*thread_func)(void *), void *arg);
extern "C" void rosetta_write_string(const char *str, int len);
extern "C" void rosetta_console_clear_screen(void);

/* ---- Redirect std::cout to the window buffer -------------------------- */
static int window_width  = 118;
static int window_height = 27;

class WindowStreamBuf : public std::streambuf
{
public:
    WindowStreamBuf() { setp(0, 0); }
protected:
    virtual std::streamsize xsputn(const char *s, std::streamsize n)
    {
        rosetta_write_string(s, (int)n);
        return n;
    }
    virtual int overflow(int c)
    {
        if (c != EOF) {
            char ch = (char)c;
            rosetta_write_string(&ch, 1);
        }
        return c;
    }
    virtual int sync()
    {
        return 0;
    }
};

static WindowStreamBuf g_windowBuf;
static std::streambuf  *g_origCoutBuf = nullptr;

static void redirect_cout(void)
{
    g_origCoutBuf = std::cout.rdbuf(&g_windowBuf);
}

static void restore_cout(void)
{
    if (g_origCoutBuf)
        std::cout.rdbuf(g_origCoutBuf);
}

/* ---- system("cls") override ------------------------------------------- */
extern "C" int system(const char *cmd)
{
    if (cmd && std::strcmp(cmd, "cls") == 0) {
        rosetta_console_clear_screen();
        return 0;
    }
    /* Fall through to real system() for other commands. */
    return ::system(cmd);
}

/* ---- Renamed snake-game main() ---------------------------------------- */
/* snake.c defines its own main().  We rename it via a preprocessor      *
 * trick so our wrapper can provide a game-thread entry point.             */
#define main snake_main
#include "snake.c"
#undef main

/* ---- Game thread entry point for the Cocoa window --------------------- */
static void game_thread(void *)
{
    redirect_cout();
    snake_main();
    restore_cout();
}

/* ---- Application entry point ------------------------------------------ */
int main(int, char **)
{
    rosetta_window_run(window_width, window_height, game_thread, nullptr);
    return 0;
}
