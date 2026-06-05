const std = @import("std");
const dll = @import("root.zig");

pub fn main(init: std.process.Init) !void {
    const allocator = init.arena.allocator();
    const args = try init.minimal.args.toSlice(allocator);

    if (args.len != 3) {
        std.debug.print("usage: {s} <dll-path> <output-dir>\n", .{args[0]});
        return error.InvalidArguments;
    }

    try dll.dumpDllResources(allocator, args[1], args[2]);
    std.debug.print("unpacked {s} -> {s}\n", .{ args[1], args[2] });
}
