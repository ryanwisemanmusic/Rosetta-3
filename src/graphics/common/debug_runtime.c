#include <game/debug_runtime.h>

#include <ctype.h>
#include <dirent.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

#ifndef PATH_MAX
#define PATH_MAX 4096
#endif

typedef struct {
    int loaded;
    int debug_enabled;
    int x86_disasm_enabled;
    int graphics_layout_enabled;
    int first_frame_dump_enabled;
    int fb_logger_enabled;
    int window_width;
    int window_height;
    unsigned int canvas_width;
    unsigned int canvas_height;
    char binary_dir[PATH_MAX];
    char project_root[PATH_MAX];
    char log_path[PATH_MAX];
    char fb_log_dir[PATH_MAX];
    char window_title[PATH_MAX];
} DebugState;

static DebugState g_debug = {
    .loaded = 0,
    .debug_enabled = 0,
    .x86_disasm_enabled = 0,
    .graphics_layout_enabled = 0,
    .first_frame_dump_enabled = 0,
    .fb_logger_enabled = 0,
    .window_width = 0,
    .window_height = 0,
    .canvas_width = 0,
    .canvas_height = 0,
    .binary_dir = "",
    .project_root = "",
    .log_path = "rosetta3-x86.log",
    .fb_log_dir = "",
    .window_title = "",
};

static char *trim_left(char *s)
{
    while (*s == ' ' || *s == '\t' || *s == '\r' || *s == '\n') s++;
    return s;
}

static void trim_right(char *s)
{
    size_t len = strlen(s);
    while (len > 0) {
        char ch = s[len - 1];
        if (ch != ' ' && ch != '\t' && ch != '\r' && ch != '\n') break;
        s[len - 1] = '\0';
        len--;
    }
}

static void copy_dir_from_argv(char *out, size_t out_len, const char *argv0)
{
    out[0] = '\0';
    if (!argv0 || argv0[0] == '\0') return;

    snprintf(out, out_len, "%s", argv0);
    char *slash = strrchr(out, '/');
    if (!slash) {
        snprintf(out, out_len, ".");
        return;
    }
    if (slash == out) {
        slash[1] = '\0';
        return;
    }
    *slash = '\0';
}

static void copy_parent_dir(char *path)
{
    char *slash = strrchr(path, '/');
    if (!slash) {
        snprintf(path, PATH_MAX, ".");
        return;
    }
    if (slash == path) {
        path[1] = '\0';
        return;
    }
    *slash = '\0';
}

static void discover_project_root(void)
{
    if (g_debug.binary_dir[0] == '\0') return;

    char candidate[PATH_MAX];
    snprintf(candidate, sizeof(candidate), "%s", g_debug.binary_dir);
    while (candidate[0] != '\0') {
        char graphics_path[PATH_MAX];
        char build_path[PATH_MAX];
        snprintf(graphics_path, sizeof(graphics_path), "%s/src/graphics", candidate);
        snprintf(build_path, sizeof(build_path), "%s/build", candidate);
        if (access(graphics_path, F_OK) == 0 && access(build_path, F_OK) == 0) {
            snprintf(g_debug.project_root, sizeof(g_debug.project_root), "%s", candidate);
            return;
        }

        if (strcmp(candidate, "/") == 0 || strcmp(candidate, ".") == 0) break;
        copy_parent_dir(candidate);
    }
}

static void resolve_log_path(const char *value)
{
    if (!value || value[0] == '\0') return;

    if (value[0] == '/') {
        snprintf(g_debug.log_path, sizeof(g_debug.log_path), "%s", value);
        return;
    }

    if (g_debug.binary_dir[0] != '\0') {
        snprintf(g_debug.log_path, sizeof(g_debug.log_path), "%s/%s", g_debug.binary_dir, value);
        return;
    }

    snprintf(g_debug.log_path, sizeof(g_debug.log_path), "%s", value);
}

static void resolve_fb_log_dir(const char *value)
{
    if (!value || value[0] == '\0') return;

    if (value[0] == '/') {
        snprintf(g_debug.fb_log_dir, sizeof(g_debug.fb_log_dir), "%s", value);
        return;
    }

    if (g_debug.project_root[0] != '\0') {
        snprintf(g_debug.fb_log_dir, sizeof(g_debug.fb_log_dir), "%s/%s", g_debug.project_root, value);
        return;
    }

    if (g_debug.binary_dir[0] != '\0') {
        snprintf(g_debug.fb_log_dir, sizeof(g_debug.fb_log_dir), "%s/%s", g_debug.binary_dir, value);
        return;
    }

    snprintf(g_debug.fb_log_dir, sizeof(g_debug.fb_log_dir), "%s", value);
}

