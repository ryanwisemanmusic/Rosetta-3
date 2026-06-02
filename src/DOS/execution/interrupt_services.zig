const std = @import("std");
const cpu_mod = @import("cpu_state.zig");
const mem_mod = @import("segmented_memory.zig");
const host_mod = @import("host_services.zig");

pub const InterruptServices = struct {
    allocator: std.mem.Allocator,
    cpu: *cpu_mod.CpuState,
    mem: *mem_mod.RealModeMemory,
    host: host_mod.HostAdapter,
    cursor_row: u8 = 0,
    cursor_col: u8 = 0,

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
        switch (vector) {
            0x10 => try self.int10h(),
            0x15 => try self.int15h(),
            0x16 => try self.int16h(),
            0x21 => try self.int21h(),
            else => return error.UnsupportedInterrupt,
        }
    }

    fn int10h(self: *InterruptServices) !void {
        switch (self.cpu.ah()) {
            0x01 => {},
            0x02 => {
                self.cursor_row = self.cpu.dh();
                self.cursor_col = self.cpu.dl();
                self.host.setCursor(self.cursor_row, self.cursor_col);
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
            else => return error.UnsupportedVideoService,
        }
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
                const key = self.host.readKeyBlocking();
                self.cpu.setAh(key.scan);
                self.cpu.setAl(key.ascii);
                self.cpu.flags.zf = 0;
            },
            0x01 => {
                if (self.host.pollKey()) |key| {
                    self.cpu.setAh(key.scan);
                    self.cpu.setAl(key.ascii);
                    self.cpu.flags.zf = 0;
                } else {
                    self.cpu.flags.zf = 1;
                }
            },
            else => return error.UnsupportedKeyboardService,
        }
    }

    fn int21h(self: *InterruptServices) !void {
        switch (self.cpu.ah()) {
            0x09 => {
                const text = try self.mem.sliceZ(self.cpu.ds, self.cpu.dx, '$');
                self.host.writeText(text);
            },
            0x0A => try self.readBufferedLine(),
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
