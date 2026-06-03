const std = @import("std");
const common = @import("../common.zig");

pub const AccessKind = enum { fetch, read, write };
pub const ArithmeticKind = enum { add, sub, inc, dec, cmp, test_and, logical, mul, imul, div, shift };

pub fn init() void {
    common.acquire();
}

pub fn deinit() void {
    common.release();
}

pub fn validateTitleSpec(memory_size: u32, stack_top: u32, grid_offset: u32, grid_width: u32, grid_height: u32, active_type_offset: u32) void {
    common.noteValidation();
    if (memory_size == 0) common.violation("x86-title", "memory_size", "memory size is zero", .{});
    if (stack_top > memory_size)
        common.violation("x86-title", "stack_top", "stack top 0x{x} exceeds memory size 0x{x}", .{ stack_top, memory_size });
    if (grid_width > 0 and grid_height > 0) {
        const bytes = @as(u64, grid_width) * @as(u64, grid_height);
        if (grid_offset >= memory_size or grid_offset + bytes > memory_size)
            common.violation("x86-title", "grid_bounds", "grid offset 0x{x} size {d}x{d} exceeds memory 0x{x}", .{ grid_offset, grid_width, grid_height, memory_size });
        if (active_type_offset < grid_offset or active_type_offset >= memory_size)
            common.violation("x86-title", "active_piece_offset", "active piece offset 0x{x} invalid for grid offset 0x{x}", .{ active_type_offset, grid_offset });
    }
}

pub fn validateExecutorState(phase: []const u8, mem_base: u32, mem_len: usize, eip: u32, esp: u32, ebp: u32, flags_raw: u32) void {
    common.noteValidation();
    if (mem_len == 0) {
        common.violation("x86", "empty_memory", "{s}: executor memory is empty", .{phase});
        return;
    }
    const mem_end = @as(u64, mem_base) + mem_len;
    if (@as(u64, eip) < mem_base or @as(u64, eip) > mem_end)
        common.violation("x86", "eip_range", "{s}: EIP 0x{x} outside [0x{x}, 0x{x}]", .{ phase, eip, mem_base, mem_end });
    if (@as(u64, esp) < mem_base or @as(u64, esp) > mem_end)
        common.violation("x86", "esp_range", "{s}: ESP 0x{x} outside [0x{x}, 0x{x}]", .{ phase, esp, mem_base, mem_end });
    if (@as(u64, ebp) < mem_base or @as(u64, ebp) > mem_end)
        common.violation("x86", "ebp_range", "{s}: EBP 0x{x} outside [0x{x}, 0x{x}]", .{ phase, ebp, mem_base, mem_end });
    if ((flags_raw & 0x2) == 0)
        common.violation("x86", "eflags_reserved1", "{s}: EFLAGS bit1 cleared (raw=0x{x})", .{ phase, flags_raw });
}

pub fn validateInstructionFetch(start_eip: u32, mem_base: u32, mem_len: usize, instruction_size: usize) void {
    common.noteValidation();
    if (start_eip < mem_base) {
        common.violation("x86", "fetch_underflow", "instruction fetch at 0x{x} below base 0x{x}", .{ start_eip, mem_base });
        return;
    }
    const offset = @as(usize, @intCast(start_eip - mem_base));
    if (offset + instruction_size > mem_len)
        common.violation("x86", "fetch_overflow", "instruction fetch at 0x{x} width {d} exceeds memory length {d}", .{ start_eip, instruction_size, mem_len });
}

pub fn validateFlatMemoryAccess(kind: AccessKind, base: u32, mem_len: usize, addr: u32, width: usize) void {
    common.noteValidation();
    if (addr < base) {
        common.violation("x86", "memory_underflow", "{s} at 0x{x} below base 0x{x}", .{ @tagName(kind), addr, base });
        return;
    }
    const offset = @as(usize, @intCast(addr - base));
    if (offset + width > mem_len)
        common.violation("x86", "memory_overflow", "{s} at 0x{x} width {d} exceeds memory length {d}", .{ @tagName(kind), addr, width, mem_len });
}

