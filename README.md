# Rosetta 3

Apple dropping Rosetta 2 is why I am writing Rosetta 3. Losing access to this software means many developers need some alternative, however, better than where Apple left the software.

Rosetta 3 is intended to not only translate x86-64 to ARM64, but also translate various CPU instructions

Here is what is planned for the next versions of the software:

V0.03: 

- Parse .dll files correctly and convert these to their macOS equivalent.
- https://github.com/raniaferdj/Block-Puzzle : This is a simple SDL 1.2 game that I will be making sure works, since it is Windows ONLY. I also will be ensuring that through Zig, that we abide by Windows rules unless our build system explicitly builds for macOS as well, and so then we aren't locked into working with Windows software exlusively

V0.02: 

- Implement x86 games to be played via external Window instead. Since the x86 Tetris game uses color, that means only text based characters represent what the Assembly is attempting to draw.
- Ensure that Space Indvaders can be drag and dropped into the project and work. If not, that means we will need to adjust Assembly code, and then find another project to test, since we need x86 code to tranlsate consistently without having to re-modify our x86 translation layer
- Make the open source implementation of Minesweeper work.
- Ensure .exe files generated on macOS are Windows 11 compatible. This may require some proper signing, as well as ensuring the Win32 API calls get bundled into the binary in such a way where only Windows API calls get called on Windows and Cocoa calls only happen on macOS
- Flesh out the Disassembler more so that when we parse .exe files we did not create, and we can peer inside the Assembly code, to see exactly what is missing. 
- Parse .ps1 files

Progress:

[5/30/26] - With the addition of Tetris in x86 and windowed form, the biggest needed addition was .exe handling, and a Disassembler. The reason for the importance involving a Disassembler is that when we go to launch .exe files, being able to parse what is going wrong means we can find any missing Windows API calls that are not yet implemented, freeing up a considerable amount of time with trying to trace said issues. 

This marks the point in which I can release V0.01

[5/29/26] - Today I was able to get a basic Snake game to run in a Cocoa Window context, with the C++ code for the game making use of the windows.h library. This means that enough Win32 API calls were translated for a barebones Snake game to happen. It's so exciting to see where this project will next go!