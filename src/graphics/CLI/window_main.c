#include <stdio.h>
#include <stdlib.h>
#include <termios.h>
#include <unistd.h>
#include <fcntl.h>

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
