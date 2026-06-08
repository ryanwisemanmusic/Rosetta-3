const std = @import("std");
const runtime_abi = @import("runtime_abi_handshake");

pub const StackAlignmentViolation = enum {
    sp_misaligned,
    ip_misaligned,
    shadow_stack_misaligned,
};

pub const ArchAlignment = struct {
    minimum: u8,
    preferred: u8,
};

pub const x86_align = ArchAlignment{ .minimum = 4, .preferred = 4 };
pub const x64_align = ArchAlignment{ .minimum = 8, .preferred = 16 };
pub const arm64_align = ArchAlignment{ .minimum = 16, .preferred = 16 };

pub fn validateStackAlignment(
    comptime domain: []const u8,
    sp: u64,
    arch_align: ArchAlignment,
) void {
    runtime_abi.common.noteValidation();
    if (arch_align.preferred > 0 and sp & (arch_align.preferred - 1) != 0) {
        runtime_abi.common.violation(
            domain,
            "sp_misaligned",
            "sp=0x{x} expected {d}-byte alignment",
            .{ sp, arch_align.preferred },
        );
    }
}

pub fn validateInstructionAlignment(
    comptime domain: []const u8,
    ip: u64,
    arch_align: ArchAlignment,
) void {
    runtime_abi.common.noteValidation();
    if (arch_align.minimum > 0 and ip & (arch_align.minimum - 1) != 0) {
        runtime_abi.common.violation(
            domain,
            "ip_misaligned",
            "ip=0x{x} expected {d}-byte alignment",
            .{ ip, arch_align.minimum },
        );
    }
}

test "validateStackAlignment passes on aligned sp" {
    validateStackAlignment("test", 0x1000, x64_align);
}

test "validateStackAlignment logs violation on misaligned sp" {
    validateStackAlignment("test", 0x1001, x64_align);
}

test "validateInstructionAlignment passes on aligned ip" {
    validateInstructionAlignment("test", 0x1000, x86_align);
}

test "validateInstructionAlignment logs violation on misaligned ip" {
    validateInstructionAlignment("test", 0x1001, x86_align);
}

test "x86 align constants" {
    try std.testing.expectEqual(@as(u8, 4), x86_align.minimum);
    try std.testing.expectEqual(@as(u8, 4), x86_align.preferred);
}

test "x64 align constants" {
    try std.testing.expectEqual(@as(u8, 8), x64_align.minimum);
    try std.testing.expectEqual(@as(u8, 16), x64_align.preferred);
}

test "arm64 align constants" {
    try std.testing.expectEqual(@as(u8, 16), arm64_align.minimum);
    try std.testing.expectEqual(@as(u8, 16), arm64_align.preferred);
}
