const std = @import("std");

pub const MicroprofileError = error{
    InvalidTokenType,
    InvalidBoxType,
    InvalidDumpType,
    InvalidDrawMask,
    InvalidDrawBarsMask,
    InvalidCounterFormat,
    InvalidCounterFlag,
    InvalidConfigConstant,
    InvalidTimerLayout,
    InvalidCategoryLayout,
    InvalidThreadInfoLayout,
    InvalidMaxConstant,
    InvalidTypeWidth,
    InvalidFunctionPtrWidth,
};

/// Pseudo-Windows snapshot. All constants and layouts sourced from
/// microprofile.h (MicroProfile profiler, public domain). Since
/// the profiler uses fixed-width integer types throughout, there
/// is no LP64 vs LLP64 type divergence — every value is convergent.
pub const WindowsMicroprofileSpec = struct {
    // ── MicroProfileTokenType ──────────────────────────────────────
    pub const MicroProfileTokenTypeCpu: i32 = 0;
    pub const MicroProfileTokenTypeGpu: i32 = 1;

    // ── MicroProfileBoxType ────────────────────────────────────────
    pub const MicroProfileBoxTypeBar: i32 = 0;
    pub const MicroProfileBoxTypeFlat: i32 = 1;

    // ── MicroProfileDumpType ───────────────────────────────────────
    pub const MicroProfileDumpTypeHtml: i32 = 0;
    pub const MicroProfileDumpTypeCsv: i32 = 1;

    // ── MicroProfileDrawMask ───────────────────────────────────────
    pub const MP_DRAW_OFF: u32 = 0x0;
    pub const MP_DRAW_BARS: u32 = 0x1;
    pub const MP_DRAW_DETAILED: u32 = 0x2;
    pub const MP_DRAW_COUNTERS: u32 = 0x3;
    pub const MP_DRAW_FRAME: u32 = 0x4;
    pub const MP_DRAW_HIDDEN: u32 = 0x5;
    pub const MP_DRAW_SIZE: u32 = 0x6;

    // ── MicroProfileDrawBarsMask ───────────────────────────────────
    pub const MP_DRAW_TIMERS: u32 = 0x1;
    pub const MP_DRAW_AVERAGE: u32 = 0x2;
    pub const MP_DRAW_MAX: u32 = 0x4;
    pub const MP_DRAW_MIN: u32 = 0x8;
    pub const MP_DRAW_CALL_COUNT: u32 = 0x10;
    pub const MP_DRAW_TIMERS_EXCLUSIVE: u32 = 0x20;
    pub const MP_DRAW_AVERAGE_EXCLUSIVE: u32 = 0x40;
    pub const MP_DRAW_MAX_EXCLUSIVE: u32 = 0x80;
    pub const MP_DRAW_META_FIRST: u32 = 0x100;
    pub const MP_DRAW_ALL: u32 = 0xffffffff;

    // ── MicroProfileCounterFormat ──────────────────────────────────
    pub const MICROPROFILE_COUNTER_FORMAT_DEFAULT: i32 = 0;
    pub const MICROPROFILE_COUNTER_FORMAT_BYTES: i32 = 1;

    // ── MicroProfileCounterFlags ───────────────────────────────────
    pub const MICROPROFILE_COUNTER_FLAG_NONE: u32 = 0;
    pub const MICROPROFILE_COUNTER_FLAG_DETAILED: u32 = 0x1;
    pub const MICROPROFILE_COUNTER_FLAG_DETAILED_GRAPH: u32 = 0x2;
    pub const MICROPROFILE_COUNTER_FLAG_HAS_LIMIT: u32 = 0x4;
    pub const MICROPROFILE_COUNTER_FLAG_CLOSED: u32 = 0x8;
    pub const MICROPROFILE_COUNTER_FLAG_MANUAL_SWAP: u32 = 0x10;
    pub const MICROPROFILE_COUNTER_FLAG_LEAF: u32 = 0x20;

    // ── Config limits ──────────────────────────────────────────────
    pub const MICROPROFILE_MAX_GROUPS: u32 = 48;
    pub const MICROPROFILE_MAX_CATEGORIES: u32 = 16;
    pub const MICROPROFILE_MAX_GRAPHS: u32 = 5;
    pub const MICROPROFILE_GRAPH_HISTORY: u32 = 128;
    pub const MICROPROFILE_MAX_TIMERS: u32 = 1024;
    pub const MICROPROFILE_MAX_THREADS: u32 = 32;
    pub const MICROPROFILE_MAX_COUNTERS: u32 = 512;
    pub const MICROPROFILE_MAX_CONTEXT_SWITCH_THREADS: u32 = 256;
    pub const MICROPROFILE_STACK_MAX: u32 = 32;
    pub const MICROPROFILE_META_MAX: u32 = 8;
    pub const MICROPROFILE_LABEL_BUFFER_SIZE: u32 = 1024 << 10;
    pub const MICROPROFILE_GPU_MAX_QUERIES: u32 = 8 << 10;
    pub const MICROPROFILE_GPU_FRAME_DELAY: u32 = 3;
    pub const MICROPROFILE_NAME_MAX_LEN: u32 = 64;
    pub const MICROPROFILE_LABEL_MAX_LEN: u32 = 256;
    pub const MICROPROFILE_WEBSERVER_PORT: u32 = 1338;
    pub const MICROPROFILE_WEBSERVER_FRAMES: u32 = 30;
    pub const MICROPROFILE_PER_THREAD_BUFFER_SIZE: u32 = 2048 << 10;
    pub const MICROPROFILE_PER_THREAD_GPU_BUFFER_SIZE: u32 = 1024 << 10;
    pub const MICROPROFILE_MAX_FRAME_HISTORY: u32 = 512;
    pub const MICROPROFILE_INVALID_TICK: u64 = 0xFFFFFFFFFFFFFFFF;
    pub const MICROPROFILE_INVALID_TOKEN: u64 = 0;

    // ── MicroProfileTimer layout ───────────────────────────────────
    pub const sizeof_MicroProfileTimer: comptime_int = 16;
    pub const offsetof_nTicks: comptime_int = 0;
    pub const offsetof_nCount: comptime_int = 8;

    // ── MicroProfileThreadInfo layout ──────────────────────────────
    pub const sizeof_MicroProfileThreadInfo: comptime_int = 8;
    pub const offsetof_nProcessId: comptime_int = 0;
    pub const offsetof_nThreadId: comptime_int = 4;

    // ── Types ──────────────────────────────────────────────────────
    pub const sizeof_MicroProfileToken: comptime_int = 8;
    pub const sizeof_MicroProfileLogEntry: comptime_int = 8;
};

