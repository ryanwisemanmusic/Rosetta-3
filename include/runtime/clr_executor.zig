const std = @import("std");
const clr_format = @import("clr_pe_format.zig");
const clr_assembly = @import("clr_assembly.zig");
const clr_metadata = @import("clr_metadata.zig");
const winforms_bridge = @import("../winforms/winforms_bridge.zig");

const Allocator = std.mem.Allocator;

pub const ExecError = error{
    InvalidInstruction,
    StackOverflow,
    StackUnderflow,
    InvalidToken,
    NotSupported,
    OutOfMemory,
};

pub const StackValue = union(enum) {
    int32: i32,
    int64: i64,
    uint32: u32,
    uint64: u64,
    float32: f32,
    float64: f64,
    object: ?*anyopaque,
    string: []const u8,
    null: void,
};

const EvaluationStack = struct {
    values: std.ArrayListUnmanaged(StackValue),
    max_depth: u32 = 4096,
    allocator: Allocator,

    fn init(allocator: Allocator) EvaluationStack {
        return EvaluationStack{
            .values = .{ .items = &.{}, .capacity = 0 },
            .allocator = allocator,
        };
    }
    fn deinit(self: *EvaluationStack) void {
        self.values.deinit(self.allocator);
    }

    fn push(self: *EvaluationStack, value: StackValue) ExecError!void {
        if (self.values.items.len >= self.max_depth) return ExecError.StackOverflow;
        try self.values.append(self.allocator, value);
    }

    fn pop(self: *EvaluationStack) ExecError!StackValue {
        return self.values.pop() orelse return ExecError.StackUnderflow;
    }

    fn peek(self: *const EvaluationStack) ExecError!StackValue {
        if (self.values.items.len == 0) return ExecError.StackUnderflow;
        return self.values.items[self.values.items.len - 1];
    }
};

pub const LocalVariables = struct {
    values: std.ArrayListUnmanaged(StackValue),
    allocator: Allocator,
    fn init(allocator: Allocator) LocalVariables {
        return .{
            .values = .{ .items = &.{}, .capacity = 0 },
            .allocator = allocator,
        };
    }
    fn deinit(self: *LocalVariables) void {
        self.values.deinit(self.allocator);
    }
    fn set(self: *LocalVariables, index: u32, value: StackValue) ExecError!void {
        if (index >= self.values.items.len) return ExecError.InvalidToken;
        self.values.items[index] = value;
    }
    fn get(self: *const LocalVariables, index: u32) ExecError!StackValue {
        if (index >= self.values.items.len) return ExecError.InvalidToken;
        return self.values.items[index];
    }
};

pub const MethodContext = struct {
    metadata: *const clr_assembly.Assembly,
    pe_data: []const u8,
    method_token: u32,
    code: []const u8,
    stack: EvaluationStack,
    locals: LocalVariables,
    args: []const StackValue,
    allocator: Allocator,

    fn init(allocator: Allocator, metadata: *const clr_assembly.Assembly, pe_data: []const u8, method_token: u32, code: []const u8, args: []const StackValue) MethodContext {
        return MethodContext{
            .metadata = metadata,
            .pe_data = pe_data,
            .method_token = method_token,
            .code = code,
            .stack = EvaluationStack.init(allocator),
            .locals = LocalVariables.init(allocator),
            .args = args,
            .allocator = allocator,
        };
    }

    fn deinit(self: *MethodContext) void {
        self.stack.deinit();
        self.locals.deinit();
    }
};

fn readIntSlice(comptime T: type, data: []const u8, offset: u32) T {
    const bytes = @sizeOf(T);
    var result: T = 0;
    inline for (0..bytes) |i| {
        result |= (@as(T, data[offset + i]) << (i * 8));
    }
    return result;
}

