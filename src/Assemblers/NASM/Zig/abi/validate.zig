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
            runtime_abi.common.violation("nasm-instruction_encoding", "bad_instruction_length", "address=0x{x} length={d}", .{ address, bytes.len });
        }
    }

    pub fn validateAlignment(_: *AssemblerValidator, value: u64, alignment: u64, address: u64, _name: []const u8) void {
        if (alignment > 0 and value % alignment != 0) {
            runtime_abi.common.violation("nasm-alignment", "misaligned", "name={s} address=0x{x} value=0x{x} align={d}", .{ _name, address, value, alignment });
        }
    }

    pub fn validatePassConvergence(_: *AssemblerValidator, changed: bool, pass: u32, max_passes: u32) void {
        if (changed and pass >= max_passes) {
            runtime_abi.common.violation("nasm-pass_convergence", "exceeded_max_passes", "pass={d} max={d}", .{ pass, max_passes });
        }
    }

    pub fn validateOutputSize(_: *AssemblerValidator, size: usize, max_size: usize, context: []const u8) void {
        if (size > max_size) {
            runtime_abi.common.violation("nasm-output_format", "output_too_large", "{s}: {d} > {d}", .{ context, size, max_size });
        }
    }

    pub fn validateSection(_: *AssemblerValidator, start: u64, end: u64, align_val: u16) void {
        if (align_val > 0 and start % align_val != 0) {
            runtime_abi.common.violation("nasm-section_layout", "section_misaligned", "start=0x{x} align={d}", .{ start, align_val });
        }
        if (end < start) {
            runtime_abi.common.violation("nasm-section_layout", "section_underflow", "end=0x{x} < start=0x{x}", .{ end, start });
        }
    }

    pub fn validateLabel(_: *AssemblerValidator, name: []const u8, offset: u64) void {
        if (name.len == 0) {
            runtime_abi.common.violation("nasm-symbol_resolution", "empty_label_name", "offset=0x{x}", .{offset});
        }
    }

    pub fn validateBits(_: *AssemblerValidator, bits: u8) void {
        if (bits != 16 and bits != 32 and bits != 64) {
            runtime_abi.common.violation("nasm-bits_mode", "invalid_bits", "bits={d}", .{bits});
        }
    }
};

test "validation helpers" {
    const alloc = std.testing.allocator;
    var v = AssemblerValidator.init(alloc);
    v.validateInstruction(&[_]u8{0x90}, 0);
    v.validateAlignment(0x100, 16, 0, "section");
    v.validatePassConvergence(false, 2, 4);
    v.validateOutputSize(100, 1024, "test");
    v.validateSection(0x100, 0x200, 16);
    v.validateLabel("foo", 0x100);
    v.validateBits(32);
    try std.testing.expectEqual(@as(u32, 0), v.error_count);
}
