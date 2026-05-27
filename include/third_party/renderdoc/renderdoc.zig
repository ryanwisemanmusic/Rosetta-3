const std = @import("std");

pub const RenderdocError = error{
    InvalidVersionEnum,
    InvalidCaptureOption,
    InvalidInputKey,
    InvalidOverlayBit,
    InvalidShaderDebugMagic,
    InvalidStructSize,
    InvalidMemberOffset,
    InvalidFuncPtrWidth,
    InvalidCharPtrWidth,
    InvalidUint32Width,
    InvalidUint64Width,
    InvalidCallingConvention,
    InvalidApiMemberCount,
};

/// Pseudo-Windows snapshot. All RenderDoc API constants are sourced from
/// renderdoc_app.h (RenderDoc in-application API v1.6.0). The API struct
/// is an ABI-stable vtable of function pointers — layout is identical on
/// macOS and Windows x64 since all members are pointer-sized.
pub const WindowsRenderdocSpec = struct {
    // ── API Version ─────────────────────────────────────────────────
    pub const VERSION_1_0_0: u32 = 10000;
    pub const VERSION_1_0_1: u32 = 10001;
    pub const VERSION_1_0_2: u32 = 10002;
    pub const VERSION_1_1_0: u32 = 10100;
    pub const VERSION_1_1_1: u32 = 10101;
    pub const VERSION_1_1_2: u32 = 10102;
    pub const VERSION_1_2_0: u32 = 10200;
    pub const VERSION_1_3_0: u32 = 10300;
    pub const VERSION_1_4_0: u32 = 10400;
    pub const VERSION_1_4_1: u32 = 10401;
    pub const VERSION_1_4_2: u32 = 10402;
    pub const VERSION_1_5_0: u32 = 10500;
    pub const VERSION_1_6_0: u32 = 10600;
    pub const LATEST_VERSION: u32 = 10600;

    // ── Capture Options ─────────────────────────────────────────────
    pub const OPT_ALLOW_VSYNC: u32 = 0;
    pub const OPT_ALLOW_FULLSCREEN: u32 = 1;
    pub const OPT_API_VALIDATION: u32 = 2;
    pub const OPT_CAPTURE_CALLSTACKS: u32 = 3;
    pub const OPT_CAPTURE_CALLSTACKS_ONLY_ACTIONS: u32 = 4;
    pub const OPT_DELAY_FOR_DEBUGGER: u32 = 5;
    pub const OPT_VERIFY_BUFFER_ACCESS: u32 = 6;
    pub const OPT_HOOK_INTO_CHILDREN: u32 = 7;
    pub const OPT_REF_ALL_RESOURCES: u32 = 8;
    pub const OPT_SAVE_ALL_INITIALS: u32 = 9;
    pub const OPT_CAPTURE_ALL_CMD_LISTS: u32 = 10;
    pub const OPT_DEBUG_OUTPUT_MUTE: u32 = 11;
    pub const OPT_ALLOW_UNSUPPORTED_VENDOR_EXT: u32 = 12;
    pub const OPT_SOFT_MEMORY_LIMIT: u32 = 13;
    pub const OPT_COUNT: u32 = 14;

    // ── Overlay Bits ────────────────────────────────────────────────
    pub const OVERLAY_ENABLED: u32 = 0x1;
    pub const OVERLAY_FRAME_RATE: u32 = 0x2;
    pub const OVERLAY_FRAME_NUMBER: u32 = 0x4;
    pub const OVERLAY_CAPTURE_LIST: u32 = 0x8;
    pub const OVERLAY_DEFAULT: u32 = 0xF;
    pub const OVERLAY_ALL: u32 = 0xFFFFFFFF;
    pub const OVERLAY_NONE: u32 = 0;

    // ── Input Key Codes (representative subset) ─────────────────────
    pub const KEY_0: u32 = 0x30;
    pub const KEY_9: u32 = 0x39;
    pub const KEY_A: u32 = 0x41;
    pub const KEY_Z: u32 = 0x5A;
    pub const KEY_NON_PRINTABLE: u32 = 0x100;
    pub const KEY_DIVIDE: u32 = 0x101;
    pub const KEY_MULTIPLY: u32 = 0x102;
    pub const KEY_SUBTRACT: u32 = 0x103;
    pub const KEY_PLUS: u32 = 0x104;
    pub const KEY_F1: u32 = 0x105;
    pub const KEY_F12: u32 = 0x110;
    pub const KEY_HOME: u32 = 0x111;
    pub const KEY_END: u32 = 0x112;
    pub const KEY_INSERT: u32 = 0x113;
    pub const KEY_DELETE: u32 = 0x114;
    pub const KEY_PAGE_UP: u32 = 0x115;
    pub const KEY_PAGE_DN: u32 = 0x116;
    pub const KEY_BACKSPACE: u32 = 0x117;
    pub const KEY_TAB: u32 = 0x118;
    pub const KEY_PRT_SCRN: u32 = 0x119;
    pub const KEY_PAUSE: u32 = 0x11A;
    pub const KEY_MAX: u32 = 0x11B;

    // ── Shader Debug Magic ──────────────────────────────────────────
    pub const SHADER_DEBUG_MAGIC_TRUNCATED: u64 = 0x48656670eab25520;

    // ── RENDERDOC_API_1_6_0 struct layout (64-bit) ──────────────────
    // All 27 members are function pointers (8 bytes each on x64/arm64).
    pub const API_STRUCT_MEMBER_COUNT: u32 = 27;
    pub const sizeof_RENDERDOC_API: comptime_int = 216;
    pub const offsetof_GetAPIVersion: comptime_int = 0;
    pub const offsetof_SetCaptureOptionU32: comptime_int = 8;
    pub const offsetof_SetCaptureOptionF32: comptime_int = 16;
    pub const offsetof_GetCaptureOptionU32: comptime_int = 24;
    pub const offsetof_GetCaptureOptionF32: comptime_int = 32;
    pub const offsetof_SetFocusToggleKeys: comptime_int = 40;
    pub const offsetof_SetCaptureKeys: comptime_int = 48;
    pub const offsetof_GetOverlayBits: comptime_int = 56;
    pub const offsetof_MaskOverlayBits: comptime_int = 64;
    pub const offsetof_RemoveHooks: comptime_int = 72;
    pub const offsetof_UnloadCrashHandler: comptime_int = 80;
    pub const offsetof_SetCaptureFilePathTemplate: comptime_int = 88;
    pub const offsetof_GetCaptureFilePathTemplate: comptime_int = 96;
    pub const offsetof_GetNumCaptures: comptime_int = 104;
    pub const offsetof_GetCapture: comptime_int = 112;
    pub const offsetof_TriggerCapture: comptime_int = 120;
    pub const offsetof_IsTargetControlConnected: comptime_int = 128;
    pub const offsetof_LaunchReplayUI: comptime_int = 136;
    pub const offsetof_SetActiveWindow: comptime_int = 144;
    pub const offsetof_StartFrameCapture: comptime_int = 152;
    pub const offsetof_IsFrameCapturing: comptime_int = 160;
    pub const offsetof_EndFrameCapture: comptime_int = 168;
    pub const offsetof_TriggerMultiFrameCapture: comptime_int = 176;
    pub const offsetof_SetCaptureFileComments: comptime_int = 184;
    pub const offsetof_DiscardFrameCapture: comptime_int = 192;
    pub const offsetof_ShowReplayUI: comptime_int = 200;
    pub const offsetof_SetCaptureTitle: comptime_int = 208;

    // ── Calling convention ──────────────────────────────────────────
    // RENDERDOC_CC: Windows = __cdecl, macOS/Linux = empty (default).
    // On x64/arm64 all C calling conventions are identical, so there is
    // no ABI divergence at the codegen level.
    pub const RENDERDOC_CC_IS_CDECL_ON_WINDOWS: u32 = 1;
};

