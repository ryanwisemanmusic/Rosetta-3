const std = @import("std");
const testing = std.testing;
const Executor = @import("instruction_operations.zig").Executor;

/// Rosetta 3 currently has two practical stack layouts at the host boundary:
/// `raw_args` is used by the current direct import dispatch path where ESP points
/// at the first argument, while `stdcall` matches a normal x86 call frame where
/// [ESP] is the return address and [ESP + 4] is the first argument.
pub const StackLayout = enum {
    raw_args,
    stdcall,
};

pub const CleanupMode = enum {
    none,
    caller,
    callee,
};

/// Borrowed view over an x86 call boundary so shim code can read arguments
/// without manually popping state or re-implementing cleanup rules.
pub const CallFrame = struct {
    ex: *Executor,
    arg_base: u32,
    arg_count: u32,
    return_address: ?u32,
    cleanup: CleanupMode,

    pub fn init(ex: *Executor, arg_count: u32, layout: StackLayout, cleanup: CleanupMode) CallFrame {
        return switch (layout) {
            .raw_args => .{
                .ex = ex,
                .arg_base = ex.regs.esp,
                .arg_count = arg_count,
                .return_address = null,
                .cleanup = cleanup,
            },
            .stdcall => .{
                .ex = ex,
                .arg_base = ex.regs.esp + 4,
                .arg_count = arg_count,
                .return_address = ex.mem.read32(ex.regs.esp),
                .cleanup = cleanup,
            },
        };
    }

    pub fn raw(ex: *Executor, arg_count: u32) CallFrame {
        return init(ex, arg_count, .raw_args, .callee);
    }

    pub fn stdcall(ex: *Executor, arg_count: u32) CallFrame {
        return init(ex, arg_count, .stdcall, .callee);
    }

    pub fn arg(self: CallFrame, index: u32) u32 {
        std.debug.assert(index < self.arg_count);
        return self.ex.mem.read32(self.arg_base + index * 4);
    }

    pub fn finish(self: CallFrame, eax: u32) void {
        self.ex.regs.eax = eax;
        if (self.return_address) |ret_addr| {
            self.ex.regs.eip = ret_addr;
        }

        switch (self.cleanup) {
            .none => {},
            .caller => self.ex.regs.esp = self.arg_base,
            .callee => self.ex.regs.esp = self.arg_base + self.arg_count * 4,
        }
    }
};

pub fn sleepMilliseconds(ms: u32) void {
    var ts = std.c.timespec{
        .sec = @intCast(ms / 1000),
        .nsec = @intCast((ms % 1000) * std.time.ns_per_ms),
    };
    _ = std.c.nanosleep(&ts, null);
}

test "raw call frame reads arguments from current esp and cleans them up" {
    var ex = Executor.init(std.testing.allocator, 4096);
    defer ex.deinit();

    ex.regs.esp = 1024;
    ex.push(0x22222222);
    ex.push(0x11111111);

    const frame = CallFrame.raw(&ex, 2);
    try testing.expectEqual(@as(u32, 0x11111111), frame.arg(0));
    try testing.expectEqual(@as(u32, 0x22222222), frame.arg(1));

    frame.finish(7);
    try testing.expectEqual(@as(u32, 7), ex.regs.eax);
    try testing.expectEqual(@as(u32, 1024), ex.regs.esp);
}

test "stdcall call frame preserves return address semantics" {
    var ex = Executor.init(std.testing.allocator, 4096);
    defer ex.deinit();

    ex.regs.esp = 2048;
    ex.push(0xBBBBBBBB);
    ex.push(0xAAAAAAAA);
    ex.push(0x12345678);

    const frame = CallFrame.stdcall(&ex, 2);
    try testing.expectEqual(@as(u32, 0xAAAAAAAA), frame.arg(0));
    try testing.expectEqual(@as(u32, 0xBBBBBBBB), frame.arg(1));

    frame.finish(9);
    try testing.expectEqual(@as(u32, 9), ex.regs.eax);
    try testing.expectEqual(@as(u32, 0x12345678), ex.regs.eip);
    try testing.expectEqual(@as(u32, 2048), ex.regs.esp);
}
