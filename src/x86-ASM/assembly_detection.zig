const std = @import("std");

pub const AssemblerFamily = enum {
    unknown,
    masm,
    irvine32_masm,
    nasm,
    yasm,
    fasm,
    aasm,
};

pub const RuntimeProfile = enum {
    unknown,
    dos_text_mode,
    irvine32_text_mode,
    win32_block_window,
};

pub const DetectedProfile = struct {
    assembler: AssemblerFamily = .unknown,
    runtime: RuntimeProfile = .unknown,
    uses_dos_interrupts: bool = false,
    uses_win32_api: bool = false,
};

pub fn detectSourceProfile(source: []const u8) DetectedProfile {
    const lower = source;

    const has_irvine = containsIgnoreCase(lower, "irvine32.inc") or
        containsIgnoreCase(lower, "readkey") or
        containsIgnoreCase(lower, "writestring") or
        containsIgnoreCase(lower, "gotoxy");
    const has_masm = containsIgnoreCase(lower, ".model") or
        containsIgnoreCase(lower, "proto stdcall") or
        containsIgnoreCase(lower, "includelib");
    const has_nasm = containsIgnoreCase(lower, "global _start") or
        containsIgnoreCase(lower, "section .text");
    const has_yasm_linux_elf64 = has_nasm and
        (containsIgnoreCase(lower, "syscall") or
            containsIgnoreCase(lower, "SYS_exit") or
            containsIgnoreCase(lower, "SYS_read") or
            containsIgnoreCase(lower, "SYS_write")) and
        (containsIgnoreCase(lower, "Assignment:") or
            containsIgnoreCase(lower, "Assignment #"));
    const has_fasm = containsIgnoreCase(lower, "format pe") or
        containsIgnoreCase(lower, "format mz");
    const has_aasm = containsIgnoreCase(lower, "aasm");
    const has_dos_interrupts = containsIgnoreCase(lower, "int 10h") or
        containsIgnoreCase(lower, "int 21h") or
        containsIgnoreCase(lower, "int 16h") or
        containsIgnoreCase(lower, "int 15h");
    const has_win32_api = containsIgnoreCase(lower, "registerclassexa") or
        containsIgnoreCase(lower, "createwindowexa") or
        containsIgnoreCase(lower, "drawtexta") or
        containsIgnoreCase(lower, "setpixel");

    var profile = DetectedProfile{
        .uses_dos_interrupts = has_dos_interrupts,
        .uses_win32_api = has_win32_api,
    };

    profile.assembler = if (has_irvine) .irvine32_masm else if (has_masm) .masm else if (has_yasm_linux_elf64) .yasm else if (has_nasm) .nasm else if (has_fasm) .fasm else if (has_aasm) .aasm else .unknown;

    profile.runtime = if (has_irvine and containsIgnoreCase(lower, "level1row1"))
        .irvine32_text_mode
    else if (has_win32_api and containsIgnoreCase(lower, "gridcolors") and containsIgnoreCase(lower, "activecolorindex"))
        .win32_block_window
    else if (has_dos_interrupts)
        .dos_text_mode
    else
        .unknown;

    return profile;
}

fn containsIgnoreCase(haystack: []const u8, needle: []const u8) bool {
    return std.ascii.indexOfIgnoreCase(haystack, needle) != null;
}

test "detect irvine32 text mode" {
    const sample =
        \\INCLUDE Irvine32.inc
        \\intro1 BYTE "Hello", 0
        \\Level1Row1 BYTE "#####", 0
        \\call WriteString
    ;
    const profile = detectSourceProfile(sample);
    try std.testing.expectEqual(AssemblerFamily.irvine32_masm, profile.assembler);
    try std.testing.expectEqual(RuntimeProfile.irvine32_text_mode, profile.runtime);
}

test "detect dos text mode" {
    const sample =
        \\PrintText Macro row, column, text
        \\int 10h
        \\int 21h
    ;
    const profile = detectSourceProfile(sample);
    try std.testing.expectEqual(RuntimeProfile.dos_text_mode, profile.runtime);
    try std.testing.expect(profile.uses_dos_interrupts);
}

test "detect assignment-style YASM source" {
    const sample =
        \\; Assignment #1
        \\section .text
        \\global _start
        \\_start:
        \\  mov rax, SYS_exit
        \\  syscall
    ;
    const profile = detectSourceProfile(sample);
    try std.testing.expectEqual(AssemblerFamily.yasm, profile.assembler);
}
