const std = @import("std");

pub const common_thunk = struct {
    pub const read_key: u32 = 0;
    pub const render: u32 = 1;
    pub const game_over: u32 = 2;
    pub const sleep: u32 = 3;
    pub const extension_base: u32 = 4;
};

test "common thunk ids reserve a stable extension range" {
    try std.testing.expectEqual(@as(u32, 0), common_thunk.read_key);
    try std.testing.expectEqual(@as(u32, 3), common_thunk.sleep);
    try std.testing.expectEqual(@as(u32, 4), common_thunk.extension_base);
}
