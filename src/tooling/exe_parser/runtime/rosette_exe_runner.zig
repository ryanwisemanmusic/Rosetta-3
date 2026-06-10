const std = @import("std");
const core = @import("../exe_runner_core.zig");

pub fn main(init: std.process.Init) !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("MAIN: Starting rosette_exe_runner\n", .{});
    try stdout.flush();
    
    std.debug.print("MAIN: Starting rosette_exe_runner (debug)\n", .{});
    const allocator = init.arena.allocator();
    const args = try init.minimal.args.toSlice(allocator);
    if (args.len < 2 or args.len > 4) {
        std.debug.print("usage: {s} <program.exe> [trace.log] [--parse-only]\n", .{args[0]});
        return error.InvalidArguments;
    }
    std.debug.print("MAIN: Got args: {}\n", .{args.len});

    const exe_path = args[1];
    var parse_only = false;
    var explicit_log: ?[]const u8 = null;
    for (args[2..]) |arg| {
        if (std.mem.eql(u8, arg, "--parse-only")) {
            parse_only = true;
        } else if (explicit_log == null) {
            explicit_log = arg;
        } else {
            std.debug.print("usage: {s} <program.exe> [trace.log] [--parse-only]\n", .{args[0]});
            return error.InvalidArguments;
        }
    }

    const default_log_text = try std.fmt.allocPrint(allocator, "{s}.trace.log", .{exe_path});
    const default_log = try allocator.dupeZ(u8, default_log_text);
    const log_path = if (explicit_log) |log|
        try allocator.dupeZ(u8, log)
    else
        default_log;

    try core.run(init, exe_path, log_path, !parse_only);
}
