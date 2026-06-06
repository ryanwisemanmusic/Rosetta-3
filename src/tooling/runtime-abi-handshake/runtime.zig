pub const common = @import("common.zig");
pub const x86 = @import("x86/runtime.zig");
pub const dos = @import("dos/runtime.zig");
pub const x64 = @import("x64/runtime.zig");
pub const arm64 = @import("arm64/runtime.zig");
pub const graphics = @import("graphics/runtime.zig");
pub const isa = @import("isa/runtime.zig");

test "runtime handshake catches out-of-range x86 fetch without crashing" {
    x86.validateInstructionFetch(0x200, 0x100, 16, 8);
}
