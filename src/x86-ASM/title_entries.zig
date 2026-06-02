const trail_entry = @import("titles/trail_entry.zig");
const stack_entry = @import("titles/stack_entry.zig");
const block_window_entry = @import("titles/block_window_entry.zig");
const scene = @import("graphics/scene.zig");
const detection = @import("assembly_detection.zig");
const assets = @import("assembly_assets.zig");

comptime {
    _ = trail_entry;
    _ = stack_entry;
    _ = block_window_entry;
    _ = scene;
    _ = detection;
    _ = assets;
}
