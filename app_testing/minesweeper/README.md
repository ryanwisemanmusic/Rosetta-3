# WinMine

![Minesweeper Gameplay](https://github.com/wesmar/minesweeper/raw/main/images/WinMine.jpg)

A lightweight Minesweeper clone written in pure C using the Windows API. Vector-based GDI rendering, no bitmap resources – binary is <40 KB.

---

## ⚙️ Architecture

| Aspect | Detail |
| :--- | :--- |
| **Cell encoding** | 1-byte bitmask per cell: `0x80` = mine, `0x40` = revealed, `0x1F` = visual type |
| **Flood-fill** | BFS with a circular queue sized to `cBlkMax` – each cell enqueued at most once, no overflow possible |
| **Victory check** | O(1) – compares revealed count against pre-calculated target |
| **First click** | Mine is relocated if the first click lands on one |
| **Rendering** | Pure GDI vector primitives (`Ellipse`, `Polygon`, `LineTo`) + `DrawEdge` for 3D borders |
| **Fonts** | Segoe UI Bold (general text), Segoe UI Heavy (cell numbers 1-8), Consolas Bold (LED digits) |

---

## 🔧 Technical Details

- **Grid storage:** `CHAR g_GameGrid[1600]` – max 40×40, indexed as `(y << 5) + x`
- **Flood-fill:** `FloodFillReveal()` drives a circular queue; `RevealCellRecursive()` enqueues blank neighbors rather than recursing
- **Victory:** `g_TargetRevealed = (Width * Height) - Mines`; incremented on each reveal, checked via single comparison
- **Timer:** Standard `SetTimer` at 1-second intervals, starts on first click
- **Sound:** Windows system sound aliases (`SystemExclamation` / `SystemHand`) via `PlaySound` – no embedded WAV files
- **Chording:** Middle-click or Shift+Left-click reveals all neighbors around a satisfied number

---

## 🎮 Developer Trick: XYZZY Mode

**Historical Context:** The word "XYZZY" originates from the 1970s text adventure game *Colossal Cave Adventure*, where it served as a teleportation spell. Microsoft programmers adopted this as a hidden developer mode in the original Windows Minesweeper, allowing them to test mine placement logic without guessing. This implementation preserves that tradition.

### How to Activate

1. **Hold down Shift** and type **XYZZY** (all caps)
2. **Hold down Ctrl** (or press Shift once) and move your mouse over the game grid
3. The smiley face button will change expression:
   - **Happy face** 😊 → Safe cell (no mine)
   - **Scared face** 😮 → Mine detected!

### Developer Notes

This mode was invaluable during development for:
- Verifying mine placement algorithms
- Testing flood-fill boundary conditions
- Debugging first-click mine relocation logic
- Validating victory condition calculations

**Implementation Detail:** The original 1990s version used `SetPixel(hDC, 0, 0, ...)` to change the top-left screen pixel – a technique that worked reliably on Windows 95/98 but is problematic on modern composited desktops (DWM). This version uses the smiley button state instead, which is both more visible on high-DPI displays and respects modern window compositing rules.

**Exit:** Release Shift to return to normal gameplay. The button state automatically restores to match the current game situation.

---

## 📝 Design Notes

**Zero CRT.** Links with `/NODEFAULTLIB`. A custom entry point (`WinMineEntry`) replaces the standard CRT bootstrap – it calls `GetModuleHandle` / `GetCommandLineA` / `GetStartupInfoA` directly, then exits via `ExitProcess`. String formatting is handled by hand-rolled `IntToDecStr` and `FormatTime` instead of `sprintf`. All memory is statically allocated – `g_GameGrid[1600]`, the flood-fill queue, font and brush handles – there is no `malloc` or `free` anywhere in the codebase.

**Why No-CRT Architecture Works Here:**

1. **True Zero Dependencies** – Custom entry point (`WinMineEntry`) replaces `main/WinMain`, correctly parsing command-line arguments and invoking `ExitProcess`. This eliminates the entire CRT initialization chain (thread-local storage, atexit handlers, stdio buffers), reducing binary size by ~20-30 KB.

2. **Static Memory Strategy** – All data structures are global/static buffers (`g_GameGrid[1600]`, `g_FloodQueueX[1600]`, `g_FloodQueueY[1600]`). For small games, this is a feature, not a bug:
   - **Zero heap fragmentation** – No allocator overhead or free-list management
   - **Cache locality** – Entire game state fits in ~5 KB, residing in L1 cache
   - **Instant cleanup** – OS reclaims all memory on process exit (no need for cleanup code)

3. **Hand-Rolled Utilities** – Custom implementations (`IntToDecStr`, `FormatTime`) replace `stdio.h`/`sprintf`. These are 10-20 lines of code versus pulling in 50+ KB of printf family baggage.

4. **Efficient State Encoding** – Each cell is one byte with bitmasks:
   ```c
   #define MaskBomb  0x80   // Bit 7: contains mine
   #define MaskVisit 0x40   // Bit 6: revealed
   #define MaskData  0x1F   // Bits 0-4: visual type (0-15)
   ```
   This packs mine presence, visited state, and visual representation into a single byte, maximizing cache efficiency (full 40×40 grid = 1600 bytes).

5. **GDI Resource Management** – All brushes, pens, and fonts created once at startup (`LoadGraphicsFonts`), freed together on shutdown (`ReleaseGraphicsFonts`). No per-frame allocations. Critical for avoiding GDI handle leaks that can destabilize Windows' graphics subsystem.

**Cell encoding.** Each cell is a single byte: bit 7 = mine, bit 6 = revealed, bits 0–4 = visual type (0–15). The full 40×40 grid is 1600 bytes, which fits comfortably in L1 cache.

**Flood-fill queue.** BFS uses a circular buffer sized to `cBlkMax` (1600). Each blank cell is enqueued exactly once, guarded by the visited bit (`MaskVisit`), so the queue can never overflow regardless of mine layout or grid size. The implementation avoids recursion (which would require CRT stack probing), using an iterative approach with a fixed-size queue. Frontier size in practice rarely exceeds 1000 cells even on pathological mine layouts (verified via stress testing on 30×24 grids with <10 mines).

**Double buffering.** All rendering targets a persistent back surface (`CreateCompatibleDC` + `CreateCompatibleBitmap`). The screen is updated with a single `BitBlt` per frame – no tearing or flicker on repaint or game-over reveal. The back buffer is lazily allocated on first paint and reused for the lifetime of the window, resizing only when grid dimensions change.

**Random number generation.** Uses a simple Linear Congruential Generator (LCG) with constants from *Numerical Recipes* (`1664525U * seed + 1013904223U`). Seeded once at startup via `GetTickCount64()`. Sufficient quality for mine placement; upper 16 bits are used for modulo operations to avoid short-period artifacts in low bits. For cryptographic applications this would be inadequate, but for a game it's perfect – fast, deterministic (for debugging), and requires zero external dependencies.

---

## 📦 Dependencies

Links against: `kernel32`, `user32`, `gdi32`, `winmm`, `shell32`, `comctl32`, `dwmapi`

Requires Windows XP or later. Rounded corners and Mica backdrop on Windows 11 (graceful fallback on older versions).

---

## 🔥 Download

Pre-built binaries (zero CRT dependency):

| Platform | File | Size |
| :--- | :--- | :--- |
| x86 (32-bit) | `MineSweeper_x86.exe` | 29 KB |
| x64 (64-bit) | `MineSweeper_x64.exe` | 32 KB |

[Download both → `minesweeper.zip`](https://github.com/wesmar/minesweeper/releases/download/minesweeper/minesweeper.zip)

---

## 🛠️ Building

Requires Visual Studio 2026 (2017+) with the C++ Desktop workload installed.

### Using build.ps1 (recommended)

```powershell
.\build.ps1          # Build x86 + x64, verify, clean up
.\build.ps1 -Clean   # Clean first, then rebuild
```

The script does the following:
1. Locates MSBuild via `vswhere.exe`.
2. Builds `Release|x64` and `Release|Win32` in sequence.
3. Moves the resulting executables to `bin\` as `MineSweeper_x64.exe` / `MineSweeper_x86.exe`.
4. Runs post-build CRT verification with `dumpbin /imports` – fails the build if any `msvcr*`, `ucrtbase`, or `vcruntime` dependency is detected.
5. Removes all VS intermediate and output directories (`obj`, `x64\`, `Release\`).

### Manual (Visual Studio IDE)

1. Open `WinMine.vcxproj` in Visual Studio.
2. Build – Release x86 or x64.
3. Copy the resulting `WinMine.exe` from the output directory to `bin\` manually.