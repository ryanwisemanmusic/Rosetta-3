const std = @import("std");
const yasm = @import("../yasm_core.zig");
const assembler = @import("../assembler.zig");
const output = @import("../output.zig");
const runtime_abi = @import("runtime_abi_handshake");

pub const AssemblerValidator = struct {
    allocator: std.mem.Allocator,
    error_count: u32 = 0,
    warning_count: u32 = 0,

    pub fn init(allocator: std.mem.Allocator) AssemblerValidator {
        return .{ .allocator = allocator };
    }

    pub fn validateCommand(self: *AssemblerValidator, options: yasm.CommandOptions) void {
        if (options.parser != .nasm) {
            self.warn("yasm-command_line", "non_nasm_parser", "parser={s}", .{@tagName(options.parser)});
        }
        if (options.format == .elf64 and options.bits != .bits_64) {
            self.violate("yasm-command_line", "elf64_requires_64_bit", "bits={d}", .{@intFromEnum(options.bits)});
        }
        if (options.source_path == null) {
            self.violate("yasm-command_line", "missing_input", "source is required", .{});
        }
    }

    pub fn validateSourceProfile(self: *AssemblerValidator, profile: assembler.SourceProfile) void {
        if (profile.kind == .unknown) {
            self.violate("yasm-source_profile", "unknown_profile", "score={d}", .{profile.score});
        }
    }

    pub fn validateInstruction(self: *AssemblerValidator, byte_len: u8, address: u64) void {
        if (byte_len == 0 or byte_len > 15) {
            self.violate("yasm-instruction_encoding", "bad_instruction_length", "address=0x{x} length={d}", .{ address, byte_len });
        }
    }

    pub fn validateAlignment(self: *AssemblerValidator, value: u64, alignment: u64, address: u64, name: []const u8) void {
        if (alignment > 0 and value % alignment != 0) {
            self.violate("yasm-alignment", "misaligned", "name={s} address=0x{x} value=0x{x} align={d}", .{ name, address, value, alignment });
        }
    }

    pub fn validateOutputSize(self: *AssemblerValidator, size: usize, max_size: usize, context: []const u8) void {
        if (size > max_size) {
            self.violate("yasm-output_format", "output_too_large", "{s}: {d} > {d}", .{ context, size, max_size });
        }
    }

    pub fn validateArtifact(self: *AssemblerValidator, format: yasm.OutputFormat, bytes: []const u8, context: []const u8) void {
        self.validateOutputSize(bytes.len, 64 * 1024 * 1024, context);
        if (!output.validateForFormat(format, bytes)) {
            const info = output.inspectArtifact(bytes);
            self.violate("yasm-artifact_format", "format_mismatch", "expected={s} actual={s} machine=0x{x}", .{ @tagName(format), @tagName(info.kind), info.machine });
        }
    }

    pub fn validateBits(self: *AssemblerValidator, bits: yasm.BitsMode) void {
        _ = self;
        switch (bits) {
            .bits_16, .bits_32, .bits_64 => {},
        }
    }

    fn warn(self: *AssemblerValidator, comptime domain: []const u8, comptime check: []const u8, comptime fmt: []const u8, args: anytype) void {
        self.warning_count += 1;
        runtime_abi.common.violation(domain, check, fmt, args);
    }

    fn violate(self: *AssemblerValidator, comptime domain: []const u8, comptime check: []const u8, comptime fmt: []const u8, args: anytype) void {
        self.error_count += 1;
        runtime_abi.common.violation(domain, check, fmt, args);
    }
};

test "validation helpers accept elf64 placeholder" {
    var v = AssemblerValidator.init(std.testing.allocator);
    const bytes = try output.emitPlaceholderObject(std.testing.allocator, .elf64);
    defer std.testing.allocator.free(bytes);
    v.validateArtifact(.elf64, bytes, "test");
    v.validateBits(.bits_64);
    try std.testing.expectEqual(@as(u32, 0), v.error_count);
}
