const std = @import("std");
const builtin = @import("builtin");
const jwasm = @import("jwasm_core.zig");

pub const CallingConvention = struct {
    abi: ABI,
    language: jwasm.lang_type,

    const ABI = enum(u8) {
        system_v = 0,
        microsoft = 1,
        c = 2,
        pascal = 3,
        fortran = 4,
        basic = 5,
        fastcall = 6,
        _,
    };

    pub fn detect() CallingConvention {
        const detected_abi: ABI = switch (builtin.target.os.tag) {
            .macos, .linux, .freebsd => .system_v,
            .windows => .microsoft,
            else => .system_v,
        };
        const lang: jwasm.lang_type = switch (detected_abi) {
            .microsoft => .c,
            .system_v => .c,
            else => .c,
        };
        return CallingConvention{ .abi = detected_abi, .language = lang };
    }

    pub fn parameterRegister(self: *const CallingConvention, index: usize) ?u8 {
        return switch (self.abi) {
            .system_v => switch (index) {
                0 => 16,
                1 => 17,
                2 => 18,
                3 => 19,
                4 => 8,
                5 => 9,
                else => null,
            },
            .microsoft => switch (index) {
                0 => 19,
                1 => 18,
                2 => 8,
                3 => 9,
                else => null,
            },
            .fastcall => switch (index) {
                0 => 19,
                1 => 18,
                else => null,
            },
            else => null,
        };
    }

    pub fn returnRegister(self: *const CallingConvention) u8 {
        _ = self;
        return 0;
    }

    pub fn isRegisterBased(self: *const CallingConvention) bool {
        return switch (self.abi) {
            .system_v, .microsoft, .fastcall => true,
            else => false,
        };
    }
};

pub const JwasmModelProcs = struct {
    abi: CallingConvention,

    pub fn generateStartup(self: *const JwasmModelProcs, model: jwasm.model_type, buffer: *std.ArrayListUnmanaged(u8), allocator: std.mem.Allocator) !void {
        _ = model;
        _ = buffer;
        _ = allocator;
        _ = self;
    }

    pub fn generateExit(self: *const JwasmModelProcs, buffer: *std.ArrayListUnmanaged(u8), allocator: std.mem.Allocator) !void {
        _ = buffer;
        _ = allocator;
        _ = self;
    }
};

pub const JwasmAbiValidator = struct {
    convention: CallingConvention,
    model: jwasm.model_type,
    use32: bool = false,
    use64: bool = false,
    far_calls: bool = false,
    far_returns: bool = false,
    stack_frame_size: u32 = 0,
    has_prologue: bool = false,
    lang: jwasm.lang_type = .none,

    pub fn init(model: jwasm.model_type, lang: jwasm.lang_type, use32: bool) JwasmAbiValidator {
        const far = switch (model) {
            .medium, .large, .huge => true,
            else => false,
        };
        const abi_type: CallingConvention.ABI = switch (lang) {
            .c => if (use32) .microsoft else .system_v,
            .pascal => .pascal,
            .fortran => .fortran,
            .basic => .basic,
            .stdcall => .microsoft,
            .fastcall => .fastcall,
            else => .system_v,
        };
        return JwasmAbiValidator{
            .convention = CallingConvention{ .abi = abi_type, .language = lang },
            .model = model,
            .use32 = use32,
            .far_calls = far,
            .lang = lang,
        };
    }

    pub fn initFull(model: jwasm.model_type, lang: jwasm.lang_type, use32: bool, use64: bool) JwasmAbiValidator {
        var v = JwasmAbiValidator.init(model, lang, use32);
        v.use64 = use64;
        return v;
    }

    pub fn needsFarReturn(self: *const JwasmAbiValidator) bool {
        return self.far_calls;
    }

    pub fn prologueSize(self: *const JwasmAbiValidator) u32 {
        _ = self;
        return 0;
    }

    pub fn validateInvoke(self: *const JwasmAbiValidator, arg_count: usize, buffer: *std.ArrayListUnmanaged(u8), allocator: std.mem.Allocator) !usize {
        _ = buffer;
        _ = allocator;
        _ = self;
        _ = arg_count;
        return 0;
    }
};

pub fn getLanguageSuffix(lang: jwasm.lang_type) []const u8 {
    return switch (lang) {
        .c => "_c",
        .pascal => "_pascal",
        .fortran => "_fortran",
        .basic => "_basic",
        .syscall => "_syscall",
        .stdcall => "_stdcall",
        .fastcall => "_fastcall",
        else => "",
    };
}

pub fn getStdcallDecoration(name: []const u8, param_bytes: u32) ![]const u8 {
    var result = std.ArrayList(u8).init(std.heap.page_allocator);
    try result.appendSlice(name);
    try result.append('@');
    try std.fmt.format(result.writer(), "{d}", .{param_bytes});
    return result.items;
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

test "fastcall parameter registers" {
    const cc = CallingConvention{ .abi = .fastcall, .language = .fastcall };
    try std.testing.expectEqual(@as(u8, 19), cc.parameterRegister(0).?);
    try std.testing.expectEqual(@as(u8, 18), cc.parameterRegister(1).?);
    try std.testing.expect(cc.parameterRegister(2) == null);
}

test "ABI validator far calls" {
    const v = JwasmAbiValidator.init(.large, .c, false);
    try std.testing.expect(v.needsFarReturn());
}

test "ABI validator flat mode" {
    const v = JwasmAbiValidator.initFull(.flat, .c, true, false);
    try std.testing.expect(!v.needsFarReturn());
}

test "language suffixes" {
    try std.testing.expectEqualStrings("_c", getLanguageSuffix(.c));
    try std.testing.expectEqualStrings("_stdcall", getLanguageSuffix(.stdcall));
    try std.testing.expectEqualStrings("_fastcall", getLanguageSuffix(.fastcall));
}

test "register based calling convention detection" {
    const cc = CallingConvention{ .abi = .system_v, .language = .c };
    try std.testing.expect(cc.isRegisterBased());
}