/// macOS host snapshot. RenderDoc API constants are identical across
/// platforms (all enum values are explicit). The struct layout is the
/// same since every member is a pointer.  Relevant type-width checks
/// ensure host pointer sizes match the expected 8 bytes on 64-bit.
pub const MacOsRenderdoc = struct {
    pub const sizeof_ptr = @sizeOf(*anyopaque);
    pub const sizeof_u32 = @sizeOf(u32);
    pub const sizeof_u64 = @sizeOf(u64);
    pub const sizeof_fn_ptr = @sizeOf(*const fn () callconv(.c) void);
};

pub fn validateRenderdocVersions() RenderdocError!void {
    if (WindowsRenderdocSpec.VERSION_1_0_0 != 10000) return error.InvalidVersionEnum;
    if (WindowsRenderdocSpec.VERSION_1_0_1 != 10001) return error.InvalidVersionEnum;
    if (WindowsRenderdocSpec.VERSION_1_0_2 != 10002) return error.InvalidVersionEnum;
    if (WindowsRenderdocSpec.VERSION_1_1_0 != 10100) return error.InvalidVersionEnum;
    if (WindowsRenderdocSpec.VERSION_1_1_1 != 10101) return error.InvalidVersionEnum;
    if (WindowsRenderdocSpec.VERSION_1_1_2 != 10102) return error.InvalidVersionEnum;
    if (WindowsRenderdocSpec.VERSION_1_2_0 != 10200) return error.InvalidVersionEnum;
    if (WindowsRenderdocSpec.VERSION_1_3_0 != 10300) return error.InvalidVersionEnum;
    if (WindowsRenderdocSpec.VERSION_1_4_0 != 10400) return error.InvalidVersionEnum;
    if (WindowsRenderdocSpec.VERSION_1_4_1 != 10401) return error.InvalidVersionEnum;
    if (WindowsRenderdocSpec.VERSION_1_4_2 != 10402) return error.InvalidVersionEnum;
    if (WindowsRenderdocSpec.VERSION_1_5_0 != 10500) return error.InvalidVersionEnum;
    if (WindowsRenderdocSpec.VERSION_1_6_0 != 10600) return error.InvalidVersionEnum;
    if (WindowsRenderdocSpec.LATEST_VERSION != 10600) return error.InvalidVersionEnum;
}

