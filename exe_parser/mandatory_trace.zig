const logger = @import("../disasm_logger/x86_trace_logger.zig");

pub fn enable(log_path_z: [*:0]const u8) void {
    logger.initMandatory(log_path_z);
}

pub fn disable() void {
    logger.deinit();
}

pub fn logText(text: []const u8) void {
    logger.logText(text);
}

pub fn isEnabled() bool {
    return logger.isEnabled();
}
