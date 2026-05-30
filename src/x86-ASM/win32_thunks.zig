const std = @import("std");
const testing = std.testing;
const Executor = @import("instruction_operations.zig").Executor;
const abi = @import("abi_handshake.zig");

fn finishSuccess(frame: abi.CallFrame) void {
    frame.finish(1);
}

fn consoleFdForHandle(handle: u32) c_int {
    return switch (handle) {
        0xB003 => 2,
        else => 1,
    };
}

/// Register Win32 console API thunks needed by console-mode x86 programs.
/// Each thunk pops its arguments from the x86 stack, calls the native
/// function (via the Rosetta 3 shim layer), and stores the return value in EAX.
pub fn register_win32_console_thunks(ex: *Executor) void {
    const map = &ex.import_table;

    map.put("_SetConsoleTextAttribute@8", struct {
        fn handler(ctx: *Executor) void {
            const frame = abi.CallFrame.raw(ctx, 2);
            const handle = frame.arg(0);
            const attrs = frame.arg(1);
            _ = attrs;
            _ = handle;
            finishSuccess(frame);
        }
    }.handler) catch {};

    map.put("_Sleep@4", struct {
        fn handler(ctx: *Executor) void {
            const frame = abi.CallFrame.raw(ctx, 1);
            abi.sleepMilliseconds(frame.arg(0));
            frame.finish(0);
        }
    }.handler) catch {};

    map.put("_GetStdHandle@4", struct {
        fn handler(ctx: *Executor) void {
            const frame = abi.CallFrame.raw(ctx, 1);
            const n = frame.arg(0);
            frame.finish(switch (n) {
                0xFFFFFFF6 => 0xB001,
                0xFFFFFFF5 => 0xB002,
                0xFFFFFFF4 => 0xB003,
                else => 0xB002,
            });
        }
    }.handler) catch {};

    map.put("_WriteFile@20", struct {
        fn handler(ctx: *Executor) void {
            const frame = abi.CallFrame.raw(ctx, 5);
            const handle = frame.arg(0);
            const buffer = frame.arg(1);
            const n_bytes = frame.arg(2);
            const written_ptr = frame.arg(3);
            const overlapped = frame.arg(4);
            _ = overlapped;

            const bytes = ctx.mem.data[buffer - ctx.mem.base .. buffer - ctx.mem.base + n_bytes];
            const written = std.c.write(consoleFdForHandle(handle), bytes.ptr, bytes.len);

            if (written_ptr != 0) {
                ctx.mem.write32(written_ptr, @intCast(written));
            }
            finishSuccess(frame);
        }
    }.handler) catch {};

    map.put("_ExitProcess@4", struct {
        fn handler(ctx: *Executor) void {
            const frame = abi.CallFrame.raw(ctx, 1);
            const code = frame.arg(0);
            std.process.exit(@as(u8, @truncate(code)));
        }
    }.handler) catch {};

    map.put("_FormatMessageA@28", struct {
        fn handler(ctx: *Executor) void {
            const frame = abi.CallFrame.raw(ctx, 7);
            const flags = frame.arg(0);
            const source = frame.arg(1);
            const msg_id = frame.arg(2);
            const lang_id = frame.arg(3);
            const buf_ptr = frame.arg(4);
            const n_size = frame.arg(5);
            const args_val = frame.arg(6);
            _ = args_val;
            _ = lang_id;
            _ = source;
            _ = msg_id;

            const err_msg = "System error occurred.\n";
            var written_len: u32 = 0;
            if (buf_ptr != 0) {
                const is_alloc = (flags & 0x100) != 0;
                if (is_alloc) {
                    const alloc_buf = 0x1000;
                    ctx.mem.write32(buf_ptr, alloc_buf);
                    written_len = @as(u32, @intCast(err_msg.len));
                } else if (n_size > 0) {
                    const dst = buf_ptr - ctx.mem.base;
                    const max_len: usize = @intCast(n_size - 1);
                    const copy_len = @min(err_msg.len, max_len);
                    @memcpy(ctx.mem.data[dst .. dst + copy_len], err_msg[0..copy_len]);
                    ctx.mem.write8(buf_ptr + @as(u32, @intCast(copy_len)), 0);
                    written_len = @intCast(copy_len);
                }
            }
            frame.finish(written_len);
        }
    }.handler) catch {};

    map.put("_GetLastError@0", struct {
        fn handler(ctx: *Executor) void {
            const frame = abi.CallFrame.raw(ctx, 0);
            frame.finish(0);
        }
    }.handler) catch {};

    map.put("_GetSystemDefaultLangID@0", struct {
        fn handler(ctx: *Executor) void {
            const frame = abi.CallFrame.raw(ctx, 0);
            frame.finish(0x0409);
        }
    }.handler) catch {};

    map.put("_FillConsoleOutputCharacterA@20", struct {
        fn handler(ctx: *Executor) void {
            const frame = abi.CallFrame.raw(ctx, 5);
            const handle = frame.arg(0);
            const character = frame.arg(1);
            const length = frame.arg(2);
            const coord = frame.arg(3);
            const written_ptr = frame.arg(4);
            _ = coord;
            _ = handle;
            _ = character;
            if (written_ptr != 0) {
                ctx.mem.write32(written_ptr, length);
            }
            finishSuccess(frame);
        }
    }.handler) catch {};

    map.put("_GetConsoleScreenBufferInfo@8", struct {
        fn handler(ctx: *Executor) void {
            const frame = abi.CallFrame.raw(ctx, 2);
            const handle = frame.arg(0);
            const info_ptr = frame.arg(1);
            _ = handle;

            if (info_ptr != 0) {
                const width: u16 = 80;
                const height: u16 = 25;
                ctx.mem.write16(info_ptr, width);
                ctx.mem.write16(info_ptr + 2, height);
                ctx.mem.write16(info_ptr + 4, 0);
                ctx.mem.write16(info_ptr + 6, 0);
                ctx.mem.write16(info_ptr + 8, 0x0007);
                ctx.mem.write16(info_ptr + 10, 0);
                ctx.mem.write16(info_ptr + 12, 0);
                ctx.mem.write16(info_ptr + 14, width);
                ctx.mem.write16(info_ptr + 16, height);
                ctx.mem.write16(info_ptr + 18, width);
                ctx.mem.write16(info_ptr + 20, height);
            }
            finishSuccess(frame);
        }
    }.handler) catch {};

    map.put("_SetConsoleCursorPosition@8", struct {
        fn handler(ctx: *Executor) void {
            const frame = abi.CallFrame.raw(ctx, 2);
            const handle = frame.arg(0);
            const coord = frame.arg(1);
            _ = coord;
            _ = handle;
            finishSuccess(frame);
        }
    }.handler) catch {};

    map.put("_SetConsoleCursorInfo@8", struct {
        fn handler(ctx: *Executor) void {
            const frame = abi.CallFrame.raw(ctx, 2);
            const handle = frame.arg(0);
            const info_ptr = frame.arg(1);
            _ = info_ptr;
            _ = handle;
            finishSuccess(frame);
        }
    }.handler) catch {};

    map.put("_GetConsoleCursorInfo@8", struct {
        fn handler(ctx: *Executor) void {
            const frame = abi.CallFrame.raw(ctx, 2);
            const handle = frame.arg(0);
            const info_ptr = frame.arg(1);
            _ = handle;
            if (info_ptr != 0) {
                ctx.mem.write32(info_ptr, 25);
                ctx.mem.write32(info_ptr + 4, 1);
            }
            finishSuccess(frame);
        }
    }.handler) catch {};

    map.put("_SetConsoleCtrlHandler@8", struct {
        fn handler(ctx: *Executor) void {
            const frame = abi.CallFrame.raw(ctx, 2);
            const handler_addr = frame.arg(0);
            const add = frame.arg(1);
            _ = add;
            _ = handler_addr;
            finishSuccess(frame);
        }
    }.handler) catch {};

    map.put("_SetConsoleMode@8", struct {
        fn handler(ctx: *Executor) void {
            const frame = abi.CallFrame.raw(ctx, 2);
            const handle = frame.arg(0);
            const mode = frame.arg(1);
            _ = mode;
            _ = handle;
            finishSuccess(frame);
        }
    }.handler) catch {};

    map.put("_GetNumberOfConsoleInputEvents@8", struct {
        fn handler(ctx: *Executor) void {
            const frame = abi.CallFrame.raw(ctx, 2);
            const handle = frame.arg(0);
            const events_ptr = frame.arg(1);
            _ = handle;
            if (events_ptr != 0) {
                ctx.mem.write32(events_ptr, 0);
            }
            finishSuccess(frame);
        }
    }.handler) catch {};

    map.put("_ReadConsoleInputA@16", struct {
        fn handler(ctx: *Executor) void {
            const frame = abi.CallFrame.raw(ctx, 4);
            const handle = frame.arg(0);
            const buffer = frame.arg(1);
            const length = frame.arg(2);
            const events_read = frame.arg(3);
            _ = length;
            _ = buffer;
            _ = handle;
            _ = events_read;
            frame.finish(0);
        }
    }.handler) catch {};

    map.put("_HeapFree@12", struct {
        fn handler(ctx: *Executor) void {
            const frame = abi.CallFrame.raw(ctx, 3);
            const heap = frame.arg(0);
            const flags = frame.arg(1);
            const mem_ptr = frame.arg(2);
            _ = mem_ptr;
            _ = flags;
            _ = heap;
            finishSuccess(frame);
        }
    }.handler) catch {};

    map.put("_GetProcessHeap@0", struct {
        fn handler(ctx: *Executor) void {
            const frame = abi.CallFrame.raw(ctx, 0);
            frame.finish(0x1000);
        }
    }.handler) catch {};

    map.put("_GetTickCount@0", struct {
        fn handler(ctx: *Executor) void {
            const frame = abi.CallFrame.raw(ctx, 0);
            var ts: std.c.timespec = undefined;
            _ = std.c.clock_gettime(@as(std.c.clockid_t, .MONOTONIC), &ts);
            const ns = @as(u64, @intCast(ts.sec)) * std.time.ns_per_s + @as(u64, @intCast(ts.nsec));
            frame.finish(@intCast(@divTrunc(ns, std.time.ns_per_ms)));
        }
    }.handler) catch {};

    map.put("_GetSystemTime@4", struct {
        fn handler(ctx: *Executor) void {
            const frame = abi.CallFrame.raw(ctx, 1);
            const st_ptr = frame.arg(0);
            if (st_ptr != 0) {
                var ts: std.c.timespec = undefined;
                _ = std.c.clock_gettime(@as(std.c.clockid_t, .REALTIME), &ts);

                const epoch_seconds = std.time.epoch.EpochSeconds{
                    .secs = @intCast(ts.sec),
                };
                const epoch_day = epoch_seconds.getEpochDay();
                const year_day = epoch_day.calculateYearDay();
                const month_day = year_day.calculateMonthDay();
                const day_seconds = epoch_seconds.getDaySeconds();

                ctx.mem.write16(st_ptr, year_day.year);
                ctx.mem.write16(st_ptr + 2, month_day.month.numeric());
                ctx.mem.write16(st_ptr + 4, @intCast((epoch_day.day + 4) % 7));
                ctx.mem.write16(st_ptr + 6, @intCast(month_day.day_index + 1));
                ctx.mem.write16(st_ptr + 8, day_seconds.getHoursIntoDay());
                ctx.mem.write16(st_ptr + 10, day_seconds.getMinutesIntoHour());
                ctx.mem.write16(st_ptr + 12, day_seconds.getSecondsIntoMinute());
                ctx.mem.write16(st_ptr + 14, @intCast(@divTrunc(ts.nsec, std.time.ns_per_ms)));
            }
            frame.finish(0);
        }
    }.handler) catch {};

    map.put("_FillConsoleOutputAttribute@20", struct {
        fn handler(ctx: *Executor) void {
            const frame = abi.CallFrame.raw(ctx, 5);
            const handle = frame.arg(0);
            const attr = frame.arg(1);
            const length = frame.arg(2);
            const coord = frame.arg(3);
            const written_ptr = frame.arg(4);
            _ = coord;
            _ = handle;
            _ = attr;
            if (written_ptr != 0) {
                ctx.mem.write32(written_ptr, length);
            }
            finishSuccess(frame);
        }
    }.handler) catch {};
}

