/*
 * cout_bridge.cpp
 * Rosetta 3 — Redirects std::cout into the Cocoa console buffer.
 *
 * Compiled into librosetta_window.a so application-level wrappers
 * don't need their own streambuf.
 *
 * rosetta_cout_redirect() is called from the Cocoa window library just
 * before the game thread starts, and rosetta_cout_restore() is called
 * when the thread exits.
 */

#include <iostream>
#include <streambuf>

/* Provided by window_main.m */
extern "C" void rosetta_write_string(const char *str, int len);

/* ========================================================================= */

class RosettaStreamBuf : public std::streambuf
{
public:
    RosettaStreamBuf() { setp(0, 0); }

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

static RosettaStreamBuf g_rosettaBuf;
static std::streambuf  *g_origCout = nullptr;

/* ========================================================================= */

extern "C" void rosetta_cout_redirect(void)
{
    g_origCout = std::cout.rdbuf(&g_rosettaBuf);
}

extern "C" void rosetta_cout_restore(void)
{
    if (g_origCout)
        std::cout.rdbuf(g_origCout);
}
