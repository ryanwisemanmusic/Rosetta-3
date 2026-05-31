#include <stdio.h>
#include "win32/Zig/zig_bridge.h"

extern void rosetta3_run_tetrisx86(void);

int main() {
    printf("Rosetta 3: Launching tetrisx86 (x86 ASM translated to Zig)...\n");
    rosetta3_run_tetrisx86();
    return 0;
}
