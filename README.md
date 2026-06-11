# Rosette

ANNOUNCEMENT [6/7/26]: THIS PROJECT AIMS FOR BROAD SYSTEMS SUPPORT THROUGH A VARIETY OF SOFTWARE TESTS, AND IS INTENDED FOR USE IN XENIA/XENIA CANARY EVENTUALLY. 

Apple dropping Rosetta 2 is why I am writing Rosette. Losing access to this software means many developers are in need of a replacement tool that integrates into current Rosetta 2 reliant projects. This framework project aims to provide support at a global level, with the aims of easy accessibility and a headache-less setup

Rosette is intended to not only translate x86/x64/DOS to ARM64, but also tackle win32 related code. Since Rosetta 2 lacks many of this functionality, Rosette aims to fix what was never delivered. 

For UNLV CS218 Students [WIP]:
This program is designed for Mac users to (eventually) run x86-64 code needed for this Assembly based class. At the moment, Version 0.04, the implementation of this feature is far from complete. This project lacks a battle-tested global shell

My aims for Rosette and CS218:
The included installer .dmg will configure your global shell to work invisibly under the hood, allowing the make command to trigger Rosette if it detects the typical x86-64 project scaffolding that is provided to CS218 students. No additional configuration should be required on your end. All x86-64 instructions are translated to ARM64 NEON. Zig is used as a means of evaluating registers before and after function calls, and after each Assembly instruction, to ensure Windows and macOS are on the same page and that the x86-64 output is what NEON also gets. 

Here is how I recommend contacting me (which is on Reddit @): u/ryanwisemanmusic :: if you are dealing with any additional problems. 