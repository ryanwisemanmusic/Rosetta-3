/*
 * cout_bridge.cpp
 * Rosette — Redirects std::cout into the Cocoa console buffer.
 *
 * Compiled into librosette_window.a so application-level wrappers
 * don't need their own streambuf.
 *
 * rosette_cout_redirect() is called from the Cocoa window library just
 * before the game thread starts, and rosette_cout_restore() is called
 * when the thread exits.
 */

#include <iostream>
#include <streambuf>

/* Provided by window_main.m */
extern "C" void rosette_write_string(const char *str, int len);

/* ========================================================================= */

class RosetteStreamBuf : public std::streambuf
{
public:
    RosetteStreamBuf() { setp(0, 0); }

protected:
    virtual std::streamsize xsputn(const char *s, std::streamsize n)
    {
        rosette_write_string(s, (int)n);
        return n;
    }

    virtual int overflow(int c)
    {
        if (c != EOF) {
            char ch = (char)c;
            rosette_write_string(&ch, 1);
        }
        return c;
    }

    virtual int sync() { return 0; }
};

static RosetteStreamBuf g_rosettaBuf;
static std::streambuf  *g_origCout = nullptr;

/* ========================================================================= */

extern "C" void rosette_cout_redirect(void)
{
    g_origCout = std::cout.rdbuf(&g_rosettaBuf);
}

extern "C" void rosette_cout_restore(void)
{
    if (g_origCout)
        std::cout.rdbuf(g_origCout);
}
