const std = @import("std");
const palette = @import("palette.zig");
const debug = @import("debug.zig");
const runtime_abi = @import("runtime_abi_handshake");

extern fn pthread_mutex_init(mutex: *[64]u8, attr: ?*anyopaque) c_int;
extern fn pthread_mutex_lock(mutex: *[64]u8) c_int;
extern fn pthread_mutex_unlock(mutex: *[64]u8) c_int;

var g_width: u32 = 0;
var g_height: u32 = 0;
var g_blocks: []palette.Color = &.{};
var g_mutex: [64]u8 = [_]u8{0} ** 64;
var g_mutex_initted: bool = false;

fn lock() void {
    _ = pthread_mutex_lock(&g_mutex);
}

fn unlock() void {
    _ = pthread_mutex_unlock(&g_mutex);
}

pub fn rosetta3_gfx_init(w: u32, h: u32) callconv(.c) void {
    debug.log(.info, "framebuffer_init(w={d}, h={d})", .{ w, h });
    runtime_abi.graphics.init();
    runtime_abi.graphics.validateFramebufferInit(w, h);
    if (!g_mutex_initted) {
        _ = pthread_mutex_init(&g_mutex, null);
        g_mutex_initted = true;
    }
    lock();
    defer unlock();
    if (g_blocks.len > 0) {
        const alloc = std.heap.page_allocator;
        alloc.free(g_blocks);
    }
    g_width = w;
    g_height = h;
    if (w == 0 or h == 0) {
        g_blocks = &.{};
        debug.log(.info, "  framebuffer disabled for zero-sized block mode", .{});
        return;
    }
    const alloc = std.heap.page_allocator;
    g_blocks = alloc.alloc(palette.Color, w * h) catch {
        debug.log(.info, "  alloc({d}) FAILED", .{w * h});
        g_width = 0;
        g_height = 0;
        return;
    };
    @memset(g_blocks, palette.COLOR_GRID_BG);
    debug.log(.info, "  allocated {d} blocks at 0x{x}", .{ w * h, @intFromPtr(g_blocks.ptr) });
}

pub fn rosetta3_gfx_deinit() callconv(.c) void {
    debug.log(.info, "framebuffer_deinit()", .{});
    lock();
    defer unlock();
    if (g_blocks.len > 0) {
        const alloc = std.heap.page_allocator;
        alloc.free(g_blocks);
    }
    g_blocks = &.{};
    g_width = 0;
    g_height = 0;
    runtime_abi.graphics.deinit();
}

pub fn rosetta3_gfx_get_width() callconv(.c) u32 {
    return g_width;
}

pub fn rosetta3_gfx_get_height() callconv(.c) u32 {
    return g_height;
}

pub fn rosetta3_gfx_get_block(x: u32, y: u32) callconv(.c) u32 {
    runtime_abi.graphics.validateFramebufferAccess(.read, g_width, g_height, x, y, null);
    if (x >= g_width or y >= g_height) {
        debug.log(.spam, "get_block({d},{d}) OUT OF BOUNDS (w={d}, h={d})", .{ x, y, g_width, g_height });
        return 0;
    }
    lock();
    defer unlock();
    const val = g_blocks[y * g_width + x];
    debug.log(.spam, "get_block({d},{d}) = 0x{x}", .{ x, y, val });
    return val;
}

pub fn rosetta3_gfx_set_block(x: u32, y: u32, rgba: u32) callconv(.c) void {
    runtime_abi.graphics.validateFramebufferAccess(.write, g_width, g_height, x, y, rgba);
    if (x >= g_width or y >= g_height) {
        debug.log(.verbose, "set_block({d},{d}, 0x{x}) OUT OF BOUNDS (w={d}, h={d})", .{ x, y, rgba, g_width, g_height });
        return;
    }
    lock();
    defer unlock();
    const old = g_blocks[y * g_width + x];
    g_blocks[y * g_width + x] = rgba;
    if (old != rgba) {
        debug.log(.spam, "set_block({d},{d}) 0x{x} -> 0x{x}", .{ x, y, old, rgba });
    }
}

pub fn rosetta3_gfx_clear(rgba: u32) callconv(.c) void {
    if (g_blocks.len == 0) return;
    lock();
    defer unlock();
    debug.log(.verbose, "clear(0x{x}) over {d} blocks", .{ rgba, g_blocks.len });
    @memset(g_blocks, rgba);
}

comptime {
    @export(&rosetta3_gfx_init, .{ .name = "rosetta3_gfx_init", .linkage = .strong });
    @export(&rosetta3_gfx_deinit, .{ .name = "rosetta3_gfx_deinit", .linkage = .strong });
    @export(&rosetta3_gfx_get_width, .{ .name = "rosetta3_gfx_get_width", .linkage = .strong });
    @export(&rosetta3_gfx_get_height, .{ .name = "rosetta3_gfx_get_height", .linkage = .strong });
    @export(&rosetta3_gfx_get_block, .{ .name = "rosetta3_gfx_get_block", .linkage = .strong });
    @export(&rosetta3_gfx_set_block, .{ .name = "rosetta3_gfx_set_block", .linkage = .strong });
    @export(&rosetta3_gfx_clear, .{ .name = "rosetta3_gfx_clear", .linkage = .strong });
}
