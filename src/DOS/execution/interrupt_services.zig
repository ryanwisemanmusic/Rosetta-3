const std = @import("std");
const cpu_mod = @import("cpu_state.zig");
const mem_mod = @import("segmented_memory.zig");
const host_mod = @import("host_services.zig");
const runtime_abi = @import("runtime_abi_handshake");
const dos_trace = @import("../dos-services/runtime.zig");
const exception_trace = @import("../exceptions/runtime.zig");

pub const InterruptServices = struct {
    allocator: std.mem.Allocator,
    cpu: *cpu_mod.CpuState,
    mem: *mem_mod.RealModeMemory,
    host: host_mod.HostAdapter,
    cursor_row: u8 = 0,
    cursor_col: u8 = 0,
    video_mode: u8 = 3,
    active_page: u8 = 0,
    peeked_key: ?host_mod.KeyStatus = null,
    dta_segment: u16 = 0,
    dta_offset: u16 = 0x80,

    pub fn init(
        allocator: std.mem.Allocator,
        cpu: *cpu_mod.CpuState,
        mem: *mem_mod.RealModeMemory,
        host: host_mod.HostAdapter,
    ) InterruptServices {
        return .{
            .allocator = allocator,
            .cpu = cpu,
            .mem = mem,
            .host = host,
        };
    }

    pub fn invoke(self: *InterruptServices, vector: u8) !void {
        dos_trace.logInterrupt("invoke", vector, self.cpu.ah(), self.cpu.al());
        exception_trace.logInterrupt("invoke", vector, self.cpu);
        switch (vector) {
            0x10 => try self.int10h(),
            0x15 => try self.int15h(),
            0x16 => try self.int16h(),
            0x1A => try self.int1Ah(),
            0x20 => self.int20h(),
            0x21 => try self.int21h(),
            0x33 => try self.int33h(),
            else => return error.UnsupportedInterrupt,
        }
    }

    fn int10h(self: *InterruptServices) !void {
        runtime_abi.dos.validateVideoService(self.cpu.ah(), self.cpu.al(), self.cpu.dh(), self.cpu.dl(), self.cpu.bh());
        switch (self.cpu.ah()) {
            0x00 => {
                self.video_mode = self.cpu.al();
                self.cursor_row = 0;
                self.cursor_col = 0;
                self.host.clearScreen();
            },
            0x01 => {},
            0x02 => {
                self.cursor_row = self.cpu.dh();
                self.cursor_col = self.cpu.dl();
                self.host.setCursor(self.cursor_row, self.cursor_col);
            },
            0x03 => {
                self.cpu.setDh(self.cursor_row);
                self.cpu.setDl(self.cursor_col);
                self.cpu.setCh(0);
                self.cpu.setCl(0);
            },
            0x06 => {
                self.host.clearScreen();
                self.cursor_row = 0;
                self.cursor_col = 0;
                self.host.setCursor(0, 0);
            },
            0x09 => {
                self.host.writeCharAttr(self.cpu.al(), self.cpu.bl(), self.cpu.cx);
            },
            0x0E => {
                self.host.writeCharAttr(self.cpu.al(), self.cpu.bl(), 1);
                self.cursor_col +%= 1;
            },
            0x0F => {
                self.cpu.setAl(self.video_mode);
                self.cpu.setAh(80);
                self.cpu.setBh(self.active_page);
            },
            else => return error.UnsupportedVideoService,
        }
        dos_trace.logVideoService("int10h", self.cpu.ah(), self.cpu.al(), self.cursor_row, self.cursor_col);
    }

    fn int15h(self: *InterruptServices) !void {
        switch (self.cpu.ah()) {
            0x86 => {
                const micros = (@as(u32, self.cpu.cx) << 16) | self.cpu.dx;
                self.host.sleepMicroseconds(micros);
            },
            else => return error.UnsupportedSystemService,
        }
    }

    fn int16h(self: *InterruptServices) !void {
        switch (self.cpu.ah()) {
            0x00 => {
                const key = self.peeked_key orelse self.host.readKeyBlocking();
                self.peeked_key = null;
                self.cpu.setAh(key.scan);
                self.cpu.setAl(key.ascii);
                self.cpu.flags.zf = 0;
                runtime_abi.dos.validateKeyboardService(0x00, key.ascii, key.scan, false);
                dos_trace.logKeyboardService("int16h", 0x00, key.ascii, key.scan, false);
            },
            0x01 => {
                if (self.peeked_key) |key| {
                    self.cpu.setAh(key.scan);
                    self.cpu.setAl(key.ascii);
                    self.cpu.flags.zf = 0;
                    runtime_abi.dos.validateKeyboardService(0x01, key.ascii, key.scan, false);
                    dos_trace.logKeyboardService("int16h", 0x01, key.ascii, key.scan, false);
                } else if (self.host.pollKey()) |key| {
                    self.peeked_key = key;
                    self.cpu.setAh(key.scan);
                    self.cpu.setAl(key.ascii);
                    self.cpu.flags.zf = 0;
                    runtime_abi.dos.validateKeyboardService(0x01, key.ascii, key.scan, false);
                    dos_trace.logKeyboardService("int16h", 0x01, key.ascii, key.scan, false);
                } else {
                    self.cpu.setAh(0);
                    self.cpu.setAl(0);
                    self.cpu.flags.zf = 1;
                    runtime_abi.dos.validateKeyboardService(0x01, 0, 0, true);
                    dos_trace.logKeyboardService("int16h", 0x01, 0, 0, true);
                }
            },
            else => return error.UnsupportedKeyboardService,
        }
    }

    fn int1Ah(self: *InterruptServices) !void {
        switch (self.cpu.ah()) {
            0x00 => {
                self.cpu.setCh(0);
                self.cpu.setCl(0);
                self.cpu.dx = self.host.timeHundredths();
                runtime_abi.dos.validateTimerService(0x00, self.cpu.cx, self.cpu.dx);
                dos_trace.logTimerService("int1Ah", 0x00, self.cpu.cx, self.cpu.dx);
            },
            0x01 => {
                runtime_abi.dos.validateTimerService(0x01, self.cpu.cx, self.cpu.dx);
                dos_trace.logTimerService("int1Ah", 0x01, self.cpu.cx, self.cpu.dx);
            },
            else => return error.UnsupportedTimerService,
        }
    }

    fn int20h(self: *InterruptServices) void {
        self.host.exitProcess(0);
        dos_trace.logDosService("int20h", 0x20, 0, self.cpu.dx, self.cpu.ds);
    }

    fn int21h(self: *InterruptServices) !void {
        runtime_abi.dos.validateDosFunction(self.cpu.ah(), self.cpu.al(), self.cpu.ds, self.cpu.dx);
        switch (self.cpu.ah()) {
            0x09 => {
                const text = try self.mem.sliceZ(self.cpu.ds, self.cpu.dx, '$');
                self.host.writeText(text);
            },
            0x0A => try self.readBufferedLine(),
            0x1A => {
                self.dta_segment = self.cpu.ds;
                self.dta_offset = self.cpu.dx;
            },
            0x2C => {
                self.cpu.setCh(0);
                self.cpu.setCl(0);
                self.cpu.setDh(0);
                self.cpu.setDl(self.host.timeHundredths());
            },
            0x4C => {
                self.host.exitProcess(self.cpu.al());
            },
            else => return error.UnsupportedDosService,
        }
        dos_trace.logDosService("int21h", self.cpu.ah(), self.cpu.al(), self.cpu.dx, self.cpu.ds);
    }

    fn int33h(self: *InterruptServices) !void {
        switch (self.cpu.ax) {
            0x0000 => {
                self.cpu.ax = 0;
            },
            0x0003 => {
                self.cpu.bx = 0;
                self.cpu.cx = 0;
                self.cpu.dx = 0;
            },
            else => return error.UnsupportedMouseService,
        }
        runtime_abi.dos.validateMouseService(self.cpu.ax, self.cpu.bx, self.cpu.cx, self.cpu.dx);
        dos_trace.logMouseService("int33h", self.cpu.ax, self.cpu.bx, self.cpu.cx, self.cpu.dx);
    }

    fn readBufferedLine(self: *InterruptServices) !void {
        const max_len = try self.mem.read8(self.cpu.ds, self.cpu.dx);
        var actual_len: u8 = 0;
        while (actual_len < max_len) {
            const key = self.host.readKeyBlocking();
            if (key.ascii == 13) break;
            try self.mem.write8(self.cpu.ds, self.cpu.dx +% 2 + actual_len, key.ascii);
            actual_len +%= 1;
        }
        try self.mem.write8(self.cpu.ds, self.cpu.dx +% 1, actual_len);
        try self.mem.write8(self.cpu.ds, self.cpu.dx +% 2 + actual_len, 13);
    }
};

