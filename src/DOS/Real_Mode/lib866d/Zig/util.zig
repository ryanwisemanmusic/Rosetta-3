const std = @import("std");
const types = @import("types.zig");
const debug = @import("debug.zig");

pub const ApplicationLogo = extern struct {
    logoData: [*:0]const u8,
    width: usize,
    height: usize,
    fgColor: u8,
    bgColor: u8,
};

pub fn DynU8(comptime T: type) type {
    return struct {
        count: usize,
        capacity: usize,
        items: ?[]T,
    };
}

pub const DynU16 = struct { count: usize, capacity: usize, items: ?[]u16 };
pub const DynU32 = struct { count: usize, capacity: usize, items: ?[]u32 };
pub const DynStr = struct { count: usize, capacity: usize, items: ?[][]u8 };

pub fn MK_FP(seg: u32, off: u16) *anyopaque {
    return @ptrFromInt((seg << 16) | @as(u32, off));
}

pub fn MAX(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
    return if (a > b) a else b;
}
pub fn MIN(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
    return if (a < b) a else b;
}

pub fn ARRAY_SIZE(x: anytype) usize {
    return @typeInfo(@TypeOf(x)).array.len;
}

pub fn SWAP16(x: u16) u16 {
    return @as(u16, @intCast((x >> 8) & 0x00FF)) | ((x << 8) & 0xFF00);
}

pub fn SWAP32(x: u32) u32 {
    return ((x >> 24) & 0x000000FF) |
        ((x >> 8) & 0x0000FF00) |
        ((x << 8) & 0x00FF0000) |
        ((x << 24) & 0xFF000000);
}

pub fn BIT(x: u5) u32 {
    return @as(u32, 1) << x;
}
pub fn BIT8(x: u3) u8 {
    return @as(u8, 1) << x;
}
pub fn BIT32(x: u5) u32 {
    return @as(u32, 1) << x;
}

pub fn stringEquals(str1: []const u8, str2: []const u8) bool {
    return std.mem.eql(u8, str1, str2);
}

pub fn stringStartsWith(full: []const u8, toCheck: []const u8) bool {
    return std.mem.startsWith(u8, full, toCheck);
}

pub fn stringEndsWith(full: []const u8, toCheck: []const u8) bool {
    return std.mem.endsWith(u8, full, toCheck);
}

pub fn stringReplaceChar(str: []u8, oldChar: u8, newChar: u8) void {
    for (str) |*c| {
        if (c.* == oldChar) c.* = newChar;
    }
}

pub fn stringToU32(str: []const u8, out: *u32) bool {
    const value = std.fmt.parseInt(u32, std.mem.trim(u8, str, " \t"), 0) catch return false;
    out.* = value;
    return true;
}

pub fn swapInPlace16(buf: *u16) void {
    buf.* = SWAP16(buf.*);
}

pub fn swapInPlace32(buf: *u32) void {
    buf.* = SWAP32(buf.*);
}

pub fn strncasecmp(str1: []const u8, str2: []const u8, strLen: usize) i32 {
    var i: usize = 0;
    while (i < strLen and i < str1.len and i < str2.len) : (i += 1) {
        const c1 = std.ascii.toLower(str1[i]);
        const c2 = std.ascii.toLower(str2[i]);
        if (c1 != c2 or c1 == 0 or c2 == 0) return @as(i32, c1) - @as(i32, c2);
    }
    return 0;
}

pub fn snprintf(out: []u8, comptime fmt: []const u8, args: anytype) i32 {
    const written = std.fmt.bufPrint(out, fmt, args) catch return @intCast(out.len);
    return @intCast(written.len);
}

pub fn printWithApplicationLogo(logo: *const ApplicationLogo, comptime fmt: []const u8, args: anytype) void {
    var logoLinesShown: usize = 0;
    debug.nullcheck(logo);
    debug.nullcheck(logo.logoData);

    const logoLinePtr = logo.logoData[logoLinesShown * logo.width ..];
    if (logoLinesShown < logo.height) {
        std.debug.print("{s}", .{logoLinePtr[0..logo.width]});
        logoLinesShown += 1;
    }
    std.debug.print(fmt, args);
}

pub fn round(f: f32) i32 {
    return if (f > 0.0) @as(i32, @intFromFloat(f + 0.5)) else @as(i32, @intFromFloat(f - 0.5));
}

pub fn sleep(milliseconds: u32) void {
    var remaining: u32 = milliseconds;
    while (remaining > 0) {
        asm volatile ("nop");
        remaining -= 1;
    }
}

pub fn msToClocks(milliseconds: u32) u32 {
    return milliseconds;
}

pub fn getTimeOffsetInClocks(milliseconds: u32) u32 {
    return msToClocks(milliseconds);
}

const DynArray = extern struct {
    count: usize,
    capacity: usize,
    items: ?[]u8,
};

fn dynArrayGrowGeneric(arr: *DynArray, elementSize: usize, allocator: std.mem.Allocator) bool {
    if ((arr.count + 1) <= arr.capacity) return true;
    const newCapacity = if (arr.capacity == 0) 8 else arr.capacity * 2;

    const newItems = allocator.realloc(arr.items.?, newCapacity * elementSize) catch {
        const newAlloc = allocator.allocAdvanced(u8, 1, newCapacity * elementSize, .exact) catch return false;
        @memcpy(newAlloc[0 .. arr.count * elementSize], arr.items.?[0 .. arr.count * elementSize]);
        allocator.free(arr.items.?);
        arr.items = newAlloc;
        arr.capacity = newCapacity;
        return true;
    };
    arr.items = newItems;
    arr.capacity = newCapacity;
    return true;
}

fn dynArrayItemAtIndex(arr: *DynArray, index: usize, elementSize: usize) usize {
    return @intFromPtr(arr.items.?) + (index * elementSize);
}
