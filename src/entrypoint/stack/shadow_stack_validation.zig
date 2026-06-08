const std = @import("std");
const runtime_abi = @import("runtime_abi_handshake");

pub const ShadowStackViolation = enum {
    bad_return_address,
    mismatched_call_ret,
    stack_imbalance,
    helper_call_stack_leak,
    return_to_unmapped_guest_memory,
};

pub const CallRetTracker = struct {
    expected_return: u64,
    call_depth: i32,
};

pub fn validateReturnAddress(
    comptime domain: []const u8,
    comptime check: []const u8,
    actual: u64,
    expected: u64,
) void {
    runtime_abi.common.noteValidation();
    if (actual != expected) {
        runtime_abi.common.violation(
            domain,
            check,
            "return_address_mismatch: expected=0x{x} actual=0x{x}",
            .{ expected, actual },
        );
    }
}

pub fn validateCallRetDepth(
    comptime domain: []const u8,
    comptime check: []const u8,
    depth: i32,
    min_depth: i32,
    max_depth: i32,
) void {
    runtime_abi.common.noteValidation();
    if (depth < min_depth or depth > max_depth) {
        runtime_abi.common.violation(
            domain,
            check,
            "call_ret_depth_out_of_bounds: depth={d} min={d} max={d}",
            .{ depth, min_depth, max_depth },
        );
    }
}

pub fn validateStackBalance(
    comptime domain: []const u8,
    comptime check: []const u8,
    depth: u32,
    expected_depth: u32,
) void {
    runtime_abi.common.noteValidation();
    if (depth != expected_depth) {
        runtime_abi.common.violation(
            domain,
            check,
            "stack_imbalance: depth={d} expected={d}",
            .{ depth, expected_depth },
        );
    }
}

pub fn validateHelperBoundary(
    comptime domain: []const u8,
    comptime check: []const u8,
    helper_ssp_before: u64,
    helper_ssp_after: u64,
) void {
    runtime_abi.common.noteValidation();
    if (helper_ssp_after != helper_ssp_before) {
        runtime_abi.common.violation(
            domain,
            check,
            "helper_stack_leak: ssp changed from 0x{x} to 0x{x}",
            .{ helper_ssp_before, helper_ssp_after },
        );
    }
}

pub fn validateGuestMemoryMapping(
    comptime domain: []const u8,
    comptime check: []const u8,
    return_address: u64,
    guest_code_base: u64,
    guest_code_size: u64,
) void {
    runtime_abi.common.noteValidation();
    const end = guest_code_base + guest_code_size;
    if (return_address < guest_code_base or return_address >= end) {
        runtime_abi.common.violation(
            domain,
            check,
            "return_to_unmapped_memory: addr=0x{x} guest=[0x{x}, 0x{x})",
            .{ return_address, guest_code_base, end },
        );
    }
}

test "validateReturnAddress passes on match" {
    validateReturnAddress("test", "ret_check", 0x1000, 0x1000);
}

test "validateReturnAddress logs violation on mismatch" {
    validateReturnAddress("test", "ret_check", 0x1000, 0x2000);
}

test "validateCallRetDepth passes within bounds" {
    validateCallRetDepth("test", "depth_check", 5, 0, 10);
}

test "validateCallRetDepth logs violation below min" {
    validateCallRetDepth("test", "depth_check", -1, 0, 10);
}

test "validateCallRetDepth logs violation above max" {
    validateCallRetDepth("test", "depth_check", 11, 0, 10);
}

test "validateStackBalance passes when balanced" {
    validateStackBalance("test", "balance", 3, 3);
}

test "validateStackBalance logs violation on imbalance" {
    validateStackBalance("test", "balance", 3, 0);
}

test "validateHelperBoundary passes when ssp unchanged" {
    validateHelperBoundary("test", "helper", 0x1000, 0x1000);
}

test "validateHelperBoundary logs violation when ssp changed" {
    validateHelperBoundary("test", "helper", 0x1000, 0x1008);
}

test "validateGuestMemoryMapping passes on valid address" {
    validateGuestMemoryMapping("test", "guest_mem", 0x2000, 0x1000, 0x2000);
}

test "validateGuestMemoryMapping logs violation on unmapped address" {
    validateGuestMemoryMapping("test", "guest_mem", 0x4000, 0x1000, 0x2000);
}

test "validateGuestMemoryMapping logs violation below base" {
    validateGuestMemoryMapping("test", "guest_mem", 0x800, 0x1000, 0x2000);
}
