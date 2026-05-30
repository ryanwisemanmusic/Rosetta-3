const contract = @import("../title_contract.zig");

pub const GRID: u32 = 0x0000;
pub const GRID_WIDTH: i32 = 10;
pub const GRID_HEIGHT: i32 = 20;

pub const ACTIVE_TYPE: u32 = 0x00C8;
pub const ACTIVE_X: u32 = 0x00CC;
pub const ACTIVE_Y: u32 = 0x00D0;
pub const ACTIVE_ROT: u32 = 0x00D4;
pub const NEXT_TYPE: u32 = 0x00D8;
pub const SCORE: u32 = 0x00DC;
pub const LINES: u32 = 0x00E0;
pub const LEVEL: u32 = 0x00E4;
pub const DROP_COUNTER: u32 = 0x00E8;
pub const GAME_OVER_FLAG: u32 = 0x00EC;
pub const EXIT_FLAG: u32 = 0x00F0;
pub const DROP_TIMER: u32 = 0x00F4;

pub const PIECE_DATA: u32 = 0x0100;
pub const PROGRAM_BASE: u32 = 0x0200;

pub const THUNK_READ_KEY: u32 = contract.common_thunk.read_key;
pub const THUNK_RENDER: u32 = contract.common_thunk.render;
pub const THUNK_GAME_OVER: u32 = contract.common_thunk.game_over;
pub const THUNK_SLEEP: u32 = contract.common_thunk.sleep;
pub const THUNK_TRY_MOVE: u32 = contract.common_thunk.extension_base;
pub const THUNK_LOCK_PROCESS: u32 = contract.common_thunk.extension_base + 1;
