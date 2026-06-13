const std = @import("std");
const model = @import("abi/model.zig");
const validate = @import("abi/validate.zig");
const yasm = @import("yasm_core.zig");
const assembler = @import("assembler.zig");
const runtime_abi = @import("runtime_abi_handshake");

pub const YasmAbiHandshake = struct {
    allocator: std.mem.Allocator,
    validator: validate.AssemblerValidator,
    sequence: u64 = 0,
    event_log: std.ArrayListUnmanaged(model.AssemblerEventRecord) = .{ .items = &.{}, .capacity = 0 },

    pub fn init(allocator: std.mem.Allocator) YasmAbiHandshake {
        runtime_abi.common.writeLine("[yasm][abi-handshake] init\n", .{});
        return .{
            .allocator = allocator,
            .validator = validate.AssemblerValidator.init(allocator),
        };
    }

    pub fn deinit(self: *YasmAbiHandshake) void {
        for (self.event_log.items) |ev| self.allocator.free(ev.detail);
        self.event_log.deinit(self.allocator);
        runtime_abi.common.writeLine("[yasm][abi-handshake] deinit violations={d}\n", .{self.validator.error_count});
    }

    pub fn onEvent(self: *YasmAbiHandshake, event: model.AssemblerEvent, domain: model.ValidationDomain, address: u64, detail: []const u8) !void {
        self.sequence += 1;
        try self.event_log.append(self.allocator, .{
            .event = event,
            .domain = domain,
            .pass = 1,
            .address = address,
            .detail = try self.allocator.dupe(u8, detail),
        });
    }

    pub fn validateCommand(self: *YasmAbiHandshake, options: yasm.CommandOptions) void {
        self.validator.validateCommand(options);
    }

    pub fn validateSourceProfile(self: *YasmAbiHandshake, profile: assembler.SourceProfile) void {
        self.validator.validateSourceProfile(profile);
    }

    pub fn validateArtifact(self: *YasmAbiHandshake, format: yasm.OutputFormat, bytes: []const u8) void {
        self.validator.validateArtifact(format, bytes, "yasm artifact");
        if (self.validator.error_count > 0) {
            runtime_abi.common.violation("yasm-abivalidate", "artifact_validation_failed", "errors={d}", .{self.validator.error_count});
        }
    }

    pub fn flushEventLog(self: *YasmAbiHandshake) void {
        for (self.event_log.items) |ev| {
            runtime_abi.common.writeLine(
                "[yasm][abi][{s}] seq={d} pass={d} addr=0x{x} size={d} {s}\n",
                .{ @tagName(ev.domain), self.sequence, ev.pass, ev.address, ev.size, ev.detail },
            );
        }
    }
};

test "abi handshake validates yasm command and artifact" {
    const argv = [_][]const u8{ "-g", "dwarf2", "-f", "elf64", "ast01.asm", "-l", "ast01.lst" };
    var options = try yasm.parseCommandLine(std.testing.allocator, &argv);
    defer options.deinit();
    const bytes = try @import("output.zig").emitPlaceholderObject(std.testing.allocator, .elf64);
    defer std.testing.allocator.free(bytes);

    var h = YasmAbiHandshake.init(std.testing.allocator);
    defer h.deinit();
    h.validateCommand(options);
    h.validateArtifact(.elf64, bytes);
    try h.onEvent(.command_parsed, .command_line, 0, "yasm -g dwarf2 -f elf64");
    try std.testing.expectEqual(@as(u32, 0), h.validator.error_count);
    try std.testing.expectEqual(@as(usize, 1), h.event_log.items.len);
}
