const std = @import("std");

pub const DesAbiError = error{
    InvalidMaskConstant,
    InvalidTypeWidth,
    InvalidDesLayout,
    InvalidDes3Layout,
    InvalidDesCbcLayout,
};

/// Pseudo-Windows snapshot. Constants and layouts derived from the C++ DES
/// headers (LLP64 assumptions; no LP64/LLP64 divergence expected here).
pub const WindowsDesSpec = struct {
    // des_data.h masks
    pub const LB32_MASK: u32 = 0x00000001;
    pub const LB64_MASK: u64 = 0x0000000000000001;
    pub const L64_MASK: u64 = 0x00000000ffffffff;

    // typedef widths
    pub const sizeof_ui8: comptime_int = 1;
    pub const sizeof_ui32: comptime_int = 4;
    pub const sizeof_ui64: comptime_int = 8;

    // class DES layout (sub_key[16])
    pub const sizeof_DES: comptime_int = 16 * sizeof_ui64;
    pub const offsetof_DES_sub_key: comptime_int = 0;

    // class DES3 layout (DES des[3])
    pub const sizeof_DES3: comptime_int = 3 * sizeof_DES;

    // class DESCBC layout (DES des; ui64 iv; ui64 last_block)
    pub const sizeof_DESCBC: comptime_int = sizeof_DES + 2 * sizeof_ui64;
    pub const offsetof_DESCBC_des: comptime_int = 0;
    pub const offsetof_DESCBC_iv: comptime_int = sizeof_DES;
    pub const offsetof_DESCBC_last_block: comptime_int = sizeof_DES + sizeof_ui64;
};

/// macOS host snapshot. These should be convergent with the Windows spec.
pub const MacOsDes = struct {
    pub const sizeof_u8 = @sizeOf(u8);
    pub const sizeof_u32 = @sizeOf(u32);
    pub const sizeof_u64 = @sizeOf(u64);
};

const DesState = extern struct {
    sub_key: [16]u64,
};

const Des3State = extern struct {
    des: [3]DesState,
};

const DesCbcState = extern struct {
    des: DesState,
    iv: u64,
    last_block: u64,
};

pub fn validateDesConstants() DesAbiError!void {
    if (WindowsDesSpec.LB32_MASK != 0x00000001) return error.InvalidMaskConstant;
    if (WindowsDesSpec.LB64_MASK != 0x0000000000000001) return error.InvalidMaskConstant;
    if (WindowsDesSpec.L64_MASK != 0x00000000ffffffff) return error.InvalidMaskConstant;
}

pub fn validateDesTypeWidths() DesAbiError!void {
    if (MacOsDes.sizeof_u8 != WindowsDesSpec.sizeof_ui8) return error.InvalidTypeWidth;
    if (MacOsDes.sizeof_u32 != WindowsDesSpec.sizeof_ui32) return error.InvalidTypeWidth;
    if (MacOsDes.sizeof_u64 != WindowsDesSpec.sizeof_ui64) return error.InvalidTypeWidth;
}

pub fn validateDesLayouts() DesAbiError!void {
    if (@sizeOf(DesState) != WindowsDesSpec.sizeof_DES) return error.InvalidDesLayout;
    if (@offsetOf(DesState, "sub_key") != WindowsDesSpec.offsetof_DES_sub_key)
        return error.InvalidDesLayout;

    if (@sizeOf(Des3State) != WindowsDesSpec.sizeof_DES3) return error.InvalidDes3Layout;

    if (@sizeOf(DesCbcState) != WindowsDesSpec.sizeof_DESCBC) return error.InvalidDesCbcLayout;
    if (@offsetOf(DesCbcState, "des") != WindowsDesSpec.offsetof_DESCBC_des)
        return error.InvalidDesCbcLayout;
    if (@offsetOf(DesCbcState, "iv") != WindowsDesSpec.offsetof_DESCBC_iv)
        return error.InvalidDesCbcLayout;
    if (@offsetOf(DesCbcState, "last_block") != WindowsDesSpec.offsetof_DESCBC_last_block)
        return error.InvalidDesCbcLayout;
}

pub fn validateAll() DesAbiError!void {
    try validateDesConstants();
    try validateDesTypeWidths();
    try validateDesLayouts();
}

/// Returns 0 on success, non-zero error code on failure.
pub export fn rosette_validate_des() c_int {
    validateAll() catch |err| return switch (err) {
        error.InvalidMaskConstant => 1,
        error.InvalidTypeWidth => 2,
        error.InvalidDesLayout => 3,
        error.InvalidDes3Layout => 4,
        error.InvalidDesCbcLayout => 5,
    };
    return 0;
}

/// returns a null-terminated string
pub export fn rosette_des_failure_name(code: c_int) [*:0]const u8 {
    return switch (code) {
        0 => "OK",
        1 => "InvalidMaskConstant",
        2 => "InvalidTypeWidth",
        3 => "InvalidDesLayout",
        4 => "InvalidDes3Layout",
        5 => "InvalidDesCbcLayout",
        else => "UnknownDesFailure",
    };
}

pub fn reportDesSpec() void {
    std.debug.print(
        \\
        \\================================================================================
        \\ DES ABI Specification Table
        \\================================================================================
        \\ Masks:
        \\   LB32_MASK = 0x{x:0>8}
        \\   LB64_MASK = 0x{x:0>16}
        \\   L64_MASK  = 0x{x:0>16}
        \\
        \\ Layouts (LLP64):
        \\   sizeof(DES)    = {d}
        \\   sizeof(DES3)   = {d}
        \\   sizeof(DESCBC) = {d}
        \\   DESCBC offsets: des={d} iv={d} last_block={d}
        \\
    , .{
        WindowsDesSpec.LB32_MASK,
        WindowsDesSpec.LB64_MASK,
        WindowsDesSpec.L64_MASK,
        WindowsDesSpec.sizeof_DES,
        WindowsDesSpec.sizeof_DES3,
        WindowsDesSpec.sizeof_DESCBC,
        WindowsDesSpec.offsetof_DESCBC_des,
        WindowsDesSpec.offsetof_DESCBC_iv,
        WindowsDesSpec.offsetof_DESCBC_last_block,
    });
}

/// print the full DES ABI spec table.
pub export fn rosette_print_des_spec() void {
    reportDesSpec();
}

test "DES ABI spec matches expected values" {
    reportDesSpec();
    try validateAll();
}
