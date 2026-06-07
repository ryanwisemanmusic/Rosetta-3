const std = @import("std");

pub const TraceEventType = enum {
    open_app,
    launch_executable,
    load_dylib,
    load_bundle,
    load_framework,
    open_plist,
    open_nib,
    open_icon,
    read_resource,
    read_script,
    read_strings,
    code_signature_check,
};

pub const TraceEvent = struct {
    event_type: TraceEventType,
    path: []const u8,
    timestamp: u64,
};

pub const AppTracer = struct {
    events: std.ArrayList(TraceEvent),
    allocator: std.mem.Allocator,
    start_time: u64,

    pub fn init(allocator: std.mem.Allocator) AppTracer {
        return .{
            .events = .empty,
            .allocator = allocator,
            .start_time = 0,
        };
    }

    pub fn deinit(self: *AppTracer) void {
        for (self.events.items) |e| {
            self.allocator.free(e.path);
        }
        self.events.deinit(self.allocator);
    }

    pub fn recordEvent(self: *AppTracer, event_type: TraceEventType, path: []const u8) !void {
        const path_copy = try self.allocator.dupe(u8, path);
        errdefer self.allocator.free(path_copy);
        try self.events.append(self.allocator, .{
            .event_type = event_type,
            .path = path_copy,
            .timestamp = self.start_time,
        });
    }

    pub fn summary(self: AppTracer) usize {
        return self.events.items.len;
    }
};

test "tracer records events" {
    var tracer = AppTracer.init(std.testing.allocator);
    defer tracer.deinit();
    try tracer.recordEvent(.open_app, "/Applications/Test.app");
    try tracer.recordEvent(.launch_executable, "/Applications/Test.app/Contents/MacOS/Test");
    try std.testing.expectEqual(@as(usize, 2), tracer.summary());
}
