const std = @import("std");

pub const FxaaError = error{
    InvalidQualityPreset,
    InvalidConsoleConstant,
    InvalidLumaCoefficient,
    InvalidAlgorithmConstant,
    InvalidDefaultToggle,
    InvalidQualityPresetCount,
    InvalidStepOrder,
    InvalidStepSize,
};

/// Pseudo-Windows snapshot. All algorithm constants and configuration
/// defaults sourced from FXAA3_11.h (NVIDIA FXAA 3.11). Since FXAA is
/// a shader algorithm (HLSL/GLSL) rather than C++, there is no LP64 vs
/// LLP64 type divergence — every value is convergent across platforms.
pub const WindowsFxaaSpec = struct {
    pub const FXAA_PC: u32 = 0;
    pub const FXAA_PC_CONSOLE: u32 = 0;
    pub const FXAA_PS3: u32 = 0;
    pub const FXAA_360: u32 = 0;
    pub const FXAA_360_OPT: u32 = 0;
    pub const FXAA_GLSL_120: u32 = 0;
    pub const FXAA_GLSL_130: u32 = 0;
    pub const FXAA_HLSL_3: u32 = 0;
    pub const FXAA_HLSL_4: u32 = 0;
    pub const FXAA_HLSL_5: u32 = 0;

    pub const FXAA_GREEN_AS_LUMA: u32 = 0;
    pub const FXAA_EARLY_EXIT: u32 = 1;
    pub const FXAA_DISCARD: u32 = 0;
    pub const FXAA_FAST_PIXEL_OFFSET: u32 = 0;
    pub const FXAA_GATHER4_ALPHA: u32 = 0;

    pub const FXAA_QUALITY__PRESET: u32 = 12;

    pub const FXAA_CONSOLE__PS3_EDGE_SHARPNESS: f32 = 8.0;
    pub const FXAA_CONSOLE__PS3_EDGE_THRESHOLD: f32 = 0.125;

    pub const LUMA_COEFF_R: f32 = 0.299;
    pub const LUMA_COEFF_G: f32 = 0.587;
    pub const LUMA_COEFF_B: f32 = 0.114;

    pub const SUBPIX_SCALE: f32 = 1.0 / 12.0;
    pub const GRADIENT_SCALE: f32 = 1.0 / 4.0;
    pub const CONSOLE_NE_BIAS_384: f32 = 1.0 / 384.0;
    pub const CONSOLE_NE_BIAS_512: f32 = 1.0 / 512.0;
    pub const SUBPIX_D_MUL: f32 = -2.0;
    pub const SUBPIX_D_ADD: f32 = 3.0;

    pub const FXAA_CONSOLE_360_CONST_DIR_X: f32 = 1.0;
    pub const FXAA_CONSOLE_360_CONST_DIR_Y: f32 = -1.0;
    pub const FXAA_CONSOLE_360_CONST_DIR_Z: f32 = 0.25;
    pub const FXAA_CONSOLE_360_CONST_DIR_W: f32 = -0.25;

    pub const QualityPreset = struct {
        preset_id: u32,
        substep_count: u32,
        steps: []const f32,
    };

    // Medium dither presets (10-15): faster, more dither
    pub const preset_10 = QualityPreset{ .preset_id = 10, .substep_count = 3, .steps = &[_]f32{ 1.5, 3.0, 12.0 } };
    pub const preset_11 = QualityPreset{ .preset_id = 11, .substep_count = 4, .steps = &[_]f32{ 1.0, 1.5, 3.0, 12.0 } };
    pub const preset_12 = QualityPreset{ .preset_id = 12, .substep_count = 5, .steps = &[_]f32{ 1.0, 1.5, 2.0, 4.0, 12.0 } };
    pub const preset_13 = QualityPreset{ .preset_id = 13, .substep_count = 6, .steps = &[_]f32{ 1.0, 1.5, 2.0, 2.0, 4.0, 12.0 } };
    pub const preset_14 = QualityPreset{ .preset_id = 14, .substep_count = 7, .steps = &[_]f32{ 1.0, 1.5, 2.0, 2.0, 2.0, 4.0, 12.0 } };
    pub const preset_15 = QualityPreset{ .preset_id = 15, .substep_count = 8, .steps = &[_]f32{ 1.0, 1.5, 2.0, 2.0, 2.0, 2.0, 4.0, 12.0 } };

    // Low dither presets (20-29): less dither, more expensive
    pub const preset_20 = QualityPreset{ .preset_id = 20, .substep_count = 3, .steps = &[_]f32{ 1.5, 2.0, 8.0 } };
    pub const preset_21 = QualityPreset{ .preset_id = 21, .substep_count = 4, .steps = &[_]f32{ 1.0, 1.5, 2.0, 8.0 } };
    pub const preset_22 = QualityPreset{ .preset_id = 22, .substep_count = 5, .steps = &[_]f32{ 1.0, 1.5, 2.0, 2.0, 8.0 } };
    pub const preset_23 = QualityPreset{ .preset_id = 23, .substep_count = 6, .steps = &[_]f32{ 1.0, 1.5, 2.0, 2.0, 2.0, 8.0 } };
    pub const preset_24 = QualityPreset{ .preset_id = 24, .substep_count = 7, .steps = &[_]f32{ 1.0, 1.5, 2.0, 2.0, 2.0, 3.0, 8.0 } };
    pub const preset_25 = QualityPreset{ .preset_id = 25, .substep_count = 8, .steps = &[_]f32{ 1.0, 1.5, 2.0, 2.0, 2.0, 2.0, 4.0, 8.0 } };
    pub const preset_26 = QualityPreset{ .preset_id = 26, .substep_count = 9, .steps = &[_]f32{ 1.0, 1.5, 2.0, 2.0, 2.0, 2.0, 2.0, 4.0, 8.0 } };
    pub const preset_27 = QualityPreset{ .preset_id = 27, .substep_count = 10, .steps = &[_]f32{ 1.0, 1.5, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 4.0, 8.0 } };
    pub const preset_28 = QualityPreset{ .preset_id = 28, .substep_count = 11, .steps = &[_]f32{ 1.0, 1.5, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 4.0, 8.0 } };
    pub const preset_29 = QualityPreset{ .preset_id = 29, .substep_count = 12, .steps = &[_]f32{ 1.0, 1.5, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 2.0, 4.0, 8.0 } };

    // Extreme quality preset (39): no dither
    pub const preset_39 = QualityPreset{ .preset_id = 39, .substep_count = 12, .steps = &[_]f32{ 1.0, 1.0, 1.0, 1.0, 1.0, 1.5, 2.0, 2.0, 2.0, 2.0, 4.0, 8.0 } };

    pub const all_presets = [_]QualityPreset{
        preset_10, preset_11, preset_12, preset_13, preset_14, preset_15,
        preset_20, preset_21, preset_22, preset_23, preset_24, preset_25,
        preset_26, preset_27, preset_28, preset_29, preset_39,
    };
};