/// macOS host snapshot. All MicroProfile constants use fixed-width
/// types — no LP64/LLP64 divergence expected.  Type-width checks
/// ensure convergence of fundamental types.
pub const MacOsMicroprofile = struct {
    pub const sizeof_u32 = @sizeOf(u32);
    pub const sizeof_u64 = @sizeOf(u64);
    pub const sizeof_ptr = @sizeOf(*anyopaque);
};

const MicroProfileTimerState = extern struct {
    nTicks: u64,
    nCount: u32,
};

const MicroProfileThreadInfoState = extern struct {
    nProcessId: u32,
    nThreadId: u32,
};

pub fn validateMicroprofileTokenType() MicroprofileError!void {
    if (WindowsMicroprofileSpec.MicroProfileTokenTypeCpu != 0) return error.InvalidTokenType;
    if (WindowsMicroprofileSpec.MicroProfileTokenTypeGpu != 1) return error.InvalidTokenType;
}

pub fn validateMicroprofileBoxType() MicroprofileError!void {
    if (WindowsMicroprofileSpec.MicroProfileBoxTypeBar != 0) return error.InvalidBoxType;
    if (WindowsMicroprofileSpec.MicroProfileBoxTypeFlat != 1) return error.InvalidBoxType;
}

pub fn validateMicroprofileDumpType() MicroprofileError!void {
    if (WindowsMicroprofileSpec.MicroProfileDumpTypeHtml != 0) return error.InvalidDumpType;
    if (WindowsMicroprofileSpec.MicroProfileDumpTypeCsv != 1) return error.InvalidDumpType;
}

