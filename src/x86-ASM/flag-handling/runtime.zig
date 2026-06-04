const runtime_abi = @import("runtime_abi_handshake");
const reg_map = @import("../register_mapping.zig");
const bridge = @import("bridge_flags");
const reg_trace = @import("../register-tracing/runtime.zig");

const MASK_CF: u64 = 1 << 0;
const MASK_PF: u64 = 1 << 2;
const MASK_AF: u64 = 1 << 4;
const MASK_ZF: u64 = 1 << 6;
const MASK_SF: u64 = 1 << 7;
const MASK_TF: u64 = 1 << 8;
const MASK_IF: u64 = 1 << 9;
const MASK_DF: u64 = 1 << 10;
const MASK_OF: u64 = 1 << 11;

pub const FlagsEffect = struct {
    updated_mask: u64 = 0,
    preserved_mask: u64 = 0,
    undefined_mask: u64 = 0,
};

fn parity8(value: u8) u1 {
    return @intFromBool((@popCount(value) & 1) == 0);
}

fn lahfImage(flags: reg_map.Flags) u8 {
    return (@as(u8, flags.sf) << 7) |
        (@as(u8, flags.zf) << 6) |
        (@as(u8, 0) << 5) |
        (@as(u8, flags.af) << 4) |
        (@as(u8, 0) << 3) |
        (@as(u8, flags.pf) << 2) |
        (@as(u8, 1) << 1) |
        @as(u8, flags.cf);
}

fn baseEvent(scope: []const u8, before_raw: u32, after_raw: u32, effect: FlagsEffect, regs: *const reg_map.RegisterFile) bridge.FlagEvent {
    var event = bridge.makeFlagEvent(.x86, reg_trace.currentSequence(), scope);
    event.before_raw = before_raw;
    event.after_raw = after_raw;
    event.updated_mask = effect.updated_mask;
    event.preserved_mask = effect.preserved_mask;
    event.undefined_mask = effect.undefined_mask;
    event.parity_flag = .{ .valid = true, .value = regs.flags.pf };
    event.auxiliary_flag = .{ .valid = true, .value = regs.flags.af };
    event.zero_flag = .{ .valid = true, .value = regs.flags.zf };
    event.sign_flag = .{ .valid = true, .value = regs.flags.sf };
    event.carry_flag = .{ .valid = true, .value = regs.flags.cf };
    event.overflow_flag = .{ .valid = true, .value = regs.flags.of };
    event.direction_flag = .{ .valid = true, .value = regs.flags.df };
    event.interrupt_flag = .{ .valid = true, .value = regs.flags.if_ };
    event.trap_flag = .{ .valid = true, .value = regs.flags.tf };
    event.lahf_image = .{ .valid = true, .value = lahfImage(regs.flags) };
    event.sahf_image = event.lahf_image;
    return event;
}

fn reportShadow(source: bridge.FlagEvent) void {
    var target = source;
    target.arch = .arm64;
    bridge.reportFlagEvent(target, reg_trace.emitOperationContext);
}

pub fn validateArithmeticFlags(scope: []const u8, before_raw: u32, regs: *const reg_map.RegisterFile, lhs: u32, rhs: u32, result: u32, effect: FlagsEffect, is_sub: bool) void {
    const low_result: u8 = @truncate(result);
    const expected_pf = parity8(low_result);
    if (regs.flags.pf != expected_pf)
        runtime_abi.common.violation("x86-flags", "parity_flag", "scope={s} result=0x{x} PF got={d} expected={d}", .{ scope, result, regs.flags.pf, expected_pf });

    const expected_af: u1 = if (is_sub)
        @intFromBool((lhs & 0xF) < (rhs & 0xF))
    else
        @intFromBool(((lhs & 0xF) + (rhs & 0xF)) > 0xF);
    if ((effect.updated_mask & MASK_AF) != 0 and regs.flags.af != expected_af)
        runtime_abi.common.violation("x86-flags", "auxiliary_flag", "scope={s} lhs=0x{x} rhs=0x{x} AF got={d} expected={d}", .{ scope, lhs, rhs, regs.flags.af, expected_af });

    const event = baseEvent(scope, before_raw, regs.flags.raw(), effect, regs);
    bridge.reportFlagEvent(event, reg_trace.emitOperationContext);
    reportShadow(event);
}

pub fn validateLogicalFlags(scope: []const u8, before_raw: u32, regs: *const reg_map.RegisterFile, result: u32, effect: FlagsEffect) void {
    const expected_pf = parity8(@truncate(result));
    if (regs.flags.pf != expected_pf)
        runtime_abi.common.violation("x86-flags", "parity_flag", "scope={s} logical result=0x{x} PF got={d} expected={d}", .{ scope, result, regs.flags.pf, expected_pf });
    const event = baseEvent(scope, before_raw, regs.flags.raw(), effect, regs);
    bridge.reportFlagEvent(event, reg_trace.emitOperationContext);
    reportShadow(event);
}

pub fn validatePreservedFlags(scope: []const u8, before_raw: u32, after_raw: u32, preserved_mask: u64, regs: *const reg_map.RegisterFile) void {
    if (((before_raw ^ after_raw) & preserved_mask) != 0)
        runtime_abi.common.violation("x86-flags", "preserved_flags", "scope={s} preserved mask 0x{x} changed before=0x{x} after=0x{x}", .{ scope, preserved_mask, before_raw, after_raw });
    const event = baseEvent(scope, before_raw, after_raw, .{
        .updated_mask = 0,
        .preserved_mask = preserved_mask,
        .undefined_mask = 0,
    }, regs);
    bridge.reportFlagEvent(event, reg_trace.emitOperationContext);
    reportShadow(event);
}

pub fn validateStringDirection(scope: []const u8, before_index: u32, after_index: u32, step: u32, regs: *const reg_map.RegisterFile) void {
    const expected_after = if (regs.flags.df == 0) before_index +% step else before_index -% step;
    if (after_index != expected_after)
        runtime_abi.common.violation("x86-flags", "direction_flag_behavior", "scope={s} DF={d} before=0x{x} after=0x{x} expected=0x{x}", .{ scope, regs.flags.df, before_index, after_index, expected_after });
    const raw = regs.flags.raw();
    const event = baseEvent(scope, raw, raw, .{
        .updated_mask = 0,
        .preserved_mask = MASK_DF,
        .undefined_mask = 0,
    }, regs);
    bridge.reportFlagEvent(event, reg_trace.emitOperationContext);
    reportShadow(event);
}

pub fn arithmeticMask() u64 {
    return MASK_CF | MASK_PF | MASK_AF | MASK_ZF | MASK_SF | MASK_OF;
}

pub fn logicalMask() u64 {
    return MASK_CF | MASK_PF | MASK_ZF | MASK_SF | MASK_OF;
}

pub fn incDecMask() u64 {
    return MASK_PF | MASK_AF | MASK_ZF | MASK_SF | MASK_OF;
}

pub fn shiftMask() u64 {
    return MASK_CF | MASK_PF | MASK_ZF | MASK_SF;
}

pub fn preservedControlMask() u64 {
    return MASK_DF | MASK_IF | MASK_TF;
}
