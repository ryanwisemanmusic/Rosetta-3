pub const MapPreserve = @import("entrypoint_map_preserve_common").MapPreserve;
pub const MapEntry = @import("entrypoint_map_preserve_common").MapEntry;
pub const initMapPreserve = @import("entrypoint_map_preserve_common").initMapPreserve;
pub const insert = @import("entrypoint_map_preserve_common").mapInsert;
pub const lookup = @import("entrypoint_map_preserve_common").mapLookup;
pub const remove = @import("entrypoint_map_preserve_common").mapRemove;
pub const DOS = @import("entrypoint_map_preserve_dos");
pub const x86 = @import("entrypoint_map_preserve_x86");
pub const x64 = @import("entrypoint_map_preserve_x64");
pub const NEON = @import("entrypoint_map_preserve_neon");

test "arch modules accessible" {
    _ = DOS;
    _ = x86;
    _ = x64;
    _ = NEON;
}
