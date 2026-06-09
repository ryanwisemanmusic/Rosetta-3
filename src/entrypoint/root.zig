pub const bss = struct {
    pub const SectionZero = @import("entrypoint_bss_init_common").SectionZero;
    pub const applyBssSections = @import("entrypoint_bss_init_common").applyBssSections;
    pub const DOS = @import("entrypoint_bss_init_dos");
    pub const x86 = @import("entrypoint_bss_init_x86");
    pub const x64 = @import("entrypoint_bss_init_x64");
    pub const NEON = @import("entrypoint_bss_init_neon");
};

pub const data = struct {
    pub const SectionCopy = @import("entrypoint_data_init_common").SectionCopy;
    pub const applyDataSections = @import("entrypoint_data_init_common").applyDataSections;
    pub const DOS = @import("entrypoint_data_init_dos");
    pub const x86 = @import("entrypoint_data_init_x86");
    pub const x64 = @import("entrypoint_data_init_x64");
    pub const NEON = @import("entrypoint_data_init_neon");
};

pub const array = @import("entrypoint_array_preserve_root");
pub const map = @import("entrypoint_map_preserve_root");
pub const code_text_segment = @import("entrypoint_code_text_segment");
pub const text_grid = @import("entrypoint_text_grid");
pub const pages = @import("entrypoint_pages");
pub const stack = @import("entrypoint_stack");

test "bss namespace provides types and arch modules" {
    const s: bss.SectionZero = .{ .offset = 0, .size = 16 };
    _ = s;
    _ = bss.DOS;
    _ = bss.x86;
    _ = bss.x64;
    _ = bss.NEON;
}

test "data namespace provides types and arch modules" {
    const s: data.SectionCopy = .{ .offset = 0, .bytes = "test" };
    _ = s;
    _ = data.DOS;
    _ = data.x86;
    _ = data.x64;
    _ = data.NEON;
}

test "array namespace provides types and arch modules" {
    const a: array.ArrayPreserve = .{ .base = 0, .element_size = 4, .capacity = 8, .count = 0 };
    _ = a;
    _ = array.DOS;
    _ = array.x86;
    _ = array.x64;
    _ = array.NEON;
}

test "map namespace provides types and arch modules" {
    const m: map.MapPreserve = .{ .base = 0, .capacity = 4, .count = 0 };
    _ = m;
    _ = map.MapEntry;
    _ = map.DOS;
    _ = map.x86;
    _ = map.x64;
    _ = map.NEON;
}

test "text_grid module accessible" {
    _ = text_grid.cellWidth;
    _ = text_grid.TextSpan;
}

test "code text segment module accessible" {
    const segment = code_text_segment.Segment.init(0x1000, 16, true, ".text");
    const guard = code_text_segment.Guard{
        .image_base = 0x1000,
        .image_size = 0x100,
        .segments = &.{segment},
    };
    try @import("std").testing.expect(code_text_segment.checkInstructionPointer(guard, 0x1000, 1).isValid());
}

test "pages module accessible" {
    _ = pages.PAGE_4K;
    _ = pages.PageAllocator;
}

test "stack module accessible" {
    _ = stack.placement;
    _ = stack.shadow_stack;
}