pub fn validateArithmetic32(kind: ArithmeticKind, lhs: u32, rhs: u32, result: u32, zf: u1, sf: u1, cf: u1, of: u1) void {
    common.noteValidation();
    switch (kind) {
        .add => {
            const wide = @as(u64, lhs) + @as(u64, rhs);
            const expected_cf: u1 = @intFromBool(wide > std.math.maxInt(u32));
            const lhs_sign = (lhs >> 31) & 1;
            const rhs_sign = (rhs >> 31) & 1;
            const res_sign = (result >> 31) & 1;
            const expected_of: u1 = @intCast((~lhs_sign & ~rhs_sign & res_sign) | (lhs_sign & rhs_sign & ~res_sign));
            if (cf != expected_cf)
                common.violation("x86", "carry_mismatch", "add carry mismatch lhs=0x{x} rhs=0x{x} result=0x{x} got={d} expected={d}", .{ lhs, rhs, result, cf, expected_cf });
            if (of != expected_of)
                common.violation("x86", "overflow_mismatch", "add overflow mismatch lhs=0x{x} rhs=0x{x} result=0x{x} got={d} expected={d}", .{ lhs, rhs, result, of, expected_of });
        },
        .sub, .cmp => {
            const expected_cf: u1 = @intFromBool(lhs < rhs);
            const lhs_sign = (lhs >> 31) & 1;
            const rhs_sign = (rhs >> 31) & 1;
            const res_sign = (result >> 31) & 1;
            const expected_of: u1 = @intCast((lhs_sign ^ rhs_sign) & (lhs_sign ^ res_sign));
            if (cf != expected_cf)
                common.violation("x86", "borrow_mismatch", "{s} borrow mismatch lhs=0x{x} rhs=0x{x} result=0x{x} got={d} expected={d}", .{ @tagName(kind), lhs, rhs, result, cf, expected_cf });
            if (of != expected_of)
                common.violation("x86", "overflow_mismatch", "{s} overflow mismatch lhs=0x{x} rhs=0x{x} result=0x{x} got={d} expected={d}", .{ @tagName(kind), lhs, rhs, result, of, expected_of });
        },
        .inc => {
            const expected_of: u1 = @intFromBool(lhs == 0x7FFF_FFFF);
            if (of != expected_of)
                common.violation("x86", "overflow_mismatch", "inc overflow mismatch value=0x{x} result=0x{x} got={d} expected={d}", .{ lhs, result, of, expected_of });
        },
        .dec => {
            const expected_of: u1 = @intFromBool(lhs == 0x8000_0000);
            if (of != expected_of)
                common.violation("x86", "overflow_mismatch", "dec overflow mismatch value=0x{x} result=0x{x} got={d} expected={d}", .{ lhs, result, of, expected_of });
        },
        .logical, .test_and => {
            if (cf != 0 or of != 0)
                common.violation("x86", "logical_flags", "{s}: logical op produced CF={d} OF={d}", .{ @tagName(kind), cf, of });
        },
        else => {},
    }
    const expected_zf: u1 = @intFromBool(result == 0);
    const expected_sf: u1 = @intCast((result >> 31) & 1);
    if (zf != expected_zf)
        common.violation("x86", "zero_flag", "{s}: zero flag mismatch result=0x{x} got={d} expected={d}", .{ @tagName(kind), result, zf, expected_zf });
    if (sf != expected_sf)
        common.violation("x86", "sign_flag", "{s}: sign flag mismatch result=0x{x} got={d} expected={d}", .{ @tagName(kind), result, sf, expected_sf });
}

pub fn validateMul32(signed_mode: bool, lhs: u32, rhs: u32, eax: u32, edx: u32, cf: u1, of: u1) void {
    common.noteValidation();
    if (!signed_mode) {
        const wide = @as(u64, lhs) * @as(u64, rhs);
        const expected_eax: u32 = @truncate(wide);
        const expected_edx: u32 = @truncate(wide >> 32);
        const expected_flag: u1 = @intFromBool(expected_edx != 0);
        if (eax != expected_eax or edx != expected_edx)
            common.violation("x86", "mul_result", "mul mismatch lhs=0x{x} rhs=0x{x} got edx:eax=0x{x}:0x{x} expected 0x{x}:0x{x}", .{ lhs, rhs, edx, eax, expected_edx, expected_eax });
        if (cf != expected_flag or of != expected_flag)
            common.violation("x86", "mul_flags", "mul flags mismatch got CF={d} OF={d} expected={d}", .{ cf, of, expected_flag });
        return;
    }
    const a = @as(i32, @bitCast(lhs));
    const b = @as(i32, @bitCast(rhs));
    const wide = @as(i64, a) * @as(i64, b);
    const wide_bits: u64 = @bitCast(wide);
    const expected_eax: u32 = @truncate(wide_bits);
    const expected_edx: u32 = @truncate(wide_bits >> 32);
    const sign_ext: u32 = if ((expected_eax & 0x8000_0000) != 0) 0xFFFF_FFFF else 0;
    const expected_flag: u1 = @intFromBool(expected_edx != sign_ext);
    if (eax != expected_eax or edx != expected_edx)
        common.violation("x86", "imul_result", "imul mismatch lhs=0x{x} rhs=0x{x} got edx:eax=0x{x}:0x{x} expected 0x{x}:0x{x}", .{ lhs, rhs, edx, eax, expected_edx, expected_eax });
    if (cf != expected_flag or of != expected_flag)
        common.violation("x86", "imul_flags", "imul flags mismatch got CF={d} OF={d} expected={d}", .{ cf, of, expected_flag });
}

pub fn validateDiv32(edx_before: u32, eax_before: u32, divisor: u32, eax_after: u32, edx_after: u32) void {
    common.noteValidation();
    if (divisor == 0) {
        common.violation("x86", "divide_by_zero", "division attempted with EDX:EAX=0x{x}:0x{x} divisor=0", .{ edx_before, eax_before });
        return;
    }
    const dividend = (@as(u64, edx_before) << 32) | eax_before;
    const expected_q: u32 = @truncate(dividend / divisor);
    const expected_r: u32 = @truncate(dividend % divisor);
    if (eax_after != expected_q or edx_after != expected_r)
        common.violation("x86", "div_result", "div mismatch dividend=0x{x} divisor=0x{x} got q=0x{x} r=0x{x} expected q=0x{x} r=0x{x}", .{ dividend, divisor, eax_after, edx_after, expected_q, expected_r });
}