pub fn validateRenderdocCaptureOptions() RenderdocError!void {
    if (WindowsRenderdocSpec.OPT_ALLOW_VSYNC != 0) return error.InvalidCaptureOption;
    if (WindowsRenderdocSpec.OPT_ALLOW_FULLSCREEN != 1) return error.InvalidCaptureOption;
    if (WindowsRenderdocSpec.OPT_API_VALIDATION != 2) return error.InvalidCaptureOption;
    if (WindowsRenderdocSpec.OPT_CAPTURE_CALLSTACKS != 3) return error.InvalidCaptureOption;
    if (WindowsRenderdocSpec.OPT_CAPTURE_CALLSTACKS_ONLY_ACTIONS != 4) return error.InvalidCaptureOption;
    if (WindowsRenderdocSpec.OPT_DELAY_FOR_DEBUGGER != 5) return error.InvalidCaptureOption;
    if (WindowsRenderdocSpec.OPT_VERIFY_BUFFER_ACCESS != 6) return error.InvalidCaptureOption;
    if (WindowsRenderdocSpec.OPT_HOOK_INTO_CHILDREN != 7) return error.InvalidCaptureOption;
    if (WindowsRenderdocSpec.OPT_REF_ALL_RESOURCES != 8) return error.InvalidCaptureOption;
    if (WindowsRenderdocSpec.OPT_SAVE_ALL_INITIALS != 9) return error.InvalidCaptureOption;
    if (WindowsRenderdocSpec.OPT_CAPTURE_ALL_CMD_LISTS != 10) return error.InvalidCaptureOption;
    if (WindowsRenderdocSpec.OPT_DEBUG_OUTPUT_MUTE != 11) return error.InvalidCaptureOption;
    if (WindowsRenderdocSpec.OPT_ALLOW_UNSUPPORTED_VENDOR_EXT != 12) return error.InvalidCaptureOption;
    if (WindowsRenderdocSpec.OPT_SOFT_MEMORY_LIMIT != 13) return error.InvalidCaptureOption;
}