static int parse_bool_value(const char *value, int fallback)
{
    if (!value || value[0] == '\0') return fallback;
    if (strcmp(value, "true") == 0) return 1;
    if (strcmp(value, "false") == 0) return 0;
    if (isdigit((unsigned char)value[0]) || value[0] == '-' || value[0] == '+') {
        return atoi(value) != 0;
    }
    return fallback;
}

static void apply_debug_key(const char *key, const char *value)
{
    if (strcmp(key, "enabled") == 0) {
        g_debug.debug_enabled = parse_bool_value(value, g_debug.debug_enabled);
    } else if (strcmp(key, "x86_disasm") == 0) {
        g_debug.x86_disasm_enabled = parse_bool_value(value, g_debug.x86_disasm_enabled);
    } else if (strcmp(key, "graphics_layout") == 0) {
        g_debug.graphics_layout_enabled = parse_bool_value(value, g_debug.graphics_layout_enabled);
    } else if (strcmp(key, "first_frame_dump") == 0) {
        g_debug.first_frame_dump_enabled = parse_bool_value(value, g_debug.first_frame_dump_enabled);
    } else if (strcmp(key, "log_file") == 0) {
        char buf[PATH_MAX];
        snprintf(buf, sizeof(buf), "%s", value);
        trim_right(buf);
        size_t len = strlen(buf);
        if (len >= 2 && buf[0] == '"' && buf[len - 1] == '"') {
            buf[len - 1] = '\0';
            resolve_log_path(buf + 1);
        } else {
            resolve_log_path(buf);
        }
    } else if (strcmp(key, "framebuffer_logger") == 0) {
        g_debug.fb_logger_enabled = parse_bool_value(value, g_debug.fb_logger_enabled);
    } else if (strcmp(key, "framebuffer_log_dir") == 0) {
        char buf[PATH_MAX];
        snprintf(buf, sizeof(buf), "%s", value);
        trim_right(buf);
        size_t len = strlen(buf);
        if (len >= 2 && buf[0] == '"' && buf[len - 1] == '"') {
            buf[len - 1] = '\0';
            resolve_fb_log_dir(buf + 1);
        } else {
            resolve_fb_log_dir(buf);
        }
    }
}

static void apply_window_key(const char *key, const char *value)
{
    if (strcmp(key, "width") == 0) {
        g_debug.window_width = atoi(value);
    } else if (strcmp(key, "height") == 0) {
        g_debug.window_height = atoi(value);
    } else if (strcmp(key, "canvas_width") == 0) {
        g_debug.canvas_width = (unsigned int)strtoul(value, NULL, 10);
    } else if (strcmp(key, "canvas_height") == 0) {
        g_debug.canvas_height = (unsigned int)strtoul(value, NULL, 10);
    } else if (strcmp(key, "title") == 0) {
        char buf[PATH_MAX];
        snprintf(buf, sizeof(buf), "%s", value);
        trim_right(buf);
        size_t len = strlen(buf);
        if (len >= 2 && buf[0] == '"' && buf[len - 1] == '"') {
            buf[len - 1] = '\0';
            snprintf(g_debug.window_title, sizeof(g_debug.window_title), "%s", buf + 1);
        } else {
            snprintf(g_debug.window_title, sizeof(g_debug.window_title), "%s", buf);
        }
    }
}

static void load_debug_toml(const char *path)
{
    FILE *fp = fopen(path, "r");
    if (!fp) return;

    char section[64] = "";
    char line[1024];
    while (fgets(line, sizeof(line), fp)) {
        char *s = trim_left(line);
        trim_right(s);
        if (s[0] == '\0' || s[0] == '#') continue;

        if (s[0] == '[') {
            char *end = strchr(s, ']');
            if (!end) continue;
            *end = '\0';
            snprintf(section, sizeof(section), "%s", trim_left(s + 1));
            trim_right(section);
            continue;
        }

        char *eq = strchr(s, '=');
        if (!eq) continue;
        *eq = '\0';

        char *key = trim_left(s);
        trim_right(key);
        char *value = trim_left(eq + 1);
        trim_right(value);

        if (strcmp(section, "debug") == 0 || strcmp(section, "global") == 0) {
            apply_debug_key(key, value);
        } else if (strcmp(section, "window") == 0) {
            apply_window_key(key, value);
        }
    }

    fclose(fp);
}

