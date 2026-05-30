#include <stdio.h>
#include "win32/Zig/zig_bridge.h"

// This will be exported from our Zig implementation
extern void rosetta3_run_snax86(void);

int main() {
    printf("Rosetta 3: Launching snax86 (x86 ASM translated to Zig)...\n");
    rosetta3_run_snax86();
    return 0;
}
