const std = @import("std");
const builtin = @import("builtin");
const masm = @import("masm_core.zig");

pub const CallingConvention = struct {
    abi: ABI,
    language: masm.ModelLanguage,

    const ABI = enum(u8) {
        system_v = 0,
        microsoft = 1,
        c = 2,
        pascal = 3,
        fortran = 4,
        basic = 5,
        _,
    };

    pub fn detect() CallingConvention {
        const abi: ABI = switch (builtin.target.os.tag) {
            .macos, .linux, .freebsd => .system_v,
            .windows => .microsoft,
            else => .system_v,
        };
        const lang: masm.ModelLanguage = switch (abi) {
            .microsoft => .c,
            .system_v => .c,
            else => .c,
        };
        return CallingConvention{ .abi = abi, .language = lang };
    }

    pub fn parameterRegister(self: *const CallingConvention, index: usize) ?u8 {
        return switch (self.abi) {
            .system_v => switch (index) {
                0 => 16, // rdi
                1 => 17, // rsi
                2 => 18, // rdx
                3 => 19, // rcx
                4 => 8,  // r8
                5 => 9,  // r9
                else => null,
            },
            .microsoft => switch (index) {
                0 => 19, // rcx
                1 => 18, // rdx
                2 => 8,  // r8
                3 => 9,  // r9
                else => null,
            },
            else => null,
        };
    }

    pub fn returnRegister(self: *const CallingConvention) u8 {
        return switch (self.abi) {
            .system_v, .microsoft => 0, // rax
            else => 0,
        };
    }
};

pub const MasmModelProcs = struct {
    abi: CallingConvention,

    pub fn generateStartup(self: *const MasmModelProcs, model: masm.MemoryModel, buffer: *std.ArrayListUnmanaged(u8), allocator: std.mem.Allocator) !void {
        _ = model;
        _ = buffer;
        _ = allocator;
        _ = self;
    }

    pub fn generateExit(self: *const MasmModelProcs, buffer: *std.ArrayListUnmanaged(u8), allocator: std.mem.Allocator) !void {
        _ = buffer;
        _ = allocator;
        _ = self;
    }
};

pub const MasmAbiValidator = struct {
    convention: CallingConvention,
    model: masm.MemoryModel,
    use32: bool = false,
    far_calls: bool = false,
    far_returns: bool = false,
    stack_frame_size: u32 = 0,
    has_prologue: bool = false,

    pub fn init(model: masm.MemoryModel, lang: masm.ModelLanguage, use32: bool) MasmAbiValidator {
        return MasmAbiValidator{
            .convention = CallingConvention{
                .abi = if (use32) .microsoft else .system_v,
                .language = lang,
            },
            .model = model,
            .use32 = use32,
            .far_calls = model == .medium or model == .large or model == .huge,
        };
    }

    pub fn needsFarReturn(self: *const MasmAbiValidator) bool {
        return self.far_calls;
    }

    pub fn prologueSize(self: *const MasmAbiValidator) u32 {
        _ = self;
        return 0;
    }

    pub fn validateInvoke(self: *const MasmAbiValidator, arg_count: usize, buffer: *std.ArrayListUnmanaged(u8), allocator: std.mem.Allocator) !usize {
        _ = buffer;
        _ = allocator;
        _ = self;
        _ = arg_count;
        return 0;
    }
};

pub fn getLanguageSuffix(lang: masm.ModelLanguage) []const u8 {
    return switch (lang) {
        .c => "_c",
        .pascal => "_pascal",
        .fortran => "_fortran",
        .basic => "_basic",
        .syscall => "_syscall",
        .stdcall => "_stdcall",
        else => "",
    };
}

test "calling convention detection" {
    const cc = CallingConvention.detect();
    try std.testing.expect(cc.abi == .system_v or cc.abi == .microsoft);
}

test "parameter registers SysV" {
    const cc = CallingConvention{ .abi = .system_v, .language = .c };
    try std.testing.expectEqual(@as(u8, 16), cc.parameterRegister(0).?);
}

test "parameter registers MS" {
    const cc = CallingConvention{ .abi = .microsoft, .language = .c };
    try std.testing.expectEqual(@as(u8, 19), cc.parameterRegister(0).?);
}

test "ABI validator far calls" {
    const v = MasmAbiValidator.init(.large, .c, false);
    try std.testing.expect(v.needsFarReturn());
}

test "language suffixes" {
    try std.testing.expectEqualStrings("_c", getLanguageSuffix(.c));
    try std.testing.expectEqualStrings("_stdcall", getLanguageSuffix(.stdcall));
}