static void apply_env_fallbacks(void)
{
    const char *gdi_verbose = getenv("GDI_VERBOSE");
    if (gdi_verbose && gdi_verbose[0] != '\0') {
        g_debug.debug_enabled = 1;
        g_debug.x86_disasm_enabled = 1;
    }

    const char *gfx_debug = getenv("ROSETTA3_GRAPHICS_DEBUG");
    if (gfx_debug && gfx_debug[0] != '\0') {
        g_debug.debug_enabled = 1;
        g_debug.graphics_layout_enabled = 1;
    }

    const char *frame_dump = getenv("ROSETTA3_FIRST_FRAME_DUMP");
    if (frame_dump && frame_dump[0] != '\0') {
        g_debug.debug_enabled = 1;
        g_debug.first_frame_dump_enabled = 1;
    }

    const char *log_path = getenv("GDI_LOG_PATH");
    if (log_path && log_path[0] != '\0') {
        resolve_log_path(log_path);
    }

    const char *fb_enabled = getenv("ROSETTA3_FB_LOGGER");
    if (fb_enabled && fb_enabled[0] != '\0') {
        g_debug.fb_logger_enabled = parse_bool_value(fb_enabled, g_debug.fb_logger_enabled);
    }

    const char *fb_dir = getenv("ROSETTA3_FB_LOG_DIR");
    if (fb_dir && fb_dir[0] != '\0') {
        resolve_fb_log_dir(fb_dir);
    }
}

static void touch_log_file(void)
{
    if (!g_debug.debug_enabled || g_debug.log_path[0] == '\0') return;
    FILE *fp = fopen(g_debug.log_path, "a");
    if (!fp) return;
    fclose(fp);
}

static void ensure_directory(const char *path)
{
    if (!path || path[0] == '\0') return;
    if (mkdir(path, 0755) != 0 && errno != EEXIST) return;
}

static void clear_fb_log_dir(void)
{
    if (!g_debug.fb_logger_enabled || g_debug.fb_log_dir[0] == '\0') return;
    ensure_directory(g_debug.fb_log_dir);

    DIR *dir = opendir(g_debug.fb_log_dir);
    if (!dir) return;

    struct dirent *ent;
    while ((ent = readdir(dir)) != NULL) {
        if (ent->d_name[0] == '.') continue;
        const char *ext = strrchr(ent->d_name, '.');
        if (!ext) continue;
        if (strcmp(ext, ".jpg") != 0 && strcmp(ext, ".jpeg") != 0) continue;

        char full[PATH_MAX];
        snprintf(full, sizeof(full), "%s/%s", g_debug.fb_log_dir, ent->d_name);
        unlink(full);
    }

    closedir(dir);
}

void rosetta3_debug_bootstrap_from_argv(const char *argv0)
{
    if (g_debug.loaded) return;
    g_debug.loaded = 1;

    copy_dir_from_argv(g_debug.binary_dir, sizeof(g_debug.binary_dir), argv0);
    discover_project_root();
    if (g_debug.project_root[0] != '\0') {
        resolve_fb_log_dir("src/graphics/fb-logger/log");
    }
    if (g_debug.binary_dir[0] != '\0' && strcmp(g_debug.binary_dir, ".") != 0) {
        char path[PATH_MAX];
        snprintf(path, sizeof(path), "%s/game.toml", g_debug.binary_dir);
        load_debug_toml(path);
    } else {
        load_debug_toml("game.toml");
    }

    apply_env_fallbacks();
    if (g_debug.binary_dir[0] != '\0' && strchr(g_debug.log_path, '/') == NULL) {
        resolve_log_path(g_debug.log_path);
    }
    clear_fb_log_dir();
    touch_log_file();
}

int rosetta3_debug_enabled(void)
{
    return g_debug.debug_enabled;
}

int rosetta3_debug_x86_disasm_enabled(void)
{
    return g_debug.debug_enabled && g_debug.x86_disasm_enabled;
}

int rosetta3_debug_graphics_enabled(void)
{
    return g_debug.debug_enabled && g_debug.graphics_layout_enabled;
}

int rosetta3_debug_first_frame_dump_enabled(void)
{
    return g_debug.debug_enabled && g_debug.first_frame_dump_enabled;
}

const char *rosetta3_debug_log_path(void)
{
    return g_debug.log_path;
}

int rosetta3_fb_logger_enabled(void)
{
    return g_debug.fb_logger_enabled;
}

const char *rosetta3_fb_logger_directory(void)
{
    return g_debug.fb_log_dir;
}

int rosetta3_window_width_or(int default_value)
{
    return g_debug.window_width > 0 ? g_debug.window_width : default_value;
}

int rosetta3_window_height_or(int default_value)
{
    return g_debug.window_height > 0 ? g_debug.window_height : default_value;
}

unsigned int rosetta3_canvas_width_or(unsigned int default_value)
{
    return g_debug.canvas_width > 0 ? g_debug.canvas_width : default_value;
}

unsigned int rosetta3_canvas_height_or(unsigned int default_value)
{
    return g_debug.canvas_height > 0 ? g_debug.canvas_height : default_value;
}

const char *rosetta3_window_title_or(const char *default_value)
{
    return g_debug.window_title[0] != '\0' ? g_debug.window_title : default_value;
}