pub const ILExecutor = struct {
    assembly: *const clr_assembly.Assembly,
    pe_data: []const u8,
    allocator: Allocator,
    bridge: ?*winforms_bridge.WinFormsBridge,

    pub fn init(allocator: Allocator, assembly: *const clr_assembly.Assembly, pe_data: []const u8) ILExecutor {
        return ILExecutor{
            .assembly = assembly,
            .pe_data = pe_data,
            .allocator = allocator,
            .bridge = null,
        };
    }

    pub fn executeEntryPoint(self: *ILExecutor, entry_token: u32) ExecError!StackValue {
        const table_id = clr_format.standardTokenTable(entry_token);
        const row_index = clr_format.standardTokenRow(entry_token);
        if (table_id != clr_format.TABLE_METHODDEF or row_index < 1)
            return ExecError.InvalidToken;
        const md_idx = row_index - 1;
        if (md_idx >= self.assembly.metadata.method_defs.items.len)
            return ExecError.InvalidToken;

        const method = self.assembly.metadata.method_defs.items[md_idx];
        const body = self.resolveMethodBody(method.rva) catch |err| {
            if (comptime std.debug.runtime_safety) {
                std.log.debug("executeEntryPoint: resolveMethodBody(RVA 0x{x}) failed: {s}", .{ method.rva, @errorName(err) });
            }
            return ExecError.InvalidInstruction;
        };

        var ctx = MethodContext.init(self.allocator, self.assembly, self.pe_data, entry_token, body, &[_]StackValue{});
        defer ctx.deinit();
        return self.executeCode(&ctx);
    }

    fn resolveMethodBody(self: *ILExecutor, rva: u32) ExecError![]const u8 {
        const data = self.pe_data;
        const pe_offset: u32 = brk: {
            if (data.len < 64) return ExecError.InvalidToken;
            var po: u32 = 0;
            @memcpy(@as([*]u8, @ptrCast(&po))[0..4], data[60..64]);
            break :brk po;
        };
        const pe_coff_offset = pe_offset + 4;
        const num_sections = readIntSlice(u16, data, pe_coff_offset + 2);
        const size_of_opt = readIntSlice(u16, data, pe_coff_offset + 16);
        const section_headers_offset = pe_coff_offset + 20 + size_of_opt;

        std.debug.print("CLR resolveMethodBody: rva=0x{x}, num_sections={d}, section_headers_offset=0x{x}\n", .{ rva, num_sections, section_headers_offset });

        var file_offset: u32 = 0;
        var i: u16 = 0;
        while (i < num_sections) : (i += 1) {
            const soff = section_headers_offset + i * 40;
            if (soff + 24 > data.len) break;
            const va = readIntSlice(u32, data, soff + 12);
            const virt_size = readIntSlice(u32, data, soff + 8);
            const raw_size = readIntSlice(u32, data, soff + 16);
            const ptr_raw = readIntSlice(u32, data, soff + 20);
            std.debug.print("CLR resolveMethodBody: section {d}: va=0x{x}, virt_size={d}, raw_size={d}, ptr_raw=0x{x}\n", .{ i, va, virt_size, raw_size, ptr_raw });
            const section_end = if (virt_size > raw_size) virt_size else raw_size;
            if (rva >= va and rva < va + section_end) {
                file_offset = rva - va + ptr_raw;
                std.debug.print("CLR resolveMethodBody: found at file_offset=0x{x}\n", .{file_offset});
                break;
            }
        }
        // Some .NET compilers store method bodies as file offsets, not image-relative RVAs.
        // Try interpreting rva directly as a file offset if section scan failed.
        if (file_offset == 0 or file_offset >= data.len) {
            if (rva < data.len and rva > 0) {
                std.debug.print("CLR resolveMethodBody: trying rva as raw file offset 0x{x}\n", .{rva});
                file_offset = rva;
            }
        }
        if (file_offset == 0 or file_offset >= data.len) return ExecError.InvalidInstruction;

        const header_byte = data[file_offset];
        if (clr_format.isTinyMethod(header_byte)) {
            const code_size = clr_format.tinyMethodCodeSize(header_byte);
            if (file_offset + 1 + code_size > data.len) return ExecError.InvalidInstruction;
            return data[file_offset + 1 .. file_offset + 1 + code_size];
        } else if (clr_format.isFatMethod(header_byte)) {
            if (file_offset + 12 > data.len) return ExecError.InvalidInstruction;
            const flags = readIntSlice(u16, data, file_offset);
            const code_size = readIntSlice(u32, data, file_offset + 4);
            const header_size: u32 = 12;
            if (file_offset + header_size + code_size > data.len) return ExecError.InvalidInstruction;
            _ = flags;
            return data[file_offset + header_size .. file_offset + header_size + code_size];
        }
        return ExecError.InvalidInstruction;
    }

    pub fn executeCode(self: *ILExecutor, ctx: *MethodContext) ExecError!StackValue {
        var ip: u32 = 0;
        var steps: u32 = 0;
        const max_steps: u32 = 50000;
        while (ip < ctx.code.len) : (steps += 1) {
            if (steps >= max_steps) {
                std.debug.print("CLR IL: hit instruction limit of {d}, stopping to prevent hang\n", .{max_steps});
                return ExecError.InvalidInstruction;
            }
            var opcode = ctx.code[ip];
            ip += 1;

            const is_two_byte = opcode == 0xFE;
            if (is_two_byte) {
                if (ip >= ctx.code.len) return ExecError.InvalidInstruction;
                opcode = ctx.code[ip];
                ip += 1;
            }

            switch (opcode) {
                // Nop
                0x00 => {},

                // Load argument (short forms)
                0x02, 0x03, 0x04, 0x05 => {
                    const idx = opcode - 0x02;
                    if (idx < ctx.args.len) {
                        try ctx.stack.push(ctx.args[idx]);
                    } else {
                        try ctx.stack.push(StackValue.null);
                    }
                },

                // Load local (short forms)
                0x06, 0x07, 0x08, 0x09 => {
                    const idx = opcode - 0x06;
                    if (idx < ctx.locals.values.items.len) {
                        try ctx.stack.push(try ctx.locals.get(idx));
                    } else {
                        try ctx.stack.push(StackValue.null);
                    }
                },

                // Store local (short forms)
                0x0A, 0x0B, 0x0C, 0x0D => {
                    const idx = opcode - 0x0A;
                    const val = try ctx.stack.pop();
                    if (idx < ctx.locals.values.items.len) {
                        try ctx.locals.set(idx, val);
                    }
                },

                // ldnull
                0x14 => try ctx.stack.push(StackValue.null),

                // ldc.i4.m1, ldc.i4.0..8
                0x15 => try ctx.stack.push(StackValue{ .int32 = -1 }),
                0x16 => try ctx.stack.push(StackValue{ .int32 = 0 }),
                0x17 => try ctx.stack.push(StackValue{ .int32 = 1 }),
                0x18 => try ctx.stack.push(StackValue{ .int32 = 2 }),
                0x19 => try ctx.stack.push(StackValue{ .int32 = 3 }),
                0x1A => try ctx.stack.push(StackValue{ .int32 = 4 }),
                0x1B => try ctx.stack.push(StackValue{ .int32 = 5 }),
                0x1C => try ctx.stack.push(StackValue{ .int32 = 6 }),
                0x1D => try ctx.stack.push(StackValue{ .int32 = 7 }),
                0x1E => try ctx.stack.push(StackValue{ .int32 = 8 }),

                // ldc.i4.s
                0x1F => {
                    if (ip >= ctx.code.len) return ExecError.InvalidInstruction;
                    const v = @as(i32, @as(i8, @bitCast(ctx.code[ip])));
                    ip += 1;
                    try ctx.stack.push(StackValue{ .int32 = v });
                },

                // ldc.i4
                0x20 => {
                    if (ip + 4 > ctx.code.len) return ExecError.InvalidInstruction;
                    const v = readIntSlice(i32, ctx.code, ip);
                    ip += 4;
                    try ctx.stack.push(StackValue{ .int32 = v });
                },

                // ldc.i8
                0x21 => {
                    if (ip + 8 > ctx.code.len) return ExecError.InvalidInstruction;
                    const v = readIntSlice(i64, ctx.code, ip);
                    ip += 8;
                    try ctx.stack.push(StackValue{ .int64 = v });
                },

                // ldc.r4
                0x22 => {
                    if (ip + 4 > ctx.code.len) return ExecError.InvalidInstruction;
                    const v = @as(f32, @bitCast(readIntSlice(u32, ctx.code, ip)));
                    ip += 4;
                    try ctx.stack.push(StackValue{ .float32 = v });
                },

                // ldc.r8
                0x23 => {
                    if (ip + 8 > ctx.code.len) return ExecError.InvalidInstruction;
                    const v = @as(f64, @bitCast(readIntSlice(u64, ctx.code, ip)));
                    ip += 8;
                    try ctx.stack.push(StackValue{ .float64 = v });
                },

                // dup
                0x25 => {
                    const val = try ctx.stack.peek();
                    try ctx.stack.push(val);
                },

                // pop
                0x26 => _ = try ctx.stack.pop(),

                // call
                0x28 => {
                    if (ip + 4 > ctx.code.len) return ExecError.InvalidInstruction;
                    const token = readIntSlice(u32, ctx.code, ip);
                    ip += 4;
                    try self.handleCall(ctx, token, false);
                },

                // ret
                0x2A => {
                    if (ctx.stack.values.items.len > 0) return ctx.stack.pop();
                    return StackValue.null;
                },

                // br
                0x38 => {
                    if (ip + 1 > ctx.code.len) return ExecError.InvalidInstruction;
                    const offset: i32 = @as(i8, @bitCast(ctx.code[ip]));
                    ip = @as(u32, @intCast(@as(i32, @intCast(ip)) + offset));
                },

                // brfalse
                0x39 => {
                    if (ip + 1 > ctx.code.len) return ExecError.InvalidInstruction;
                    const val = try ctx.stack.pop();
                    const is_false = switch (val) {
                        .int32 => |v| v == 0,
                        .object => |o| o == null,
                        .null => true,
                        else => false,
                    };
                    if (is_false) {
                        const offset: i32 = @as(i8, @bitCast(ctx.code[ip]));
                        ip = @as(u32, @intCast(@as(i32, @intCast(ip)) + offset));
                    } else {
                        ip += 1;
                    }
                },

                // brtrue
                0x3A => {
                    if (ip + 1 > ctx.code.len) return ExecError.InvalidInstruction;
                    const val = try ctx.stack.pop();
                    const is_true = switch (val) {
                        .int32 => |v| v != 0,
                        .object => |o| o != null,
                        .null => false,
                        else => true,
                    };
                    if (is_true) {
                        const offset: i32 = @as(i8, @bitCast(ctx.code[ip]));
                        ip = @as(u32, @intCast(@as(i32, @intCast(ip)) + offset));
                    } else {
                        ip += 1;
                    }
                },

                // beq, bge, bgt, ble, blt, bne_un
                0x3B, 0x3C, 0x3D, 0x3E, 0x3F, 0x40 => {
                    if (ip + 1 > ctx.code.len) return ExecError.InvalidInstruction;
                    const b = try ctx.stack.pop();
                    const a = try ctx.stack.pop();
                    var cmp: i64 = 0;
                    if (@as(?i64, a.int32)) |av| {
                        if (@as(?i64, b.int32)) |bv| cmp = av - bv;
                    }
                    const take_branch = switch (opcode) {
                        0x3B => cmp == 0,
                        0x3C => cmp >= 0,
                        0x3D => cmp > 0,
                        0x3E => cmp <= 0,
                        0x3F => cmp < 0,
                        0x40 => cmp != 0,
                        else => false,
                    };
                    if (take_branch) {
                        const offset: i32 = @as(i8, @bitCast(ctx.code[ip]));
                        ip = @as(u32, @intCast(@as(i32, @intCast(ip)) + offset));
                    } else {
                        ip += 1;
                    }
                },

                // Arithmetic
                0x58 => { // add
                    const b = try ctx.stack.pop();
                    const a = try ctx.stack.pop();
                    try ctx.stack.push(binaryArith(a, b, .add));
                },
                0x59 => { // sub
                    const b = try ctx.stack.pop();
                    const a = try ctx.stack.pop();
                    try ctx.stack.push(binaryArith(a, b, .sub));
                },
                0x5A => { // mul
                    const b = try ctx.stack.pop();
                    const a = try ctx.stack.pop();
                    try ctx.stack.push(binaryArith(a, b, .mul));
                },
                0x5B => { // div
                    const b = try ctx.stack.pop();
                    const a = try ctx.stack.pop();
                    try ctx.stack.push(binaryArith(a, b, .div));
                },

                // Neg
                0x65 => {
                    const a = try ctx.stack.pop();
                    try ctx.stack.push(switch (a) {
                        .int32 => |v| StackValue{ .int32 = -v },
                        .int64 => |v| StackValue{ .int64 = -v },
                        else => return ExecError.InvalidInstruction,
                    });
                },

                // ldlen
                0x8E => {
                    const arr = try ctx.stack.pop();
                    const len: u32 = switch (arr) {
                        .object => |obj| if (obj != null) @intCast(0) else 0,
                        else => return ExecError.InvalidInstruction,
                    };
                    try ctx.stack.push(StackValue{ .int32 = @as(i32, @intCast(len)) });
                },

                // conv operations
                0x67 => { // conv.i1
                    const a = try ctx.stack.pop();
                    const val: i32 = switch (a) {
                        .int32 => |v| @as(i32, @as(i8, @truncate(v))),
                        else => 0,
                    };
                    try ctx.stack.push(StackValue{ .int32 = val });
                },
                0x68 => { // conv.i2
                    const a = try ctx.stack.pop();
                    const val: i32 = switch (a) {
                        .int32 => |v| @as(i32, @as(i16, @truncate(v))),
                        else => 0,
                    };
                    try ctx.stack.push(StackValue{ .int32 = val });
                },
                0x69 => { // conv.i4
                    const a = try ctx.stack.pop();
                    try ctx.stack.push(StackValue{ .int32 = switch (a) {
                        .int32 => |v| v,
                        .int64 => |v| @as(i32, @truncate(v)),
                        .float32 => |v| @as(i32, @intCast(@as(i64, @intFromFloat(v)))),
                        .float64 => |v| @as(i32, @intCast(@as(i64, @intFromFloat(v)))),
                        else => 0,
                    } });
                },
                0x6A => { // conv.i8
                    const a = try ctx.stack.pop();
                    try ctx.stack.push(StackValue{ .int64 = switch (a) {
                        .int32 => |v| @as(i64, v),
                        .int64 => |v| v,
                        .float32 => |v| @as(i64, @intFromFloat(v)),
                        .float64 => |v| @as(i64, @intFromFloat(v)),
                        else => 0,
                    } });
                },

                // callvirt
                0x6F => {
                    if (ip + 4 > ctx.code.len) return ExecError.InvalidInstruction;
                    const token = readIntSlice(u32, ctx.code, ip);
                    ip += 4;
                    try self.handleCall(ctx, token, true);
                },

                // newobj
                0x73 => {
                    if (ip + 4 > ctx.code.len) return ExecError.InvalidInstruction;
                    const token = readIntSlice(u32, ctx.code, ip);
                    ip += 4;
                    _ = token;
                    try ctx.stack.push(StackValue{ .object = null });
                },

                // ldstr
                0x72 => {
                    if (ip + 4 > ctx.code.len) return ExecError.InvalidInstruction;
                    const token = readIntSlice(u32, ctx.code, ip);
                    ip += 4;
                    const str = try self.getStringFromToken(token);
                    try ctx.stack.push(StackValue{ .string = str });
                },

                // castclass / isinst
                0x74, 0x75 => {
                    if (ip + 4 > ctx.code.len) return ExecError.InvalidInstruction;
                    _ = readIntSlice(u32, ctx.code, ip);
                    ip += 4;
                },

                // throw
                0x7A => {
                    _ = try ctx.stack.pop();
                    if (comptime std.debug.runtime_safety) {
                        std.log.debug("CLR IL Executor: throw executed (stub)", .{});
                    }
                    return StackValue.null;
                },

                // ldfld / ldflda
                0x7B, 0x7C => {
                    if (ip + 4 > ctx.code.len) return ExecError.InvalidInstruction;
                    _ = readIntSlice(u32, ctx.code, ip);
                    ip += 4;
                    const obj = try ctx.stack.pop();
                    _ = obj;
                    try ctx.stack.push(StackValue{ .int32 = 0 });
                },

                // stfld
                0x7D => {
                    if (ip + 4 > ctx.code.len) return ExecError.InvalidInstruction;
                    _ = readIntSlice(u32, ctx.code, ip);
                    ip += 4;
                    const val = try ctx.stack.pop();
                    _ = val;
                    _ = try ctx.stack.pop(); // obj
                },

                // ldsfld
                0x7E => {
                    if (ip + 4 > ctx.code.len) return ExecError.InvalidInstruction;
                    _ = readIntSlice(u32, ctx.code, ip);
                    ip += 4;
                    try ctx.stack.push(StackValue{ .int32 = 0 });
                },

                // stsfld
                0x80 => {
                    if (ip + 4 > ctx.code.len) return ExecError.InvalidInstruction;
                    _ = readIntSlice(u32, ctx.code, ip);
                    ip += 4;
                    _ = try ctx.stack.pop();
                },

                // stobj
                0x81 => {
                    if (ip + 4 > ctx.code.len) return ExecError.InvalidInstruction;
                    _ = readIntSlice(u32, ctx.code, ip);
                    ip += 4;
                    _ = try ctx.stack.pop();
                    _ = try ctx.stack.pop();
                },

                // box
                0x8C => {
                    if (ip + 4 > ctx.code.len) return ExecError.InvalidInstruction;
                    _ = readIntSlice(u32, ctx.code, ip);
                    ip += 4;
                },

                // initobj
                0xCB => {
                    if (ip + 4 > ctx.code.len) return ExecError.InvalidInstruction;
                    _ = readIntSlice(u32, ctx.code, ip);
                    ip += 4;
                    _ = try ctx.stack.pop();
                },

                // Two-byte opcodes handled by prefix detection above
                0xFE => unreachable,

                else => {
                    if (comptime std.debug.runtime_safety) {
                        std.log.debug("CLR IL: unsupported opcode 0x{x:0>2}", .{opcode});
                    }
                    return ExecError.NotSupported;
                },
            }
        }
        return StackValue.null;
    }

    fn handleCall(self: *ILExecutor, ctx: *MethodContext, token: u32, _: bool) ExecError!void {
        // IL tokens use standard ECMA-335 encoding: table in upper 8 bits, row in lower 24 bits
        const table_id = clr_format.standardTokenTable(token);
        const row_index_1based = clr_format.standardTokenRow(token);

        if (table_id == clr_format.TABLE_METHODDEF) {
            if (row_index_1based < 1 or row_index_1based > self.assembly.metadata.method_defs.items.len) return;
            const md = self.assembly.metadata.method_defs.items[row_index_1based - 1];
            const method_name = clr_metadata.readString(self.assembly.metadata.heap.string, md.name);

            if (comptime std.debug.runtime_safety) {
                std.log.debug("CLR IL: call MethodDef '{s}' (row {d}) rva=0x{x}", .{ method_name, row_index_1based, md.rva });
            }

            if (md.rva != 0) {
                const body = self.resolveMethodBody(md.rva) catch |err| {
                    if (comptime std.debug.runtime_safety) {
                        std.log.debug("  resolveMethodBody(RVA 0x{x}) failed: {s}", .{ md.rva, @errorName(err) });
                    }
                    return;
                };

                var sub_ctx = MethodContext.init(self.allocator, self.assembly, self.pe_data, token, body, &.{});
                defer sub_ctx.deinit();
                _ = self.executeCode(&sub_ctx) catch {};
            }
        } else if (table_id == clr_format.TABLE_MEMBERREF) {
            if (row_index_1based < 1 or row_index_1based > self.assembly.metadata.member_refs.items.len) return;
            const mr = self.assembly.metadata.member_refs.items[row_index_1based - 1];
            const method_name = clr_metadata.readString(self.assembly.metadata.heap.string, mr.name);

            if (comptime std.debug.runtime_safety) {
                std.log.debug("CLR IL: call MemberRef '{s}' (row {d})", .{ method_name, row_index_1based });
            }

            if (self.bridge) |bridge| {
                _ = bridge.callWinFormsMethod(method_name, ctx.args) catch {};
            }
        }
    }

    pub fn executeMethod(self: *ILExecutor, method_token: u32, args: []const StackValue) ExecError!StackValue {
        const table_id = clr_format.standardTokenTable(method_token);
        const row_index_1based = clr_format.standardTokenRow(method_token);
        if (table_id != clr_format.TABLE_METHODDEF or row_index_1based < 1)
            return ExecError.InvalidToken;
        if (row_index_1based > self.assembly.metadata.method_defs.items.len)
            return ExecError.InvalidToken;

        const md = self.assembly.metadata.method_defs.items[row_index_1based - 1];
        const body = self.resolveMethodBody(md.rva) catch return ExecError.InvalidInstruction;

        var ctx = MethodContext.init(self.allocator, self.assembly, self.pe_data, method_token, body, args);
        defer ctx.deinit();
        return self.executeCode(&ctx);
    }

    fn getStringFromToken(self: *ILExecutor, token: u32) ![]const u8 {
        const us_offset = clr_format.standardTokenRow(token);
        if (us_offset >= self.assembly.metadata.heap.user_string.len) return ExecError.InvalidToken;
        const data = self.assembly.metadata.heap.user_string[us_offset..];
        if (data.len < 1) return ExecError.InvalidToken;
        const len = @as(usize, data[0]);
        if (us_offset + 1 + len > self.assembly.metadata.heap.user_string.len)
            return ExecError.InvalidToken;
        return data[1 .. 1 + len];
    }
};

