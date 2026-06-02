const std = @import("std");
const dos_session = @import("../src/DOS/execution/session.zig");
const host_mod = @import("../src/DOS/execution/host_services.zig");

pub const Bridge = struct {
    allocator: std.mem.Allocator,
    host: host_mod.HostAdapter,

    pub fn init(allocator: std.mem.Allocator, host: host_mod.HostAdapter) Bridge {
        return .{
            .allocator = allocator,
            .host = host,
        };
    }

    pub fn loadCom(self: Bridge, image: []const u8) !dos_session.Session {
        var session = try dos_session.Session.init(self.allocator, self.host);
        try session.loadCom(image, 0x1000);
        return session;
    }
};

test "bridge creates DOS session for COM image" {
    var host_state = host_mod.NoopHostState{};
    defer host_state.deinit(std.testing.allocator);

    const bridge = Bridge.init(std.testing.allocator, host_state.adapter());
    var session = try bridge.loadCom("ABC");
    defer session.deinit();
    try std.testing.expectEqual(@as(u16, 0x1000), session.cpu.cs);
}
