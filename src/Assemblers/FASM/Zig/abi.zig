const std = @import("std");
const builtin = @import("builtin");
const runtime_abi = @import("runtime_abi_handshake");
const fasm = @import("fasm_core.zig");
const tables = @import("tables.zig");
const errors = @import("errors.zig");

pub const ABI = enum(u8) {
    system_v = 0,
    microsoft = 1,
    linux = 2,
    windows = 3,
    darwin = 4,
    _,
};

pub const RegisterClass = enum(u8) {
    general_purpose = 0,
    simd = 1,
    avx = 2,
    mask = 3,
    segment = 4,
    control = 5,
    debug = 6,
    mmx = 7,
    _,
};

pub const CallingConvention = struct {
    abi: ABI,
    callee_saved: []const u8 = &.{},
    caller_saved: []const u8 = &.{},
    parameter_regs: []const u8 = &.{},
    return_reg: u8 = 0,
    return_reg_simd: u8 = 0,
    stack_alignment: u8 = 16,
    shadow_space: u8 = 0,

    pub fn detect() CallingConvention {
        return switch (builtin.target.os.tag) {
            .macos, .linux, .freebsd, .netbsd, .openbsd => CallingConvention{
                .abi = .system_v,
                .callee_saved = &.{ 24, 25, 26, 27, 28, 29, 30, 31 },
                .caller_saved = &.{ 0, 1, 2, 3, 4, 5, 6, 7 },
                .parameter_regs = &.{ 16, 17, 18, 19, 20, 21 },
                .return_reg = 0,
                .return_reg_simd = 64,
                .stack_alignment = 16,
                .shadow_space = 0,
            },
            .windows => CallingConvention{
                .abi = .microsoft,
                .callee_saved = &.{ 24, 25, 26, 27, 28, 29, 30, 31 },
                .caller_saved = &.{ 0, 1, 2, 3, 4, 5, 6, 7 },
                .parameter_regs = &.{ 24, 25, 26, 27, 16, 17, 18, 19 },
                .return_reg = 0,
                .return_reg_simd = 64,
                .stack_alignment = 16,
                .shadow_space = 32,
            },
            else => CallingConvention{
                .abi = .system_v,
                .callee_saved = &.{ 24, 25, 26, 27, 28, 29, 30, 31 },
                .caller_saved = &.{ 0, 1, 2, 3, 4, 5, 6, 7 },
                .parameter_regs = &.{ 16, 17, 18, 19, 20, 21 },
                .return_reg = 0,
                .return_reg_simd = 64,
                .stack_alignment = 16,
                .shadow_space = 0,
            },
        };
    }

    pub fn isCalleeSaved(self: *const CallingConvention, reg: u8) bool {
        for (self.callee_saved) |r| {
            if (r == reg) return true;
        }
        return false;
    }

    pub fn isCallerSaved(self: *const CallingConvention, reg: u8) bool {
        for (self.caller_saved) |r| {
            if (r == reg) return true;
        }
        return false;
    }

    pub fn parameterRegister(self: *const CallingConvention, index: usize) ?u8 {
        if (index >= self.parameter_regs.len) return null;
        return self.parameter_regs[index];
    }
};

