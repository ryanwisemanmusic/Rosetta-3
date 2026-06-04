const runtime_abi = @import("runtime_abi_handshake");
const bridge = @import("bridge_dos_runtime");

var sequence: u64 = 0;

fn reportShadow(scope: []const u8, seq: u64, kind: bridge.DosSemanticKind, major: u64, minor: u64, value0: u64, value1: u64, value2: u64, value3: u64) void {
    var target = bridge.makeDosEvent(.arm64, seq, scope, kind);
    target.major = major;
    target.minor = minor;
    target.value0 = value0;
    target.value1 = value1;
    target.value2 = value2;
    target.value3 = value3;
    bridge.reportDosEvent(target, noopContext);
}

pub fn logPsp(scope: []const u8, psp_segment: u16, env_segment: u16, command_tail_len: u8, dta_segment: u16, dta_offset: u16) void {
    sequence += 1;
    runtime_abi.common.writeLine(
        "[dos-psp] scope={s} seq={d} psp=0x{x} env=0x{x} cmdlen={d} dta={x}:{x}\n",
        .{ scope, sequence, psp_segment, env_segment, command_tail_len, dta_segment, dta_offset },
    );
    var source = bridge.makeDosEvent(.dos, sequence, scope, .psp);
    source.major = psp_segment;
    source.minor = env_segment;
    source.value0 = command_tail_len;
    source.value1 = dta_segment;
    source.value2 = dta_offset;
    source.value3 = ((@as(u64, psp_segment) << 16) | dta_offset);
    bridge.reportDosEvent(source, noopContext);
    reportShadow(scope, sequence, .psp, source.major, source.minor, source.value0, source.value1, source.value2, source.value3);
}

pub fn logMemoryMap(scope: []const u8, ivt_base: u32, bda_base: u32, vga_base: u32, memory_len: usize) void {
    sequence += 1;
    runtime_abi.common.writeLine(
        "[dos-psp] scope={s} seq={d} ivt=0x{x} bda=0x{x} vga=0x{x} mem={d}\n",
        .{ scope, sequence, ivt_base, bda_base, vga_base, memory_len },
    );
    var source = bridge.makeDosEvent(.dos, sequence, scope, .memory_map);
    source.major = ivt_base;
    source.minor = bda_base;
    source.value0 = vga_base;
    source.value1 = memory_len;
    bridge.reportDosEvent(source, noopContext);
    reportShadow(scope, sequence, .memory_map, source.major, source.minor, source.value0, source.value1, source.value2, source.value3);
}

pub fn logMzLoad(scope: []const u8, load_segment: u16, entry_cs: u16, entry_ip: u16, stack_ss: u16, stack_sp: u16) void {
    sequence += 1;
    runtime_abi.common.writeLine(
        "[dos-psp] scope={s} seq={d} mz loadseg=0x{x} entry={x}:{x} stack={x}:{x}\n",
        .{ scope, sequence, load_segment, entry_cs, entry_ip, stack_ss, stack_sp },
    );
    var source = bridge.makeDosEvent(.dos, sequence, scope, .mz_load);
    source.major = load_segment;
    source.minor = entry_cs;
    source.value0 = entry_ip;
    source.value1 = stack_ss;
    source.value2 = stack_sp;
    bridge.reportDosEvent(source, noopContext);
    reportShadow(scope, sequence, .mz_load, source.major, source.minor, source.value0, source.value1, source.value2, source.value3);
}

fn noopContext(_: []const u8) void {}
