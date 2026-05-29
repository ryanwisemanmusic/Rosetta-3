/*
 * window_entry.cpp — Snake game demo for the Rosetta 3 Cocoa console window.
 *
 * Compiled by the test prodder (via SUITE_SOURCES=window_entry.cpp in
 * suite.cfg) into a standalone binary.  Requires librosetta_window.a,
 * -framework Cocoa, -framework Foundation.
 *
 * snake.c (the shared game logic) is #include'd here and is not compiled
 * as a separate binary — its game loop would block the prodder.
 */

#define ROSETTA_WINDOW_MODE
#include <windows.h>
#include <synchapi.h>
#include <conio.h>
#include <cstring>
#include <iostream>

/* ---- ObjC window library C-linkage entry points ------------------------ */
extern "C" void rosetta_window_run(int width, int height,
                                    void (*thread_func)(void *), void *arg);
extern "C" void rosetta_write_string(const char *str, int len);

/*
 * The snake game draws a canvas of (lenght+2) × (width+3):
 *   lenght=118, width=27   (playable area, as defined in snake.c)
 *   +2 columns for left/right walls
 *   +3 rows for score line + top wall + bottom wall
 * The buffer and window must match this full canvas size so walls,
 * score, food, and snake heads are all on-screen and in-bounds.
 */
static int window_width  = 118 + 2;   /* full canvas columns */
static int window_height = 27 + 3;    /* full canvas rows    */

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
    virtual int sync() { return 0; }
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

/* ---- Renamed snake-game main() ----------------------------------------- */
#define main snake_main
#include "snake.c"
#undef main

/* ---- Game thread entry point for the Cocoa window ---------------------- */
static void game_thread(void *)
{
    redirect_cout();
    snake_main();
    restore_cout();
}

/* ---- Application entry point ------------------------------------------- */
int main(int, char **)
{
    rosetta_window_run(window_width, window_height, game_thread, nullptr);
    return 0;
}
