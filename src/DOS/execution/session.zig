const std = @import("std");
const cpu_mod = @import("cpu_state.zig");
const mem_mod = @import("segmented_memory.zig");
const loader = @import("loader.zig");
const host_mod = @import("host_services.zig");
const interrupts = @import("interrupt_services.zig");
const runtime_abi = @import("runtime_abi_handshake");
const reg_trace = @import("../register-tracing/runtime.zig");
const stack_trace = @import("../stack/runtime.zig");
const psp_trace = @import("../psp/runtime.zig");

fn rawFlags(flags: cpu_mod.Flags) u16 {
    return @bitCast(flags);
}

pub const Session = struct {
    allocator: std.mem.Allocator,
    cpu: cpu_mod.CpuState,
    mem: mem_mod.RealModeMemory,
    host: host_mod.HostAdapter,
    services: interrupts.InterruptServices,
    loaded: ?loader.LoadedProgram = null,

    pub fn init(allocator: std.mem.Allocator, host: host_mod.HostAdapter) !Session {
        runtime_abi.dos.init();
        errdefer runtime_abi.dos.deinit();
        reg_trace.init();
        errdefer reg_trace.deinit();
        var session = Session{
            .allocator = allocator,
            .cpu = .{},
            .mem = try mem_mod.RealModeMemory.initDefault(allocator),
            .host = host,
            .services = undefined,
        };
        errdefer session.mem.deinit();
        try seedDosMemoryMap(&session.mem);
        session.services = interrupts.InterruptServices.init(allocator, &session.cpu, &session.mem, host);
        runtime_abi.dos.validateDosMemoryMap(session.mem.bytes.len, 0x00000, 0x00400, 0xB8000);
        psp_trace.logMemoryMap("session-init", 0x00000, 0x00400, 0xB8000, session.mem.bytes.len);
        runtime_abi.dos.validateSession("init", session.mem.bytes.len, session.cpu.cs, session.cpu.ip, session.cpu.ss, session.cpu.sp, rawFlags(session.cpu.flags));
        reg_trace.logCheckpoint("init", &session.cpu);
        stack_trace.logState("init", .checkpoint, &session.cpu, &session.mem);
        return session;
    }

    pub fn deinit(self: *Session) void {
        self.mem.deinit();
        reg_trace.deinit();
        runtime_abi.dos.deinit();
    }

    pub fn loadCom(self: *Session, image: []const u8, load_segment: u16) !void {
        self.loaded = try loader.loadCom(&self.mem, &self.cpu, image, load_segment);
        if (self.loaded) |loaded| {
            runtime_abi.dos.validateLoad("com", self.mem.bytes.len, loaded.psp_segment, loaded.load_segment, loaded.entry_cs, loaded.entry_ip, loaded.stack_ss, loaded.stack_sp);
        }
        runtime_abi.dos.validateSession("loadCom", self.mem.bytes.len, self.cpu.cs, self.cpu.ip, self.cpu.ss, self.cpu.sp, rawFlags(self.cpu.flags));
        reg_trace.logCheckpoint("loadCom", &self.cpu);
        stack_trace.logState("loadCom", .checkpoint, &self.cpu, &self.mem);
    }

    pub fn loadSourceReference(self: *Session, load_segment: u16) !void {
        self.loaded = try loader.loadSourceReference(&self.mem, &self.cpu, load_segment);
        if (self.loaded) |loaded| {
            runtime_abi.dos.validateLoad("source_reference", self.mem.bytes.len, loaded.psp_segment, loaded.load_segment, loaded.entry_cs, loaded.entry_ip, loaded.stack_ss, loaded.stack_sp);
        }
        runtime_abi.dos.validateSession("loadSourceReference", self.mem.bytes.len, self.cpu.cs, self.cpu.ip, self.cpu.ss, self.cpu.sp, rawFlags(self.cpu.flags));
        reg_trace.logCheckpoint("loadSourceReference", &self.cpu);
        stack_trace.logState("loadSourceReference", .checkpoint, &self.cpu, &self.mem);
    }

    pub fn loadMz(self: *Session, image: []const u8, psp_segment: u16) !void {
        self.loaded = try loader.loadMz(&self.mem, &self.cpu, image, psp_segment);
        if (self.loaded) |loaded| {
            runtime_abi.dos.validateLoad("mz", self.mem.bytes.len, loaded.psp_segment, loaded.load_segment, loaded.entry_cs, loaded.entry_ip, loaded.stack_ss, loaded.stack_sp);
        }
        runtime_abi.dos.validateSession("loadMz", self.mem.bytes.len, self.cpu.cs, self.cpu.ip, self.cpu.ss, self.cpu.sp, rawFlags(self.cpu.flags));
        reg_trace.logCheckpoint("loadMz", &self.cpu);
        stack_trace.logState("loadMz", .checkpoint, &self.cpu, &self.mem);
    }

    pub fn interrupt(self: *Session, vector: u8) !void {
        self.services.cpu = &self.cpu;
        self.services.mem = &self.mem;
        runtime_abi.dos.validateInterrupt(vector, self.cpu.ah(), self.cpu.al());
        reg_trace.logInterrupt("pre", vector, &self.cpu);
        stack_trace.logState("pre-interrupt", .before_interrupt, &self.cpu, &self.mem);
        try self.services.invoke(vector);
        runtime_abi.dos.validateSession("interrupt", self.mem.bytes.len, self.cpu.cs, self.cpu.ip, self.cpu.ss, self.cpu.sp, rawFlags(self.cpu.flags));
        reg_trace.logInterrupt("post", vector, &self.cpu);
        stack_trace.logState("post-interrupt", .after_interrupt, &self.cpu, &self.mem);
    }

    pub fn push16(self: *Session, value: u16) !void {
        self.cpu.sp -%= 2;
        try self.mem.write16(self.cpu.ss, self.cpu.sp, value);
        stack_trace.logState("push16", .after_instruction, &self.cpu, &self.mem);
    }

    pub fn pop16(self: *Session) !u16 {
        const value = try self.mem.read16(self.cpu.ss, self.cpu.sp);
        self.cpu.sp +%= 2;
        stack_trace.logState("pop16", .after_instruction, &self.cpu, &self.mem);
        return value;
    }
};

fn seedDosMemoryMap(mem: *mem_mod.RealModeMemory) !void {
    try mem.fill(0x0000, 0x0000, 0x0400, 0);
    try mem.fill(0x0040, 0x0000, 0x0100, 0);
    try mem.fill(0xB800, 0x0000, 0x1000, 0);
}

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