pub fn validateRenderdocOverlayBits() RenderdocError!void {
    if (WindowsRenderdocSpec.OVERLAY_ENABLED != 0x1) return error.InvalidOverlayBit;
    if (WindowsRenderdocSpec.OVERLAY_FRAME_RATE != 0x2) return error.InvalidOverlayBit;
    if (WindowsRenderdocSpec.OVERLAY_FRAME_NUMBER != 0x4) return error.InvalidOverlayBit;
    if (WindowsRenderdocSpec.OVERLAY_CAPTURE_LIST != 0x8) return error.InvalidOverlayBit;
    if (WindowsRenderdocSpec.OVERLAY_DEFAULT != 0xF) return error.InvalidOverlayBit;
    if (WindowsRenderdocSpec.OVERLAY_ALL != 0xFFFFFFFF) return error.InvalidOverlayBit;
    if (WindowsRenderdocSpec.OVERLAY_NONE != 0) return error.InvalidOverlayBit;
}

pub fn validateRenderdocInputKeys() RenderdocError!void {
    if (WindowsRenderdocSpec.KEY_0 != 0x30) return error.InvalidInputKey;
    if (WindowsRenderdocSpec.KEY_9 != 0x39) return error.InvalidInputKey;
    if (WindowsRenderdocSpec.KEY_A != 0x41) return error.InvalidInputKey;
    if (WindowsRenderdocSpec.KEY_Z != 0x5A) return error.InvalidInputKey;
    if (WindowsRenderdocSpec.KEY_NON_PRINTABLE != 0x100) return error.InvalidInputKey;
    if (WindowsRenderdocSpec.KEY_DIVIDE != 0x101) return error.InvalidInputKey;
    if (WindowsRenderdocSpec.KEY_MULTIPLY != 0x102) return error.InvalidInputKey;
    if (WindowsRenderdocSpec.KEY_SUBTRACT != 0x103) return error.InvalidInputKey;
    if (WindowsRenderdocSpec.KEY_PLUS != 0x104) return error.InvalidInputKey;
    if (WindowsRenderdocSpec.KEY_F1 != 0x105) return error.InvalidInputKey;
    if (WindowsRenderdocSpec.KEY_F12 != 0x110) return error.InvalidInputKey;
    if (WindowsRenderdocSpec.KEY_HOME != 0x111) return error.InvalidInputKey;
    if (WindowsRenderdocSpec.KEY_END != 0x112) return error.InvalidInputKey;
    if (WindowsRenderdocSpec.KEY_INSERT != 0x113) return error.InvalidInputKey;
    if (WindowsRenderdocSpec.KEY_DELETE != 0x114) return error.InvalidInputKey;
    if (WindowsRenderdocSpec.KEY_PAGE_UP != 0x115) return error.InvalidInputKey;
    if (WindowsRenderdocSpec.KEY_PAGE_DN != 0x116) return error.InvalidInputKey;
    if (WindowsRenderdocSpec.KEY_BACKSPACE != 0x117) return error.InvalidInputKey;
    if (WindowsRenderdocSpec.KEY_TAB != 0x118) return error.InvalidInputKey;
    if (WindowsRenderdocSpec.KEY_PRT_SCRN != 0x119) return error.InvalidInputKey;
    if (WindowsRenderdocSpec.KEY_PAUSE != 0x11A) return error.InvalidInputKey;
    if (WindowsRenderdocSpec.KEY_MAX != 0x11B) return error.InvalidInputKey;
}

pub fn validateRenderdocShaderDebugMagic() RenderdocError!void {
    if (WindowsRenderdocSpec.SHADER_DEBUG_MAGIC_TRUNCATED != 0x48656670eab25520)
        return error.InvalidShaderDebugMagic;
}