pub fn validateMicroprofileDrawMasks() MicroprofileError!void {
    if (WindowsMicroprofileSpec.MP_DRAW_OFF != 0x0) return error.InvalidDrawMask;
    if (WindowsMicroprofileSpec.MP_DRAW_BARS != 0x1) return error.InvalidDrawMask;
    if (WindowsMicroprofileSpec.MP_DRAW_DETAILED != 0x2) return error.InvalidDrawMask;
    if (WindowsMicroprofileSpec.MP_DRAW_COUNTERS != 0x3) return error.InvalidDrawMask;
    if (WindowsMicroprofileSpec.MP_DRAW_FRAME != 0x4) return error.InvalidDrawMask;
    if (WindowsMicroprofileSpec.MP_DRAW_HIDDEN != 0x5) return error.InvalidDrawMask;
    if (WindowsMicroprofileSpec.MP_DRAW_SIZE != 0x6) return error.InvalidDrawMask;

    if (WindowsMicroprofileSpec.MP_DRAW_TIMERS != 0x1) return error.InvalidDrawBarsMask;
    if (WindowsMicroprofileSpec.MP_DRAW_AVERAGE != 0x2) return error.InvalidDrawBarsMask;
    if (WindowsMicroprofileSpec.MP_DRAW_MAX != 0x4) return error.InvalidDrawBarsMask;
    if (WindowsMicroprofileSpec.MP_DRAW_MIN != 0x8) return error.InvalidDrawBarsMask;
    if (WindowsMicroprofileSpec.MP_DRAW_CALL_COUNT != 0x10) return error.InvalidDrawBarsMask;
    if (WindowsMicroprofileSpec.MP_DRAW_TIMERS_EXCLUSIVE != 0x20) return error.InvalidDrawBarsMask;
    if (WindowsMicroprofileSpec.MP_DRAW_AVERAGE_EXCLUSIVE != 0x40) return error.InvalidDrawBarsMask;
    if (WindowsMicroprofileSpec.MP_DRAW_MAX_EXCLUSIVE != 0x80) return error.InvalidDrawBarsMask;
    if (WindowsMicroprofileSpec.MP_DRAW_META_FIRST != 0x100) return error.InvalidDrawBarsMask;
    if (WindowsMicroprofileSpec.MP_DRAW_ALL != 0xffffffff) return error.InvalidDrawBarsMask;
}

pub fn validateMicroprofileCounterEnums() MicroprofileError!void {
    if (WindowsMicroprofileSpec.MICROPROFILE_COUNTER_FORMAT_DEFAULT != 0) return error.InvalidCounterFormat;
    if (WindowsMicroprofileSpec.MICROPROFILE_COUNTER_FORMAT_BYTES != 1) return error.InvalidCounterFormat;

    if (WindowsMicroprofileSpec.MICROPROFILE_COUNTER_FLAG_NONE != 0) return error.InvalidCounterFlag;
    if (WindowsMicroprofileSpec.MICROPROFILE_COUNTER_FLAG_DETAILED != 0x1) return error.InvalidCounterFlag;
    if (WindowsMicroprofileSpec.MICROPROFILE_COUNTER_FLAG_DETAILED_GRAPH != 0x2) return error.InvalidCounterFlag;
    if (WindowsMicroprofileSpec.MICROPROFILE_COUNTER_FLAG_HAS_LIMIT != 0x4) return error.InvalidCounterFlag;
    if (WindowsMicroprofileSpec.MICROPROFILE_COUNTER_FLAG_CLOSED != 0x8) return error.InvalidCounterFlag;
    if (WindowsMicroprofileSpec.MICROPROFILE_COUNTER_FLAG_MANUAL_SWAP != 0x10) return error.InvalidCounterFlag;
    if (WindowsMicroprofileSpec.MICROPROFILE_COUNTER_FLAG_LEAF != 0x20) return error.InvalidCounterFlag;
}