/// macOS host snapshot. FXAA is a pure shader algorithm with no
/// platform-dependent types — all values are convergent with the
/// Windows spec.
pub const MacOsFxaa = struct {
    pub const sizeof_f32 = @sizeOf(f32);
};

pub fn validateFxaaPlatformDefaults() FxaaError!void {
    if (WindowsFxaaSpec.FXAA_PC != 0) return error.InvalidDefaultToggle;
    if (WindowsFxaaSpec.FXAA_PC_CONSOLE != 0) return error.InvalidDefaultToggle;
    if (WindowsFxaaSpec.FXAA_PS3 != 0) return error.InvalidDefaultToggle;
    if (WindowsFxaaSpec.FXAA_360 != 0) return error.InvalidDefaultToggle;
    if (WindowsFxaaSpec.FXAA_360_OPT != 0) return error.InvalidDefaultToggle;
    if (WindowsFxaaSpec.FXAA_GLSL_120 != 0) return error.InvalidDefaultToggle;
    if (WindowsFxaaSpec.FXAA_GLSL_130 != 0) return error.InvalidDefaultToggle;
    if (WindowsFxaaSpec.FXAA_HLSL_3 != 0) return error.InvalidDefaultToggle;
    if (WindowsFxaaSpec.FXAA_HLSL_4 != 0) return error.InvalidDefaultToggle;
    if (WindowsFxaaSpec.FXAA_HLSL_5 != 0) return error.InvalidDefaultToggle;
}

