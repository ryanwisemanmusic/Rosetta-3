const contract = @import("../title_contract.zig");

pub const HEAD_X: u32 = 0x0000;
pub const HEAD_Y: u32 = 0x0004;
pub const TARGET_X: u32 = 0x0008;
pub const TARGET_Y: u32 = 0x000C;
pub const SCORE: u32 = 0x0010;
pub const VEL_X: u32 = 0x0014;
pub const VEL_Y: u32 = 0x0018;
pub const RNG_STATE: u32 = 0x001C;

pub const PROGRAM_BASE: u32 = 0x0100;

pub const SCREEN_WIDTH: i32 = 60;
pub const SCREEN_HEIGHT: i32 = 20;

pub const THUNK_READ_KEY: u32 = contract.common_thunk.read_key;
pub const THUNK_RENDER: u32 = contract.common_thunk.render;
pub const THUNK_GAME_OVER: u32 = contract.common_thunk.game_over;
pub const THUNK_SLEEP: u32 = contract.common_thunk.sleep;