pub fn validateMicroprofileConfigLimits() MicroprofileError!void {
    if (WindowsMicroprofileSpec.MICROPROFILE_MAX_GROUPS != 48) return error.InvalidMaxConstant;
    if (WindowsMicroprofileSpec.MICROPROFILE_MAX_CATEGORIES != 16) return error.InvalidMaxConstant;
    if (WindowsMicroprofileSpec.MICROPROFILE_MAX_GRAPHS != 5) return error.InvalidMaxConstant;
    if (WindowsMicroprofileSpec.MICROPROFILE_MAX_TIMERS != 1024) return error.InvalidMaxConstant;
    if (WindowsMicroprofileSpec.MICROPROFILE_MAX_THREADS != 32) return error.InvalidMaxConstant;
    if (WindowsMicroprofileSpec.MICROPROFILE_MAX_COUNTERS != 512) return error.InvalidMaxConstant;
    if (WindowsMicroprofileSpec.MICROPROFILE_STACK_MAX != 32) return error.InvalidMaxConstant;
    if (WindowsMicroprofileSpec.MICROPROFILE_META_MAX != 8) return error.InvalidMaxConstant;
    if (WindowsMicroprofileSpec.MICROPROFILE_GPU_FRAME_DELAY != 3) return error.InvalidMaxConstant;
    if (WindowsMicroprofileSpec.MICROPROFILE_NAME_MAX_LEN != 64) return error.InvalidMaxConstant;
    if (WindowsMicroprofileSpec.MICROPROFILE_LABEL_MAX_LEN != 256) return error.InvalidMaxConstant;
    if (WindowsMicroprofileSpec.MICROPROFILE_WEBSERVER_PORT != 1338) return error.InvalidMaxConstant;
    if (WindowsMicroprofileSpec.MICROPROFILE_MAX_FRAME_HISTORY != 512) return error.InvalidMaxConstant;
    if (WindowsMicroprofileSpec.MICROPROFILE_INVALID_TOKEN != 0) return error.InvalidMaxConstant;
}

pub fn validateMicroprofileLayouts() MicroprofileError!void {
    if (@sizeOf(MicroProfileTimerState) != WindowsMicroprofileSpec.sizeof_MicroProfileTimer)
        return error.InvalidTimerLayout;
    if (@offsetOf(MicroProfileTimerState, "nTicks") != WindowsMicroprofileSpec.offsetof_nTicks)
        return error.InvalidTimerLayout;
    if (@offsetOf(MicroProfileTimerState, "nCount") != WindowsMicroprofileSpec.offsetof_nCount)
        return error.InvalidTimerLayout;

    if (@sizeOf(MicroProfileThreadInfoState) != WindowsMicroprofileSpec.sizeof_MicroProfileThreadInfo)
        return error.InvalidThreadInfoLayout;
    if (@offsetOf(MicroProfileThreadInfoState, "nProcessId") != WindowsMicroprofileSpec.offsetof_nProcessId)
        return error.InvalidThreadInfoLayout;
    if (@offsetOf(MicroProfileThreadInfoState, "nThreadId") != WindowsMicroprofileSpec.offsetof_nThreadId)
        return error.InvalidThreadInfoLayout;
}

pub fn validateMicroprofileTypeWidths() MicroprofileError!void {
    if (MacOsMicroprofile.sizeof_u32 != 4) return error.InvalidTypeWidth;
    if (MacOsMicroprofile.sizeof_u64 != 8) return error.InvalidTypeWidth;
    if (MacOsMicroprofile.sizeof_ptr != 8) return error.InvalidFunctionPtrWidth;
}

pub fn validateAll() MicroprofileError!void {
    try validateMicroprofileTokenType();
    try validateMicroprofileBoxType();
    try validateMicroprofileDumpType();
    try validateMicroprofileDrawMasks();
    try validateMicroprofileCounterEnums();
    try validateMicroprofileConfigLimits();
    try validateMicroprofileLayouts();
    try validateMicroprofileTypeWidths();
}