pub fn validateFxaaFeatureToggles() FxaaError!void {
    if (WindowsFxaaSpec.FXAA_GREEN_AS_LUMA != 0) return error.InvalidDefaultToggle;
    if (WindowsFxaaSpec.FXAA_EARLY_EXIT != 1) return error.InvalidDefaultToggle;
    if (WindowsFxaaSpec.FXAA_DISCARD != 0) return error.InvalidDefaultToggle;
    if (WindowsFxaaSpec.FXAA_FAST_PIXEL_OFFSET != 0) return error.InvalidDefaultToggle;
    if (WindowsFxaaSpec.FXAA_GATHER4_ALPHA != 0) return error.InvalidDefaultToggle;
}

pub fn validateFxaaAlgorithmConstants() FxaaError!void {
    if (WindowsFxaaSpec.LUMA_COEFF_R != 0.299) return error.InvalidLumaCoefficient;
    if (WindowsFxaaSpec.LUMA_COEFF_G != 0.587) return error.InvalidLumaCoefficient;
    if (WindowsFxaaSpec.LUMA_COEFF_B != 0.114) return error.InvalidLumaCoefficient;

    if (WindowsFxaaSpec.SUBPIX_SCALE != 1.0 / 12.0) return error.InvalidAlgorithmConstant;
    if (WindowsFxaaSpec.GRADIENT_SCALE != 1.0 / 4.0) return error.InvalidAlgorithmConstant;
    if (WindowsFxaaSpec.CONSOLE_NE_BIAS_384 != 1.0 / 384.0) return error.InvalidAlgorithmConstant;
    if (WindowsFxaaSpec.CONSOLE_NE_BIAS_512 != 1.0 / 512.0) return error.InvalidAlgorithmConstant;
    if (WindowsFxaaSpec.SUBPIX_D_MUL != -2.0) return error.InvalidAlgorithmConstant;
    if (WindowsFxaaSpec.SUBPIX_D_ADD != 3.0) return error.InvalidAlgorithmConstant;

    if (WindowsFxaaSpec.FXAA_CONSOLE_360_CONST_DIR_X != 1.0) return error.InvalidConsoleConstant;
    if (WindowsFxaaSpec.FXAA_CONSOLE_360_CONST_DIR_Y != -1.0) return error.InvalidConsoleConstant;
    if (WindowsFxaaSpec.FXAA_CONSOLE_360_CONST_DIR_Z != 0.25) return error.InvalidConsoleConstant;
    if (WindowsFxaaSpec.FXAA_CONSOLE_360_CONST_DIR_W != -0.25) return error.InvalidConsoleConstant;

    if (WindowsFxaaSpec.FXAA_CONSOLE__PS3_EDGE_SHARPNESS != 8.0) return error.InvalidConsoleConstant;
    if (WindowsFxaaSpec.FXAA_CONSOLE__PS3_EDGE_THRESHOLD != 0.125) return error.InvalidConsoleConstant;

    if (WindowsFxaaSpec.FXAA_QUALITY__PRESET != 12) return error.InvalidQualityPreset;
}

pub fn validateFxaaQualityPresets() FxaaError!void {
    if (WindowsFxaaSpec.all_presets.len != 17) return error.InvalidQualityPresetCount;

    for (WindowsFxaaSpec.all_presets) |preset| {
        if (preset.steps.len != preset.substep_count)
            return error.InvalidQualityPreset;

        // Validate step sizes are monotonically non-decreasing (sorted ascending)
        for (preset.steps, 0..) |step, i| {
            if (step <= 0.0) return error.InvalidStepSize;
            if (i > 0 and step < preset.steps[i - 1]) return error.InvalidStepOrder;
        }

        // Validate the final step is always the max (terminator)
        const last = preset.steps[preset.steps.len - 1];
        if (preset.preset_id < 20 and last != 12.0) return error.InvalidStepSize;
        if (preset.preset_id >= 20 and preset.preset_id != 39 and last != 8.0) return error.InvalidStepSize;
        if (preset.preset_id == 39 and last != 8.0) return error.InvalidStepSize;
    }
}

pub fn validateAll() FxaaError!void {
    try validateFxaaPlatformDefaults();
    try validateFxaaFeatureToggles();
    try validateFxaaAlgorithmConstants();
    try validateFxaaQualityPresets();
}

/// Returns 0 on success, non-zero error code on failure.
pub export fn rosetta3_validate_fxaa() c_int {
    validateAll() catch |err| return switch (err) {
        error.InvalidQualityPreset => 1,
        error.InvalidConsoleConstant => 2,
        error.InvalidLumaCoefficient => 3,
        error.InvalidAlgorithmConstant => 4,
        error.InvalidDefaultToggle => 5,
        error.InvalidQualityPresetCount => 6,
        error.InvalidStepOrder => 7,
        error.InvalidStepSize => 8,
    };
    return 0;
}

