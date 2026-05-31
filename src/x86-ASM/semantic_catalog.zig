const std = @import("std");
const core = @import("family_core.zig");

pub const InstructionSemantic = struct {
    mnemonic: []const u8,
    family: core.InstructionFamily,
    updates_flags: core.FlagMask = .{},
    touches_memory: bool = false,
    todo: []const u8,
};

pub const core_semantics = [_]InstructionSemantic{
    .{ .mnemonic = "MOV", .family = .data_movement, .touches_memory = true, .todo = "Add full width-specific data movement lowering." },
    .{ .mnemonic = "LEA", .family = .data_movement, .todo = "Resolve effective address only, without dereference." },
    .{ .mnemonic = "ADD", .family = .arithmetic, .updates_flags = .{ .cf = true, .pf = true, .af = true, .zf = true, .sf = true, .of = true }, .todo = "Unify byte/word/dword/qword flag behavior." },
    .{ .mnemonic = "SUB", .family = .arithmetic, .updates_flags = .{ .cf = true, .pf = true, .af = true, .zf = true, .sf = true, .of = true }, .todo = "Wire subtraction and compare through shared arithmetic core." },
    .{ .mnemonic = "CMP", .family = .compare_test, .updates_flags = .{ .cf = true, .pf = true, .af = true, .zf = true, .sf = true, .of = true }, .todo = "Discard result while preserving SUB flag semantics." },
    .{ .mnemonic = "TEST", .family = .compare_test, .updates_flags = .{ .pf = true, .zf = true, .sf = true }, .todo = "Clear CF/OF while preserving width masking." },
    .{ .mnemonic = "CALL", .family = .control_flow, .touches_memory = true, .todo = "Separate near, far, thunk, and imported call lowering." },
    .{ .mnemonic = "RET", .family = .control_flow, .touches_memory = true, .todo = "Model immediate stack cleanup for stdcall-style returns." },
    .{ .mnemonic = "MOVSB", .family = .string, .touches_memory = true, .todo = "Share REP/DF behavior across MOVS/CMPS/SCAS/STOS/LODS." },
    .{ .mnemonic = "MUL", .family = .multiply_divide, .updates_flags = .{ .cf = true, .of = true }, .todo = "Expose implicit accumulator register pairs by width." },
    .{ .mnemonic = "DIV", .family = .multiply_divide, .todo = "Add divide fault reporting and quotient range checks." },
};

pub fn findSemantic(mnemonic: []const u8) ?InstructionSemantic {
    for (core_semantics) |entry| {
        if (std.ascii.eqlIgnoreCase(entry.mnemonic, mnemonic)) return entry;
    }
    return null;
}

test "semantic catalog includes mov and call" {
    try std.testing.expect(findSemantic("mov") != null);
    try std.testing.expect(findSemantic("CALL") != null);
    try std.testing.expect(findSemantic("iret") == null);
}
