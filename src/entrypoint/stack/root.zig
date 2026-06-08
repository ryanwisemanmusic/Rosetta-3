pub const placement = struct {
    pub const StackPlacement = @import("entrypoint_stack_placement_common").StackPlacement;
    pub const StackInitResult = @import("entrypoint_stack_placement_common").StackInitResult;
    pub const computePhysicalSp = @import("entrypoint_stack_placement_common").computePhysicalSp;
    pub const applyStackPlacement = @import("entrypoint_stack_placement_common").applyStackPlacement;
    pub const DOS = @import("entrypoint_stack_placement_dos");
    pub const x86 = @import("entrypoint_stack_placement_x86");
    pub const x64 = @import("entrypoint_stack_placement_x64");
    pub const NEON = @import("entrypoint_stack_placement_neon");
};

pub const shadow_stack = struct {
    pub const ShadowStackPlacement = @import("entrypoint_shadow_stack_common").ShadowStackPlacement;
    pub const ShadowStackState = @import("entrypoint_shadow_stack_common").ShadowStackState;
    pub const computeInitialSsp = @import("entrypoint_shadow_stack_common").computeInitialSsp;
    pub const initShadowStack = @import("entrypoint_shadow_stack_common").initShadowStack;
    pub const pushEntry = @import("entrypoint_shadow_stack_common").pushEntry;
    pub const popEntry = @import("entrypoint_shadow_stack_common").popEntry;
    pub const peekEntry = @import("entrypoint_shadow_stack_common").peekEntry;
    pub const validateEntry = @import("entrypoint_shadow_stack_common").validateEntry;
    pub const x86 = @import("entrypoint_shadow_stack_x86");
    pub const x64 = @import("entrypoint_shadow_stack_x64");
    pub const NEON = @import("entrypoint_shadow_stack_neon");
};

pub const alignment = @import("entrypoint_stack_alignment");
pub const shadow_stack_validation = @import("entrypoint_shadow_stack_validation");

test "placement namespace provides types" {
    const p: placement.StackPlacement = .{
        .base = 0x1000,
        .size = 0x100,
        .alignment = 16,
        .grows_down = true,
    };
    _ = p;
}

test "shadow_stack namespace provides types" {
    const s: shadow_stack.ShadowStackPlacement = .{
        .base = 0x2000,
        .size = 0x100,
        .entry_size = 4,
    };
    _ = s;
}

test "arch-specific placement modules accessible" {
    _ = placement.DOS;
    _ = placement.x86;
    _ = placement.x64;
    _ = placement.NEON;
}

test "arch-specific shadow_stack modules accessible" {
    _ = shadow_stack.x86;
    _ = shadow_stack.x64;
    _ = shadow_stack.NEON;
}

test "alignment module accessible" {
    _ = alignment;
}

test "shadow_stack_validation module accessible" {
    _ = shadow_stack_validation;
}