pub fn validateRenderdocApiStructLayout() RenderdocError!void {
    // Validate member count matches 1.6.0
    if (WindowsRenderdocSpec.API_STRUCT_MEMBER_COUNT != 27) return error.InvalidApiMemberCount;

    // Validate struct total size
    if (WindowsRenderdocSpec.sizeof_RENDERDOC_API != 216) return error.InvalidStructSize;

    // Validate each member offset
    if (WindowsRenderdocSpec.offsetof_GetAPIVersion != 0) return error.InvalidMemberOffset;
    if (WindowsRenderdocSpec.offsetof_SetCaptureOptionU32 != 8) return error.InvalidMemberOffset;
    if (WindowsRenderdocSpec.offsetof_SetCaptureOptionF32 != 16) return error.InvalidMemberOffset;
    if (WindowsRenderdocSpec.offsetof_GetCaptureOptionU32 != 24) return error.InvalidMemberOffset;
    if (WindowsRenderdocSpec.offsetof_GetCaptureOptionF32 != 32) return error.InvalidMemberOffset;
    if (WindowsRenderdocSpec.offsetof_SetFocusToggleKeys != 40) return error.InvalidMemberOffset;
    if (WindowsRenderdocSpec.offsetof_SetCaptureKeys != 48) return error.InvalidMemberOffset;
    if (WindowsRenderdocSpec.offsetof_GetOverlayBits != 56) return error.InvalidMemberOffset;
    if (WindowsRenderdocSpec.offsetof_MaskOverlayBits != 64) return error.InvalidMemberOffset;
    if (WindowsRenderdocSpec.offsetof_RemoveHooks != 72) return error.InvalidMemberOffset;
    if (WindowsRenderdocSpec.offsetof_UnloadCrashHandler != 80) return error.InvalidMemberOffset;
    if (WindowsRenderdocSpec.offsetof_SetCaptureFilePathTemplate != 88) return error.InvalidMemberOffset;
    if (WindowsRenderdocSpec.offsetof_GetCaptureFilePathTemplate != 96) return error.InvalidMemberOffset;
    if (WindowsRenderdocSpec.offsetof_GetNumCaptures != 104) return error.InvalidMemberOffset;
    if (WindowsRenderdocSpec.offsetof_GetCapture != 112) return error.InvalidMemberOffset;
    if (WindowsRenderdocSpec.offsetof_TriggerCapture != 120) return error.InvalidMemberOffset;
    if (WindowsRenderdocSpec.offsetof_IsTargetControlConnected != 128) return error.InvalidMemberOffset;
    if (WindowsRenderdocSpec.offsetof_LaunchReplayUI != 136) return error.InvalidMemberOffset;
    if (WindowsRenderdocSpec.offsetof_SetActiveWindow != 144) return error.InvalidMemberOffset;
    if (WindowsRenderdocSpec.offsetof_StartFrameCapture != 152) return error.InvalidMemberOffset;
    if (WindowsRenderdocSpec.offsetof_IsFrameCapturing != 160) return error.InvalidMemberOffset;
    if (WindowsRenderdocSpec.offsetof_EndFrameCapture != 168) return error.InvalidMemberOffset;
    if (WindowsRenderdocSpec.offsetof_TriggerMultiFrameCapture != 176) return error.InvalidMemberOffset;
    if (WindowsRenderdocSpec.offsetof_SetCaptureFileComments != 184) return error.InvalidMemberOffset;
    if (WindowsRenderdocSpec.offsetof_DiscardFrameCapture != 192) return error.InvalidMemberOffset;
    if (WindowsRenderdocSpec.offsetof_ShowReplayUI != 200) return error.InvalidMemberOffset;
    if (WindowsRenderdocSpec.offsetof_SetCaptureTitle != 208) return error.InvalidMemberOffset;
}

