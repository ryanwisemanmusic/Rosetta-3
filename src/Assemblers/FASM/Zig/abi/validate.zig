const std = @import("std");
const runtime_abi = @import("runtime_abi_handshake");

pub const AssemblerValidator = struct {
    allocator: std.mem.Allocator,
    error_count: u32 = 0,
    warning_count: u32 = 0,

    pub fn init(allocator: std.mem.Allocator) AssemblerValidator {
        return AssemblerValidator{ .allocator = allocator };
    }

    pub fn validateInstruction(_: *AssemblerValidator, bytes: []const u8, address: u64) void {
        if (bytes.len == 0 or bytes.len > 15) {
            runtime_abi.common.violation("fasm-instruction_encoding", "bad_instruction_length", "address=0x{x} length={d}", .{ address, bytes.len });
        }
    }

    pub fn validateAlignment(_: *AssemblerValidator, value: u64, alignment: u64, address: u64, _name: []const u8) void {
        if (alignment > 0 and value % alignment != 0) {
            runtime_abi.common.violation("fasm-alignment", "misaligned", "name={s} address=0x{x} value=0x{x} align={d}", .{ _name, address, value, alignment });
        }
    }

    pub fn validatePassConvergence(_: *AssemblerValidator, changed: bool, pass: u32, max_passes: u32) void {
        if (changed and pass >= max_passes) {
            runtime_abi.common.violation("fasm-pass_convergence", "exceeded_max_passes", "pass={d} max={d}", .{ pass, max_passes });
        }
    }

    pub fn validateOutputSize(_: *AssemblerValidator, size: usize, max_size: usize, context: []const u8) void {
        if (size > max_size) {
            runtime_abi.common.violation("fasm-output_format", "output_too_large", "{s}: {d} > {d}", .{ context, size, max_size });
        }
    }

    pub fn validateSegment(_: *AssemblerValidator, start: u64, end: u64, align_val: u16) void {
        if (align_val > 0 and start % align_val != 0) {
            runtime_abi.common.violation("fasm-segment_layout", "segment_misaligned", "start=0x{x} align={d}", .{ start, align_val });
        }
        if (end < start) {
            runtime_abi.common.violation("fasm-segment_layout", "segment_underflow", "end=0x{x} < start=0x{x}", .{ end, start });
        }
    }

    pub fn validateSymbol(_: *AssemblerValidator, name: []const u8, offset: u64, segment: u32) void {
        _ = segment;
        if (name.len == 0) {
            runtime_abi.common.violation("fasm-symbol_resolution", "empty_symbol_name", "offset=0x{x}", .{offset});
        }
    }
};

test "validation helpers" {
    const alloc = std.testing.allocator;
    var v = AssemblerValidator.init(alloc);
    v.validateInstruction(&[_]u8{0x90}, 0);
    v.validateAlignment(0x100, 16, 0, "segment");
    v.validatePassConvergence(false, 2, 4);
    v.validateOutputSize(100, 1024, "test");
    v.validateSegment(0x100, 0x200, 16);
    v.validateSymbol("foo", 0x100, 0);
    try std.testing.expectEqual(@as(u32, 0), v.error_count);
}