/// Returns 0 on success, non-zero error code on failure.
pub export fn rosetta3_validate_microprofile() c_int {
    validateAll() catch |err| return switch (err) {
        error.InvalidTokenType => 1,
        error.InvalidBoxType => 2,
        error.InvalidDumpType => 3,
        error.InvalidDrawMask => 4,
        error.InvalidDrawBarsMask => 5,
        error.InvalidCounterFormat => 6,
        error.InvalidCounterFlag => 7,
        error.InvalidConfigConstant => 8,
        error.InvalidTimerLayout => 9,
        error.InvalidCategoryLayout => 10,
        error.InvalidThreadInfoLayout => 11,
        error.InvalidMaxConstant => 12,
        error.InvalidTypeWidth => 13,
        error.InvalidFunctionPtrWidth => 14,
    };
    return 0;
}

/// returns a null-terminated string
pub export fn rosetta3_microprofile_failure_name(code: c_int) [*:0]const u8 {
    return switch (code) {
        0 => "OK",
        1 => "InvalidTokenType",
        2 => "InvalidBoxType",
        3 => "InvalidDumpType",
        4 => "InvalidDrawMask",
        5 => "InvalidDrawBarsMask",
        6 => "InvalidCounterFormat",
        7 => "InvalidCounterFlag",
        8 => "InvalidConfigConstant",
        9 => "InvalidTimerLayout",
        10 => "InvalidCategoryLayout",
        11 => "InvalidThreadInfoLayout",
        12 => "InvalidMaxConstant",
        13 => "InvalidTypeWidth",
        14 => "InvalidFunctionPtrWidth",
        else => "UnknownMicroprofileFailure",
    };
}