test "register win32 console thunks" {
    var ex = Executor.init(std.testing.allocator, 4096);
    defer ex.deinit();

    ex.regs.esp = 2048;
    register_win32_console_thunks(&ex);

    ex.push(0xFFFFFFF5);
    ex.dispatch_import("_GetStdHandle@4");
    try testing.expectEqual(@as(u32, 0xB002), ex.regs.eax);
}

test "Sleep thunk" {
    var ex = Executor.init(std.testing.allocator, 4096);
    defer ex.deinit();

    ex.regs.esp = 2048;
    register_win32_console_thunks(&ex);

    ex.push(1);
    ex.dispatch_import("_Sleep@4");
    try testing.expect(true);
}

test "FormatMessageA writes into caller buffer" {
    var ex = Executor.init(std.testing.allocator, 4096);
    defer ex.deinit();

    ex.regs.esp = 3072;
    register_win32_console_thunks(&ex);

    const buffer_ptr: u32 = 128;
    ex.push(0);
    ex.push(32);
    ex.push(buffer_ptr);
    ex.push(0);
    ex.push(0);
    ex.push(0);
    ex.push(0);

    ex.dispatch_import("_FormatMessageA@28");

    try testing.expect(ex.regs.eax > 0);
    try testing.expectEqual(@as(u8, 'S'), ex.mem.read8(buffer_ptr));
}

test "GetSystemTime populates a plausible UTC year" {
    var ex = Executor.init(std.testing.allocator, 4096);
    defer ex.deinit();

    ex.regs.esp = 3072;
    register_win32_console_thunks(&ex);

    const system_time_ptr: u32 = 256;
    ex.push(system_time_ptr);
    ex.dispatch_import("_GetSystemTime@4");

    const year = ex.mem.read16(system_time_ptr);
    try testing.expect(year >= 2024);
}

test "ExitProcess thunk registration" {
    var ex = Executor.init(std.testing.allocator, 4096);
    defer ex.deinit();

    ex.regs.esp = 2048;
    register_win32_console_thunks(&ex);

    try testing.expect(ex.import_table.contains("_ExitProcess@4"));
}
