const std = @import("std");
const cpu_mod = @import("cpu_state.zig");
const mem_mod = @import("segmented_memory.zig");
const loader = @import("loader.zig");
const host_mod = @import("host_services.zig");
const interrupts = @import("interrupt_services.zig");

pub const Session = struct {
    allocator: std.mem.Allocator,
    cpu: cpu_mod.CpuState,
    mem: mem_mod.RealModeMemory,
    host: host_mod.HostAdapter,
    services: interrupts.InterruptServices,
    loaded: ?loader.LoadedProgram = null,

    pub fn init(allocator: std.mem.Allocator, host: host_mod.HostAdapter) !Session {
        var session = Session{
            .allocator = allocator,
            .cpu = .{},
            .mem = try mem_mod.RealModeMemory.initDefault(allocator),
            .host = host,
            .services = undefined,
        };
        errdefer session.mem.deinit();
        session.services = interrupts.InterruptServices.init(allocator, &session.cpu, &session.mem, host);
        return session;
    }

    pub fn deinit(self: *Session) void {
        self.mem.deinit();
    }

    pub fn loadCom(self: *Session, image: []const u8, load_segment: u16) !void {
        self.loaded = try loader.loadCom(&self.mem, &self.cpu, image, load_segment);
    }

    pub fn loadSourceReference(self: *Session, load_segment: u16) !void {
        self.loaded = try loader.loadSourceReference(&self.mem, &self.cpu, load_segment);
    }

    pub fn interrupt(self: *Session, vector: u8) !void {
        self.services.cpu = &self.cpu;
        self.services.mem = &self.mem;
        try self.services.invoke(vector);
    }

    pub fn push16(self: *Session, value: u16) !void {
        self.cpu.sp -%= 2;
        try self.mem.write16(self.cpu.ss, self.cpu.sp, value);
    }

    pub fn pop16(self: *Session) !u16 {
        const value = try self.mem.read16(self.cpu.ss, self.cpu.sp);
        self.cpu.sp +%= 2;
        return value;
    }
};

test "session can load source reference and call DOS exit" {
    var host_state = host_mod.NoopHostState{};
    defer host_state.deinit(std.testing.allocator);

    var session = try Session.init(std.testing.allocator, host_state.adapter());
    defer session.deinit();

    try session.loadSourceReference(0x2000);
    session.cpu.setAh(0x4C);
    session.cpu.setAl(3);
    try session.interrupt(0x21);
    try std.testing.expect(host_state.exited);
    try std.testing.expectEqual(@as(u8, 3), host_state.exit_code);
}
