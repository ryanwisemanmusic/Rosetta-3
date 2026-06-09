const Executor = @import("../../../x86-ASM/instruction_operations.zig").Executor;
const imports = @import("../imports/imports.zig");

pub const THUNK_TAG_BASE: u32 = 0xF000_0000;
pub const THUNK_TAG_MASK: u32 = 0x0FFF_FFFF;

pub fn isThunkTag(value: u32) bool {
    return value >= THUNK_TAG_BASE;
}

pub fn indexToTag(index: u32) u32 {
    return THUNK_TAG_BASE | (index & THUNK_TAG_MASK);
}

pub fn tagToIndex(tag: u32) u32 {
    return tag & THUNK_TAG_MASK;
}

pub fn populateIatFromImports(exec: *Executor, import_dir: *const imports.ImportDirectory, image_base: u32) void {
    for (import_dir.descriptors, 0..) |desc, i| {
        const iat_va = image_base + desc.iat_rva;
        exec.mem.write32(iat_va, indexToTag(@intCast(i)));
    }
}

pub fn dispatchByTag(exec: *Executor, tag: u32, import_dir: *const imports.ImportDirectory) void {
    const index = tagToIndex(tag);
    if (index >= import_dir.descriptors.len) return;
    exec.dispatch_import(import_dir.descriptors[index].function_name);
}
