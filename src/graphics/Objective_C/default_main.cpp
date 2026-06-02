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

#include <game/debug_runtime.h>
#include <game/toml_config.h>
#include <libgen.h>
#include <cstdlib>
#include <cstring>
#include <string>

/* Provided by librosetta_window.a (window_main.m) */
extern "C" void rosetta_window_run(int width, int height,
                                    void (*thread_func)(void *), void *arg);

/* Provided by librosetta_window.a (window_gdi.m) */
extern "C" void rosetta_gdi_window_run(int width, int height, const char *title,
                                        void (*thread_func)(void *), void *arg);

/* Renamed from game's main() via -Dmain=rosetta_game_main */
extern int rosetta_game_main(void);

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
    int width = 80;
    int height = 25;
    int gdi = 0;
    std::string title = "Rosetta 3";
    rosetta3_debug_bootstrap_from_argv((argc > 0) ? argv[0] : nullptr);

    /* Try binary directory first, then CWD */
    std::string path = (argc > 0) ? config_path_from_argv(argv[0]) : "";
    TomlConfig config;

    if (!path.empty() && config.load(path)) {
        width  = (int)config.get_int("window", "width",  width);
        height = (int)config.get_int("window", "height", height);
        gdi    = (int)config.get_int("window", "gdi",    gdi);
        title  = config.get_string("window", "title",  title);
    } else if (config.load("game.toml")) {
        width  = (int)config.get_int("window", "width",  width);
        height = (int)config.get_int("window", "height", height);
        gdi    = (int)config.get_int("window", "gdi",    gdi);
        title  = config.get_string("window", "title",  title);
    }

    if (gdi) {
        rosetta_gdi_window_run(width, height, title.c_str(),
                                game_entry, nullptr);
    } else {
        rosetta_window_run(width, height, game_entry, nullptr);
    }
    return 0;
}