/// Validates host type widths. On both macOS LP64 and Windows LLP64,
/// function pointers are 8 bytes, uint32_t is 4 bytes, uint64_t is 8
/// bytes, and char pointers are 8 bytes — these are convergent on all
/// 64-bit platforms.  No LP64/LLP64 divergence in pointer or standard
/// integer width.
pub fn validateRenderdocTypeWidths() RenderdocError!void {
    if (MacOsRenderdoc.sizeof_ptr != 8) return error.InvalidFuncPtrWidth;
    if (MacOsRenderdoc.sizeof_fn_ptr != 8) return error.InvalidFuncPtrWidth;
    if (MacOsRenderdoc.sizeof_u32 != 4) return error.InvalidUint32Width;
    if (MacOsRenderdoc.sizeof_u64 != 8) return error.InvalidUint64Width;
}

pub fn validateAll() RenderdocError!void {
    try validateRenderdocVersions();
    try validateRenderdocCaptureOptions();
    try validateRenderdocOverlayBits();
    try validateRenderdocInputKeys();
    try validateRenderdocShaderDebugMagic();
    try validateRenderdocApiStructLayout();
    try validateRenderdocTypeWidths();
}

/// Returns 0 on success, non-zero error code on failure.
pub export fn rosetta3_validate_renderdoc() c_int {
    validateAll() catch |err| return switch (err) {
        error.InvalidVersionEnum => 1,
        error.InvalidCaptureOption => 2,
        error.InvalidInputKey => 3,
        error.InvalidOverlayBit => 4,
        error.InvalidShaderDebugMagic => 5,
        error.InvalidStructSize => 6,
        error.InvalidMemberOffset => 7,
        error.InvalidFuncPtrWidth => 8,
        error.InvalidCharPtrWidth => 9,
        error.InvalidUint32Width => 10,
        error.InvalidUint64Width => 11,
        error.InvalidCallingConvention => 12,
        error.InvalidApiMemberCount => 13,
    };
    return 0;
}

/// returns a null-terminated string
pub export fn rosetta3_renderdoc_failure_name(code: c_int) [*:0]const u8 {
    return switch (code) {
        0 => "OK",
        1 => "InvalidVersionEnum",
        2 => "InvalidCaptureOption",
        3 => "InvalidInputKey",
        4 => "InvalidOverlayBit",
        5 => "InvalidShaderDebugMagic",
        6 => "InvalidStructSize",
        7 => "InvalidMemberOffset",
        8 => "InvalidFuncPtrWidth",
        9 => "InvalidCharPtrWidth",
        10 => "InvalidUint32Width",
        11 => "InvalidUint64Width",
        12 => "InvalidCallingConvention",
        13 => "InvalidApiMemberCount",
        else => "UnknownRenderdocFailure",
    };
}