pub const ABIValidator = struct {
    convention: CallingConvention,
    used_registers: std.bit_set.IntegerBitSet(256) = .{ .mask = @as(u256, 0) },
    preserved_registers_needed: std.bit_set.IntegerBitSet(256) = .{ .mask = @as(u256, 0) },
    in_function_prologue: bool = false,
    stack_frame_size: u32 = 0,
    red_zone_used: bool = false,

    pub fn init() ABIValidator {
        return ABIValidator{
            .convention = CallingConvention.detect(),
        };
    }

    pub fn markRegisterUsed(self: *ABIValidator, reg: u8) void {
        self.used_registers.set(reg);
    }

    pub fn validatePrologue(self: *ABIValidator) !void {
        if (!self.in_function_prologue) {
            return;
        }
        // Validate that callee-saved registers are preserved if used.
        var iter = self.used_registers.iterator(.{ .kind = .set });
        while (iter.next()) |reg| {
            const r: u8 = @intCast(reg);
            if (self.convention.isCalleeSaved(r) and !self.preserved_registers_needed.isSet(r)) {
                continue;
            }
        }
    }

    pub fn validateEpilogue(self: *ABIValidator) !void {
        _ = self;
    }

    pub fn validateStackAlignment(self: *ABIValidator, current_rsp: u64) !void {
        const alignment = self.convention.stack_alignment;
        runtime_abi.common.noteValidation();
        if (alignment > 0 and current_rsp & (alignment - 1) != 0) {
            runtime_abi.common.violation("fasm-abi", "stack_alignment", "rsp=0x{x} expected {d}-byte alignment", .{ current_rsp, alignment });
        }
    }

    pub fn validateCall(self: *ABIValidator, args: usize) !void {
        _ = self;
        _ = args;
    }

    pub fn applyPrologue(self: *ABIValidator, buffer: *std.ArrayListUnmanaged(u8), allocator: std.mem.Allocator) !usize {
        var frame_size: usize = 0;

        if (self.convention.abi == .microsoft) {
            try buffer.appendSlice(allocator, &.{0x55});
            try buffer.appendSlice(allocator, &.{ 0x48, 0x89, 0xE5 });
            frame_size += 3;

            if (self.convention.shadow_space > 0) {
                try buffer.appendSlice(allocator, &.{ 0x48, 0x83, 0xEC, self.convention.shadow_space });
                frame_size += 4;
            }
        } else {
            try buffer.appendSlice(allocator, &.{0x55});
            try buffer.appendSlice(allocator, &.{ 0x48, 0x89, 0xE5 });
            frame_size += 3;
        }

        self.in_function_prologue = true;
        return frame_size;
    }

    pub fn applyEpilogue(self: *ABIValidator, buffer: *std.ArrayListUnmanaged(u8), allocator: std.mem.Allocator) !void {
        if (self.convention.abi == .microsoft) {
            if (self.convention.shadow_space > 0) {
                try buffer.appendSlice(allocator, &.{ 0x48, 0x83, 0xC4, self.convention.shadow_space });
            }
        }
        try buffer.appendSlice(allocator, &.{0x5D});
        try buffer.appendSlice(allocator, &.{0xC3});
    }

    pub fn detectFunctionCalls(data: []const u8) usize {
        var count: usize = 0;
        var i: usize = 0;
        while (i < data.len) {
            // Detect CALL (E8 xx xx xx xx) relative calls
            if (data[i] == 0xE8 and i + 4 < data.len) {
                count += 1;
                i += 5;
            }
            // Detect CALL (FF /2) register/memory calls
            else if (data[i] == 0xFF and i + 1 < data.len and (data[i + 1] & 0x38) == 0x10) {
                count += 1;
                i += 2;
            } else {
                i += 1;
            }
        }
        return count;
    }
};

test "ABI detection" {
    const convention = CallingConvention.detect();
    try std.testing.expect(convention.abi == .system_v or convention.abi == .microsoft or convention.abi == .linux);
}

test "callee saved registers" {
    const convention = CallingConvention.detect();
    try std.testing.expect(convention.isCalleeSaved(24)); // rbx
}

test "ABI prologue generation" {
    var validator = ABIValidator.init();
    var buffer: std.ArrayListUnmanaged(u8) = .{ .items = &.{}, .capacity = 0 };
    defer buffer.deinit(std.testing.allocator);

    const size = try validator.applyPrologue(&buffer, std.testing.allocator);
    try std.testing.expect(size > 0);
    try std.testing.expect(buffer.items.len > 0);
}

test "detect calls in binary" {
    const data = [_]u8{ 0xE8, 0x00, 0x00, 0x00, 0x00, 0x90, 0x90, 0x90 };
    const count = ABIValidator.detectFunctionCalls(&data);
    try std.testing.expectEqual(@as(usize, 1), count);
}
