const std = @import("std");
const core = @import("family_core.zig");

pub const RepMode = enum {
    none,
    rep,
    repe,
    repne,
};

pub const StringOp = enum {
    movs,
    cmps,
    scas,
    stos,
    lods,
};

pub const StringInstructionDesc = struct {
    op: StringOp,
    width: core.OperandWidth,
    rep_mode: RepMode = .none,
    reads_source: bool,
    reads_dest: bool,
    writes_dest: bool,
};

pub const common_string_ops = [_]StringInstructionDesc{
    .{ .op = .movs, .width = .byte, .rep_mode = .rep, .reads_source = true, .reads_dest = false, .writes_dest = true },
    .{ .op = .cmps, .width = .byte, .rep_mode = .repe, .reads_source = true, .reads_dest = true, .writes_dest = false },
    .{ .op = .scas, .width = .byte, .rep_mode = .repne, .reads_source = false, .reads_dest = true, .writes_dest = false },
    .{ .op = .stos, .width = .byte, .rep_mode = .rep, .reads_source = false, .reads_dest = false, .writes_dest = true },
    .{ .op = .lods, .width = .byte, .rep_mode = .rep, .reads_source = true, .reads_dest = false, .writes_dest = false },
};

test "string scaffold covers movs and scas" {
    try std.testing.expectEqual(StringOp.movs, common_string_ops[0].op);
    try std.testing.expectEqual(RepMode.repne, common_string_ops[2].rep_mode);
}
