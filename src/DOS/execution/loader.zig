const std = @import("std");
const cpu_mod = @import("cpu_state.zig");
const mem_mod = @import("segmented_memory.zig");

pub const ImageKind = enum {
    source_reference,
    com,
    mz,
};

pub const LoadedProgram = struct {
    kind: ImageKind,
    psp_segment: u16,
    load_segment: u16,
    entry_cs: u16,
    entry_ip: u16,
    stack_ss: u16,
    stack_sp: u16,
};

pub fn initPsp(mem: *mem_mod.RealModeMemory, psp_segment: u16) !void {
    try mem.fill(psp_segment, 0x0000, 256, 0);
    try mem.write8(psp_segment, 0x0000, 0xCD);
    try mem.write8(psp_segment, 0x0001, 0x20);
}

pub fn loadCom(
    mem: *mem_mod.RealModeMemory,
    cpu: *cpu_mod.CpuState,
    image: []const u8,
    load_segment: u16,
) !LoadedProgram {
    try initPsp(mem, load_segment);
    try mem.writeBytes(load_segment, 0x0100, image);

    cpu.cs = load_segment;
    cpu.ds = load_segment;
    cpu.es = load_segment;
    cpu.ss = load_segment;
    cpu.ip = 0x0100;
    cpu.sp = 0xFFFE;

    return .{
        .kind = .com,
        .psp_segment = load_segment,
        .load_segment = load_segment,
        .entry_cs = load_segment,
        .entry_ip = 0x0100,
        .stack_ss = load_segment,
        .stack_sp = 0xFFFE,
    };
}

pub fn loadSourceReference(
    mem: *mem_mod.RealModeMemory,
    cpu: *cpu_mod.CpuState,
    load_segment: u16,
) !LoadedProgram {
    try initPsp(mem, load_segment);
    cpu.cs = load_segment;
    cpu.ds = load_segment;
    cpu.es = load_segment;
    cpu.ss = load_segment;
    cpu.ip = 0x0100;
    cpu.sp = 0xFFFE;
    return .{
        .kind = .source_reference,
        .psp_segment = load_segment,
        .load_segment = load_segment,
        .entry_cs = load_segment,
        .entry_ip = 0x0100,
        .stack_ss = load_segment,
        .stack_sp = 0xFFFE,
    };
}

test "com loader initializes tiny model state" {
    var cpu: cpu_mod.CpuState = .{};
    var mem = try mem_mod.RealModeMemory.initDefault(std.testing.allocator);
    defer mem.deinit();

    const loaded = try loadCom(&mem, &cpu, "ABC", 0x1200);
    try std.testing.expectEqual(ImageKind.com, loaded.kind);
    try std.testing.expectEqual(@as(u16, 0x1200), cpu.cs);
    try std.testing.expectEqual(@as(u16, 0x0100), cpu.ip);
    try std.testing.expectEqual(@as(u8, 'A'), try mem.read8(0x1200, 0x0100));
}
