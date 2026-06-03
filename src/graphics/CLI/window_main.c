#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <termios.h>
#include <unistd.h>
#include <fcntl.h>
#include <game/debug_runtime.h>
static struct termios oldt;

void rosetta3_cli_init() {
    // Set terminal to raw mode
    tcgetattr(STDIN_FILENO, &oldt);
    struct termios newt = oldt;
    newt.c_lflag &= ~(ICANON | ECHO);
    tcsetattr(STDIN_FILENO, TCSANOW, &newt);
    
    int flags = fcntl(STDIN_FILENO, F_GETFL, 0);
    fcntl(STDIN_FILENO, F_SETFL, flags | O_NONBLOCK);
    
    // Hide cursor
    printf("\x1b[?25l");
    fflush(stdout);
}

void rosetta3_cli_deinit() {
    tcsetattr(STDIN_FILENO, TCSANOW, &oldt);
    
    // Show cursor
    printf("\x1b[?25h");
    fflush(stdout);
}

int rosetta3_cli_get_key() {
    unsigned char ch;
    if (read(STDIN_FILENO, &ch, 1) > 0) {
        return (int)ch;
    }
    return -1;
}

void rosetta3_cli_clear() {
    printf("\x1b[2J\x1b[H");
    fflush(stdout);
}

void rosetta3_cli_move_cursor(int x, int y) {
    printf("\x1b[%d;%dH", y + 1, x + 1);
    fflush(stdout);
}

void rosetta3_cli_write_byte(unsigned char byte) {
    putchar(byte);
    fflush(stdout);
}

void rosetta3_cli_write_text(const char *text, int len) {
    fwrite(text, 1, (size_t)len, stdout);
    fflush(stdout);
}

bool rosetta3_gfx_scene_is_available(void) {
    return 0;
}

void rosetta3_gfx_scene_set_canvas_size(unsigned int width, unsigned int height) {
    (void)width;
    (void)height;
}

unsigned int rosetta3_gfx_scene_get_canvas_width(void) {
    return 0;
}

unsigned int rosetta3_gfx_scene_get_canvas_height(void) {
    return 0;
}

void rosetta3_gfx_scene_clear(void) {
}

void rosetta3_gfx_scene_fill_rect(int x, int y, int width, int height, unsigned int color) {
    (void)x;
    (void)y;
    (void)width;
    (void)height;
    (void)color;
}

void rosetta3_gfx_scene_stroke_rect(int x, int y, int width, int height, int thickness, unsigned int color) {
    (void)x;
    (void)y;
    (void)width;
    (void)height;
    (void)thickness;
    (void)color;
}

void rosetta3_gfx_scene_draw_text(int x, int y, unsigned int fg_color, unsigned int bg_color, const unsigned char *text_ptr, unsigned int len) {
    (void)x;
    (void)y;
    (void)fg_color;
    (void)bg_color;
    (void)text_ptr;
    (void)len;
}

unsigned int rosetta3_gfx_scene_rect_count(void) {
    return 0;
}

unsigned int rosetta3_gfx_scene_text_count(void) {
    return 0;
}

bool rosetta3_gfx_scene_get_rect(unsigned int index, void *out_rect) {
    (void)index;
    (void)out_rect;
    return 0;
}

bool rosetta3_gfx_scene_get_text(unsigned int index, void *out_text) {
    (void)index;
    (void)out_text;
    return 0;
}