/// returns a null-terminated string for a failure code.
pub export fn rosetta3_fxaa_failure_name(code: c_int) [*:0]const u8 {
    return switch (code) {
        0 => "OK",
        1 => "InvalidQualityPreset",
        2 => "InvalidConsoleConstant",
        3 => "InvalidLumaCoefficient",
        4 => "InvalidAlgorithmConstant",
        5 => "InvalidDefaultToggle",
        6 => "InvalidQualityPresetCount",
        7 => "InvalidStepOrder",
        8 => "InvalidStepSize",
        else => "UnknownFxaaFailure",
    };
}

pub fn reportFxaaSpec() void {
    std.debug.print(
        \\
        \\================================================================================
        \\ FXAA 3.11 Specification Table (NVIDIA)
        \\================================================================================
        \\ Default quality preset: {d}
        \\ Feature toggles:
        \\   GREEN_AS_LUMA       = {d}
        \\   EARLY_EXIT          = {d}
        \\   DISCARD             = {d}
        \\   FAST_PIXEL_OFFSET   = {d}
        \\   GATHER4_ALPHA       = {d}
        \\
        \\ Console PS3 constants:
        \\   EDGE_SHARPNESS      = {d:.1}
        \\   EDGE_THRESHOLD      = {d:.3}
        \\
        \\ Console 360 constants:
        \\   ConstDir            = ({d:.2}, {d:.2}, {d:.2}, {d:.2})
        \\
        \\ Luma coefficients (BT.601):
        \\   R = {d:.3}, G = {d:.3}, B = {d:.3}
        \\
        \\ Algorithm constants:
        \\   subpixScale         = {d:.8}  (1/12)
        \\   gradientScale       = {d:.2}   (1/4)
        \\   subpixD             = {d:.0}*subpixC + {d:.0}
        \\
    , .{
        WindowsFxaaSpec.FXAA_QUALITY__PRESET,
        WindowsFxaaSpec.FXAA_GREEN_AS_LUMA,
        WindowsFxaaSpec.FXAA_EARLY_EXIT,
        WindowsFxaaSpec.FXAA_DISCARD,
        WindowsFxaaSpec.FXAA_FAST_PIXEL_OFFSET,
        WindowsFxaaSpec.FXAA_GATHER4_ALPHA,
        WindowsFxaaSpec.FXAA_CONSOLE__PS3_EDGE_SHARPNESS,
        WindowsFxaaSpec.FXAA_CONSOLE__PS3_EDGE_THRESHOLD,
        WindowsFxaaSpec.FXAA_CONSOLE_360_CONST_DIR_X,
        WindowsFxaaSpec.FXAA_CONSOLE_360_CONST_DIR_Y,
        WindowsFxaaSpec.FXAA_CONSOLE_360_CONST_DIR_Z,
        WindowsFxaaSpec.FXAA_CONSOLE_360_CONST_DIR_W,
        WindowsFxaaSpec.LUMA_COEFF_R,
        WindowsFxaaSpec.LUMA_COEFF_G,
        WindowsFxaaSpec.LUMA_COEFF_B,
        WindowsFxaaSpec.SUBPIX_SCALE,
        WindowsFxaaSpec.GRADIENT_SCALE,
        WindowsFxaaSpec.SUBPIX_D_MUL,
        WindowsFxaaSpec.SUBPIX_D_ADD,
    });

    std.debug.print(
        \\ Quality presets:
        \\   ID  | PS | Step sizes
        \\ ------+----+----------------------------------------
    , .{});
    for (WindowsFxaaSpec.all_presets) |p| {
        std.debug.print("   {d:3} | {d:2} |", .{ p.preset_id, p.substep_count });
        for (p.steps) |s| {
            std.debug.print(" {d:4.1}", .{s});
        }
        std.debug.print("\n", .{});
    }

    std.debug.print(
        \\
        \\================================================================================
        \\
    , .{});
}

pub export fn rosetta3_print_fxaa_spec() void {
    reportFxaaSpec();
}

test "FXAA 3.11 spec matches expected values" {
    reportFxaaSpec();
    try validateAll();
}