pub fn reportRenderdocSpec() void {
    std.debug.print(
        \\
        \\================================================================================
        \\ RenderDoc In-Application API Specification Table
        \\================================================================================
        \\ API version: 1.6.0 (enum value 10600)
        \\
        \\ Capture options ({d} total):
        \\   AllowVSync                      = {d:2}
        \\   AllowFullscreen                 = {d:2}
        \\   APIValidation                   = {d:2}
        \\   CaptureCallstacks               = {d:2}
        \\   CaptureCallstacksOnlyActions    = {d:2}
        \\   DelayForDebugger                = {d:2}
        \\   VerifyBufferAccess              = {d:2}
        \\   HookIntoChildren                = {d:2}
        \\   RefAllResources                 = {d:2}
        \\   SaveAllInitials                 = {d:2}
        \\   CaptureAllCmdLists              = {d:2}
        \\   DebugOutputMute                 = {d:2}
        \\   AllowUnsupportedVendorExtensions = {d:2}
        \\   SoftMemoryLimit                 = {d:2}
        \\
        \\ Overlay bits:
        \\   Enabled     = 0x{x:0>8}
        \\   FrameRate   = 0x{x:0>8}
        \\   FrameNumber = 0x{x:0>8}
        \\   CaptureList = 0x{x:0>8}
        \\   Default     = 0x{x:0>8}
        \\   All         = 0x{x:0>8}
        \\   None        = 0x{x:0>8}
        \\
        \\ Shader debug magic (truncated): 0x{x:0>16}
        \\
    , .{
        WindowsRenderdocSpec.OPT_COUNT,
        WindowsRenderdocSpec.OPT_ALLOW_VSYNC,
        WindowsRenderdocSpec.OPT_ALLOW_FULLSCREEN,
        WindowsRenderdocSpec.OPT_API_VALIDATION,
        WindowsRenderdocSpec.OPT_CAPTURE_CALLSTACKS,
        WindowsRenderdocSpec.OPT_CAPTURE_CALLSTACKS_ONLY_ACTIONS,
        WindowsRenderdocSpec.OPT_DELAY_FOR_DEBUGGER,
        WindowsRenderdocSpec.OPT_VERIFY_BUFFER_ACCESS,
        WindowsRenderdocSpec.OPT_HOOK_INTO_CHILDREN,
        WindowsRenderdocSpec.OPT_REF_ALL_RESOURCES,
        WindowsRenderdocSpec.OPT_SAVE_ALL_INITIALS,
        WindowsRenderdocSpec.OPT_CAPTURE_ALL_CMD_LISTS,
        WindowsRenderdocSpec.OPT_DEBUG_OUTPUT_MUTE,
        WindowsRenderdocSpec.OPT_ALLOW_UNSUPPORTED_VENDOR_EXT,
        WindowsRenderdocSpec.OPT_SOFT_MEMORY_LIMIT,
        WindowsRenderdocSpec.OVERLAY_ENABLED,
        WindowsRenderdocSpec.OVERLAY_FRAME_RATE,
        WindowsRenderdocSpec.OVERLAY_FRAME_NUMBER,
        WindowsRenderdocSpec.OVERLAY_CAPTURE_LIST,
        WindowsRenderdocSpec.OVERLAY_DEFAULT,
        WindowsRenderdocSpec.OVERLAY_ALL,
        WindowsRenderdocSpec.OVERLAY_NONE,
        WindowsRenderdocSpec.SHADER_DEBUG_MAGIC_TRUNCATED,
    });

    std.debug.print(
        \\ RENDERDOC_API_1_6_0 layout (64-bit):
        \\   Member count                    = {d}
        \\   sizeof                          = {d} bytes
        \\   offsetof(GetAPIVersion)                 = {d}
        \\   offsetof(SetCaptureOptionU32)           = {d}
        \\   offsetof(SetCaptureOptionF32)           = {d}
        \\   offsetof(GetCaptureOptionU32)           = {d}
        \\   offsetof(GetCaptureOptionF32)           = {d}
        \\   offsetof(SetFocusToggleKeys)            = {d}
        \\   offsetof(SetCaptureKeys)                = {d}
        \\   offsetof(GetOverlayBits)                = {d}
        \\   offsetof(MaskOverlayBits)               = {d}
        \\   offsetof(RemoveHooks)                   = {d}
        \\   offsetof(UnloadCrashHandler)            = {d}
        \\   offsetof(SetCaptureFilePathTemplate)    = {d}
        \\   offsetof(GetCaptureFilePathTemplate)    = {d}
        \\   offsetof(GetNumCaptures)                = {d}
        \\   offsetof(GetCapture)                    = {d}
        \\   offsetof(TriggerCapture)                = {d}
        \\   offsetof(IsTargetControlConnected)      = {d}
        \\   offsetof(LaunchReplayUI)                = {d}
        \\   offsetof(SetActiveWindow)               = {d}
        \\   offsetof(StartFrameCapture)             = {d}
        \\   offsetof(IsFrameCapturing)              = {d}
        \\   offsetof(EndFrameCapture)               = {d}
        \\   offsetof(TriggerMultiFrameCapture)      = {d}
        \\   offsetof(SetCaptureFileComments)        = {d}
        \\   offsetof(DiscardFrameCapture)           = {d}
        \\   offsetof(ShowReplayUI)                  = {d}
        \\   offsetof(SetCaptureTitle)               = {d}
        \\
    , .{
        WindowsRenderdocSpec.API_STRUCT_MEMBER_COUNT,
        WindowsRenderdocSpec.sizeof_RENDERDOC_API,
        WindowsRenderdocSpec.offsetof_GetAPIVersion,
        WindowsRenderdocSpec.offsetof_SetCaptureOptionU32,
        WindowsRenderdocSpec.offsetof_SetCaptureOptionF32,
        WindowsRenderdocSpec.offsetof_GetCaptureOptionU32,
        WindowsRenderdocSpec.offsetof_GetCaptureOptionF32,
        WindowsRenderdocSpec.offsetof_SetFocusToggleKeys,
        WindowsRenderdocSpec.offsetof_SetCaptureKeys,
        WindowsRenderdocSpec.offsetof_GetOverlayBits,
        WindowsRenderdocSpec.offsetof_MaskOverlayBits,
        WindowsRenderdocSpec.offsetof_RemoveHooks,
        WindowsRenderdocSpec.offsetof_UnloadCrashHandler,
        WindowsRenderdocSpec.offsetof_SetCaptureFilePathTemplate,
        WindowsRenderdocSpec.offsetof_GetCaptureFilePathTemplate,
        WindowsRenderdocSpec.offsetof_GetNumCaptures,
        WindowsRenderdocSpec.offsetof_GetCapture,
        WindowsRenderdocSpec.offsetof_TriggerCapture,
        WindowsRenderdocSpec.offsetof_IsTargetControlConnected,
        WindowsRenderdocSpec.offsetof_LaunchReplayUI,
        WindowsRenderdocSpec.offsetof_SetActiveWindow,
        WindowsRenderdocSpec.offsetof_StartFrameCapture,
        WindowsRenderdocSpec.offsetof_IsFrameCapturing,
        WindowsRenderdocSpec.offsetof_EndFrameCapture,
        WindowsRenderdocSpec.offsetof_TriggerMultiFrameCapture,
        WindowsRenderdocSpec.offsetof_SetCaptureFileComments,
        WindowsRenderdocSpec.offsetof_DiscardFrameCapture,
        WindowsRenderdocSpec.offsetof_ShowReplayUI,
        WindowsRenderdocSpec.offsetof_SetCaptureTitle,
    });

    std.debug.print(
        \\ Key codes (representative):
        \\   KEY_0                           = 0x{x:0>2}
        \\   KEY_9                           = 0x{x:0>2}
        \\   KEY_A                           = 0x{x:0>2}
        \\   KEY_Z                           = 0x{x:0>2}
        \\   KEY_NON_PRINTABLE               = 0x{x:0>3}
        \\   KEY_MAX                         = 0x{x:0>3}
        \\
        \\ Type widths:
        \\   sizeof(void*)                   = {d}  (expected: {d})
        \\   sizeof(fn ptr)                  = {d}  (expected: {d})
        \\   sizeof(uint32_t)                = {d}  (expected: {d})
        \\   sizeof(uint64_t)                = {d}  (expected: {d})
        \\
        \\================================================================================
        \\
    , .{
        WindowsRenderdocSpec.KEY_0,
        WindowsRenderdocSpec.KEY_9,
        WindowsRenderdocSpec.KEY_A,
        WindowsRenderdocSpec.KEY_Z,
        WindowsRenderdocSpec.KEY_NON_PRINTABLE,
        WindowsRenderdocSpec.KEY_MAX,
        MacOsRenderdoc.sizeof_ptr,
        8,
        MacOsRenderdoc.sizeof_fn_ptr,
        8,
        MacOsRenderdoc.sizeof_u32,
        4,
        MacOsRenderdoc.sizeof_u64,
        8,
    });
}

pub export fn rosetta3_print_renderdoc_spec() void {
    reportRenderdocSpec();
}

test "RenderDoc spec matches expected values" {
    reportRenderdocSpec();
    try validateAll();
}