test "dos string output uses ds:dx and dollar terminator" {
    var cpu: cpu_mod.CpuState = .{ .ds = 0x1000 };
    var mem = try mem_mod.RealModeMemory.initDefault(std.testing.allocator);
    defer mem.deinit();

    try mem.writeBytes(0x1000, 0x0020, "Hello$");
    cpu.dx = 0x0020;
    cpu.setAh(0x09);

    var host_state = host_mod.NoopHostState{};
    defer host_state.deinit(std.testing.allocator);

    var services = InterruptServices.init(std.testing.allocator, &cpu, &mem, host_state.adapter());
    try services.invoke(0x21);
    try std.testing.expectEqualStrings("Hello", host_state.log.items);
}

test "buffered keyboard input fills DOS 0Ah buffer" {
    var cpu: cpu_mod.CpuState = .{ .ds = 0x2000 };
    var mem = try mem_mod.RealModeMemory.initDefault(std.testing.allocator);
    defer mem.deinit();

    try mem.write8(0x2000, 0x0040, 8);
    cpu.dx = 0x0040;
    cpu.setAh(0x0A);

    var host_state = host_mod.NoopHostState{ .queued_key = .{ .available = true, .ascii = 'A', .scan = 0x1E } };
    defer host_state.deinit(std.testing.allocator);
    var services = InterruptServices.init(std.testing.allocator, &cpu, &mem, host_state.adapter());
    try services.invoke(0x21);
    try std.testing.expectEqual(@as(u8, 1), try mem.read8(0x2000, 0x0041));
    try std.testing.expectEqual(@as(u8, 'A'), try mem.read8(0x2000, 0x0042));
}

test "int20h exits with zero status" {
    var cpu: cpu_mod.CpuState = .{};
    var mem = try mem_mod.RealModeMemory.initDefault(std.testing.allocator);
    defer mem.deinit();

    var host_state = host_mod.NoopHostState{};
    defer host_state.deinit(std.testing.allocator);
    var services = InterruptServices.init(std.testing.allocator, &cpu, &mem, host_state.adapter());
    try services.invoke(0x20);
    try std.testing.expect(host_state.exited);
    try std.testing.expectEqual(@as(u8, 0), host_state.exit_code);
}

test "int1Ah timer returns hundredths in dx" {
    var cpu: cpu_mod.CpuState = .{};
    var mem = try mem_mod.RealModeMemory.initDefault(std.testing.allocator);
    defer mem.deinit();

    cpu.setAh(0x00);
    var host_state = host_mod.NoopHostState{};
    defer host_state.deinit(std.testing.allocator);
    var services = InterruptServices.init(std.testing.allocator, &cpu, &mem, host_state.adapter());
    try services.invoke(0x1A);
    try std.testing.expectEqual(@as(u16, 42), cpu.dx);
}
