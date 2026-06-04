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

fn emit(scope: []const u8, kind: bridge.DosSemanticKind, major: u64, minor: u64, value0: u64, value1: u64, value2: u64, value3: u64) void {
    sequence += 1;
    runtime_abi.common.writeLine(
        "[dos-service] scope={s} seq={d} kind={s} major=0x{x} minor=0x{x} v0=0x{x} v1=0x{x} v2=0x{x} v3=0x{x}\n",
        .{ scope, sequence, @tagName(kind), major, minor, value0, value1, value2, value3 },
    );
    var source = bridge.makeDosEvent(.dos, sequence, scope, kind);
    source.major = major;
    source.minor = minor;
    source.value0 = value0;
    source.value1 = value1;
    source.value2 = value2;
    source.value3 = value3;
    bridge.reportDosEvent(source, noopContext);
    reportShadow(scope, sequence, kind, major, minor, value0, value1, value2, value3);
}

pub fn logInterrupt(scope: []const u8, vector: u8, ah: u8, al: u8) void {
    emit(scope, .interrupt, vector, ah, al, 0, 0, 0);
}

pub fn logDosService(scope: []const u8, ah: u8, al: u8, dx: u16, ds: u16) void {
    emit(scope, .dos_service, ah, al, ds, dx, 0, 0);
}

pub fn logVideoService(scope: []const u8, ah: u8, al: u8, row: u8, col: u8) void {
    emit(scope, .video_service, ah, al, row, col, 0, 0);
}

pub fn logKeyboardService(scope: []const u8, ah: u8, ascii: u8, scan: u8, zf: bool) void {
    emit(scope, .keyboard_service, ah, ascii, scan, @intFromBool(zf), 0, 0);
}

pub fn logTimerService(scope: []const u8, ah: u8, cx: u16, dx: u16) void {
    emit(scope, .timer_service, ah, 0, cx, dx, 0, 0);
}

pub fn logMouseService(scope: []const u8, ax: u16, bx: u16, cx: u16, dx: u16) void {
    emit(scope, .mouse_service, ax, bx, cx, dx, 0, 0);
}

fn noopContext(_: []const u8) void {}