pub fn reportMicroprofileSpec() void {
    std.debug.print(
        \\
        \\================================================================================
        \\ MicroProfile Profiler Specification Table
        \\================================================================================
        \\ Token types: CPU={d}, GPU={d}
        \\ Box types:   Bar={d}, Flat={d}
        \\ Dump types:  HTML={d}, CSV={d}
        \\
        \\ Draw masks:
        \\   OFF={x} BARS={x} DETAILED={x}
        \\   COUNTERS={x} FRAME={x} HIDDEN={x} SIZE={x}
        \\
    , .{
        WindowsMicroprofileSpec.MicroProfileTokenTypeCpu,
        WindowsMicroprofileSpec.MicroProfileTokenTypeGpu,
        WindowsMicroprofileSpec.MicroProfileBoxTypeBar,
        WindowsMicroprofileSpec.MicroProfileBoxTypeFlat,
        WindowsMicroprofileSpec.MicroProfileDumpTypeHtml,
        WindowsMicroprofileSpec.MicroProfileDumpTypeCsv,
        WindowsMicroprofileSpec.MP_DRAW_OFF,
        WindowsMicroprofileSpec.MP_DRAW_BARS,
        WindowsMicroprofileSpec.MP_DRAW_DETAILED,
        WindowsMicroprofileSpec.MP_DRAW_COUNTERS,
        WindowsMicroprofileSpec.MP_DRAW_FRAME,
        WindowsMicroprofileSpec.MP_DRAW_HIDDEN,
        WindowsMicroprofileSpec.MP_DRAW_SIZE,
    });

    std.debug.print(
        \\ Draw bars mask bits:
        \\   TIMERS={x} AVERAGE={x} MAX={x} MIN={x}
        \\   CALL_COUNT={x} TIMERS_EXCL={x}
        \\   AVERAGE_EXCL={x} MAX_EXCL={x}
        \\   META_FIRST={x} ALL={x}
        \\
        \\ Counter: DEFAULT={d}, BYTES={d}
        \\ Flags:  NONE={x} DETAILED={x} DETAILED_GRAPH={x}
        \\         HAS_LIMIT={x} CLOSED={x} MANUAL_SWAP={x}
        \\         LEAF={x}
        \\
    , .{
        WindowsMicroprofileSpec.MP_DRAW_TIMERS,
        WindowsMicroprofileSpec.MP_DRAW_AVERAGE,
        WindowsMicroprofileSpec.MP_DRAW_MAX,
        WindowsMicroprofileSpec.MP_DRAW_MIN,
        WindowsMicroprofileSpec.MP_DRAW_CALL_COUNT,
        WindowsMicroprofileSpec.MP_DRAW_TIMERS_EXCLUSIVE,
        WindowsMicroprofileSpec.MP_DRAW_AVERAGE_EXCLUSIVE,
        WindowsMicroprofileSpec.MP_DRAW_MAX_EXCLUSIVE,
        WindowsMicroprofileSpec.MP_DRAW_META_FIRST,
        WindowsMicroprofileSpec.MP_DRAW_ALL,
        WindowsMicroprofileSpec.MICROPROFILE_COUNTER_FORMAT_DEFAULT,
        WindowsMicroprofileSpec.MICROPROFILE_COUNTER_FORMAT_BYTES,
        WindowsMicroprofileSpec.MICROPROFILE_COUNTER_FLAG_NONE,
        WindowsMicroprofileSpec.MICROPROFILE_COUNTER_FLAG_DETAILED,
        WindowsMicroprofileSpec.MICROPROFILE_COUNTER_FLAG_DETAILED_GRAPH,
        WindowsMicroprofileSpec.MICROPROFILE_COUNTER_FLAG_HAS_LIMIT,
        WindowsMicroprofileSpec.MICROPROFILE_COUNTER_FLAG_CLOSED,
        WindowsMicroprofileSpec.MICROPROFILE_COUNTER_FLAG_MANUAL_SWAP,
        WindowsMicroprofileSpec.MICROPROFILE_COUNTER_FLAG_LEAF,
    });

    std.debug.print(
        \\ Limits:
        \\   MAX_GROUPS={d} MAX_CATEGORIES={d} MAX_GRAPHS={d}
        \\   MAX_TIMERS={d} MAX_THREADS={d} MAX_COUNTERS={d}
        \\   STACK_MAX={d} META_MAX={d}
        \\   WEBSERVER_PORT={d} MAX_FRAME_HISTORY={d}
        \\   NAME_MAX_LEN={d} LABEL_MAX_LEN={d}
        \\
        \\ Timer layout (LLP64):
        \\   sizeof(MicroProfileTimer) = {d}
        \\   offsetof(nTicks)          = {d}
        \\   offsetof(nCount)          = {d}
        \\
        \\ ThreadInfo layout:
        \\   sizeof(MicroProfileThreadInfo) = {d}
        \\   offsetof(nProcessId)           = {d}
        \\   offsetof(nThreadId)            = {d}
        \\
        \\================================================================================
        \\
    , .{
        WindowsMicroprofileSpec.MICROPROFILE_MAX_GROUPS,
        WindowsMicroprofileSpec.MICROPROFILE_MAX_CATEGORIES,
        WindowsMicroprofileSpec.MICROPROFILE_MAX_GRAPHS,
        WindowsMicroprofileSpec.MICROPROFILE_MAX_TIMERS,
        WindowsMicroprofileSpec.MICROPROFILE_MAX_THREADS,
        WindowsMicroprofileSpec.MICROPROFILE_MAX_COUNTERS,
        WindowsMicroprofileSpec.MICROPROFILE_STACK_MAX,
        WindowsMicroprofileSpec.MICROPROFILE_META_MAX,
        WindowsMicroprofileSpec.MICROPROFILE_WEBSERVER_PORT,
        WindowsMicroprofileSpec.MICROPROFILE_MAX_FRAME_HISTORY,
        WindowsMicroprofileSpec.MICROPROFILE_NAME_MAX_LEN,
        WindowsMicroprofileSpec.MICROPROFILE_LABEL_MAX_LEN,
        WindowsMicroprofileSpec.sizeof_MicroProfileTimer,
        WindowsMicroprofileSpec.offsetof_nTicks,
        WindowsMicroprofileSpec.offsetof_nCount,
        WindowsMicroprofileSpec.sizeof_MicroProfileThreadInfo,
        WindowsMicroprofileSpec.offsetof_nProcessId,
        WindowsMicroprofileSpec.offsetof_nThreadId,
    });
}

pub export fn rosetta3_print_microprofile_spec() void {
    reportMicroprofileSpec();
}

test "MicroProfile spec matches expected values" {
    reportMicroprofileSpec();
    try validateAll();
}