const ArithOp = enum { add, sub, mul, div };

fn binaryArith(a: StackValue, b: StackValue, op: ArithOp) StackValue {
    return switch (a) {
        .int32 => |x| switch (b) {
            .int32 => |y| StackValue{ .int32 = switch (op) {
                .add => x +% y,
                .sub => x -% y,
                .mul => x *% y,
                .div => if (y != 0) @divTrunc(x, y) else 0,
            } },
            .float32 => |y| StackValue{ .float32 = switch (op) {
                .add => @as(f32, @floatFromInt(x)) + y,
                .sub => @as(f32, @floatFromInt(x)) - y,
                .mul => @as(f32, @floatFromInt(x)) * y,
                .div => @as(f32, @floatFromInt(x)) / y,
            } },
            .float64 => |y| StackValue{ .float64 = switch (op) {
                .add => @as(f64, @floatFromInt(x)) + y,
                .sub => @as(f64, @floatFromInt(x)) - y,
                .mul => @as(f64, @floatFromInt(x)) * y,
                .div => @as(f64, @floatFromInt(x)) / y,
            } },
            else => StackValue{ .int32 = 0 },
        },
        .int64 => |x| switch (b) {
            .int64 => |y| StackValue{ .int64 = switch (op) {
                .add => x +% y,
                .sub => x -% y,
                .mul => x *% y,
                .div => if (y != 0) @divTrunc(x, y) else 0,
            } },
            else => StackValue{ .int64 = 0 },
        },
        .float32 => |x| switch (b) {
            .float32 => |y| StackValue{ .float32 = switch (op) {
                .add => x + y,
                .sub => x - y,
                .mul => x * y,
                .div => x / y,
            } },
            .int32 => |y| StackValue{ .float32 = switch (op) {
                .add => x + @as(f32, @floatFromInt(y)),
                .sub => x - @as(f32, @floatFromInt(y)),
                .mul => x * @as(f32, @floatFromInt(y)),
                .div => x / @as(f32, @floatFromInt(y)),
            } },
            else => StackValue{ .float32 = 0 },
        },
        .float64 => |x| switch (b) {
            .float64 => |y| StackValue{ .float64 = switch (op) {
                .add => x + y,
                .sub => x - y,
                .mul => x * y,
                .div => x / y,
            } },
            .int32 => |y| StackValue{ .float64 = switch (op) {
                .add => x + @as(f64, @floatFromInt(y)),
                .sub => x - @as(f64, @floatFromInt(y)),
                .mul => x * @as(f64, @floatFromInt(y)),
                .div => x / @as(f64, @floatFromInt(y)),
            } },
            else => StackValue{ .float64 = 0 },
        },
        .uint32 => |x| switch (b) {
            .uint32 => |y| StackValue{ .uint32 = switch (op) {
                .add => x +% y,
                .sub => x -% y,
                .mul => x *% y,
                .div => if (y != 0) x / y else 0,
            } },
            else => StackValue{ .uint32 = 0 },
        },
        else => StackValue{ .int32 = 0 },
    };
}
