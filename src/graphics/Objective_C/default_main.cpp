/*
 * default_main.cpp — default main() for librosetta_window.a.
 *
 * When a game source is compiled with -Dmain=rosetta_game_main,
 * this provides the application entry point that creates the
 * Cocoa console window and launches the game thread.
 *
 * Window dimensions (width × height character grid) are loaded
 * from a game.toml file located next to the binary at runtime.
 * If the file is not found, sensible defaults are used (80×25).
 */

#include <game/toml_config.h>
#include <libgen.h>
#include <cstdlib>
#include <cstring>
#include <string>

static bool g_debug_enabled = false;
static bool g_x86_disasm_enabled = false;
static std::string g_debug_log_file = "rosetta3-x86.log";

/* Provided by librosetta_window.a (window_main.m) */
extern "C" void rosetta_window_run(int width, int height,
                                    void (*thread_func)(void *), void *arg);

/* Provided by librosetta_window.a (window_gdi.m) */
extern "C" void rosetta_gdi_window_run(int width, int height, const char *title,
                                        void (*thread_func)(void *), void *arg);

/* Renamed from game's main() via -Dmain=rosetta_game_main */
extern int rosetta_game_main(void);

extern "C" int rosetta3_debug_enabled(void)
{
    return g_debug_enabled ? 1 : 0;
}

extern "C" int rosetta3_debug_x86_disasm_enabled(void)
{
    return (g_debug_enabled && g_x86_disasm_enabled) ? 1 : 0;
}

extern "C" const char *rosetta3_debug_log_path(void)
{
    return g_debug_log_file.c_str();
}

static void game_entry(void *arg)
{
    (void)arg;
    rosetta_game_main();
}

static std::string config_path_from_argv(const char *argv0)
{
    if (!argv0 || argv0[0] == '\0') return "";
    char *copy = strdup(argv0);
    if (!copy) return "";
    std::string dir = dirname(copy);
    free(copy);
    if (dir == ".") return "";
    return dir + "/game.toml";
}

int main(int argc, char **argv)
{
    (void)argc;

    int width = 80;
    int height = 25;
    int gdi = 0;
    std::string title = "Rosetta 3";

    /* Try binary directory first, then CWD */
    std::string path = (argc > 0) ? config_path_from_argv(argv[0]) : "";
    TomlConfig config;

    if (!path.empty() && config.load(path)) {
        width  = (int)config.get_int("window", "width",  width);
        height = (int)config.get_int("window", "height", height);
        gdi    = (int)config.get_int("window", "gdi",    gdi);
        title  = config.get_string("window", "title",  title);
        g_debug_enabled = config.get_bool("debug", "enabled", false);
        g_x86_disasm_enabled = config.get_bool("debug", "x86_disasm", false);
        g_debug_log_file = config.get_string("debug", "log_file", g_debug_log_file);
    } else if (config.load("game.toml")) {
        width  = (int)config.get_int("window", "width",  width);
        height = (int)config.get_int("window", "height", height);
        gdi    = (int)config.get_int("window", "gdi",    gdi);
        title  = config.get_string("window", "title",  title);
        g_debug_enabled = config.get_bool("debug", "enabled", false);
        g_x86_disasm_enabled = config.get_bool("debug", "x86_disasm", false);
        g_debug_log_file = config.get_string("debug", "log_file", g_debug_log_file);
    }

    if (gdi) {
        rosetta_gdi_window_run(width, height, title.c_str(),
                                game_entry, nullptr);
    } else {
        rosetta_window_run(width, height, game_entry, nullptr);
    }
    return 0;
}
