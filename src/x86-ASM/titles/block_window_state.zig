const contract = @import("../title_contract.zig");

pub const DATA_BASE: u32 = 0x0000;

pub const STRINGS_OFFSET: u32 = 0x0000;
pub const MyWindowClassName: u32 = 0x0000;
pub const MyWindowName: u32 = 0x000E;
pub const NextText: u32 = 0x0018;
pub const GameOverText: u32 = 0x001D;
pub const ScoreText: u32 = 0x0027;

pub const Hwnd: u32 = 0x0030;
pub const PaintDC: u32 = 0x0034;
pub const IntermediateDC: u32 = 0x0038;
pub const BlackBrush: u32 = 0x003C;
pub const OrangeBrush: u32 = 0x0040;
pub const MagentaBrush: u32 = 0x0044;

pub const GRID: u32 = 0x0048;
pub const GRID_WIDTH: i32 = 10;
pub const GRID_HEIGHT: i32 = 20;

pub const GridRowStartIndices: u32 = 0x0110;
pub const GridColors: u32 = 0x0124;

pub const TickHi: u32 = 0x0144;
pub const TickLo: u32 = 0x0148;
pub const PerfFreqHi: u32 = 0x014C;
pub const PerfFreqLo: u32 = 0x0150;

pub const ScoreTextBuffer: u32 = 0x0154;
pub const SCORE: u32 = 0x015C;
pub const LineScores: u32 = 0x0160;

pub const pieces1: u32 = 0x0174;
pub const pieces2: u32 = 0x0190;

pub const ACTIVE: u32 = 0x01AC;
pub const ACTIVE_COLOR_INDEX: u32 = 0x01B4;
pub const NEXT_BLOCK_INDEX: u32 = 0x01B5;
pub const Pieces: u32 = 0x01B8;

pub const AXIS_X: u32 = 0x01F0;
pub const AXIS_Y: u32 = 0x01F1;

pub const TOP_EXT: u32 = 0x01F4;
pub const LEFT_EXT: u32 = 0x01F8;
pub const PREDICT: u32 = 0x01FC;
pub const GAME_OVER: u32 = 0x0204;
pub const RUNNING: u32 = 0x0205;

pub const PROGRAM_BASE: u32 = 0x10000;
pub const DATA_SIZE: u32 = 0x0206;

pub const THUNK_READ_KEY: u32 = contract.common_thunk.read_key;
pub const THUNK_RENDER: u32 = contract.common_thunk.render;
pub const THUNK_GAME_OVER: u32 = contract.common_thunk.game_over;
pub const THUNK_SLEEP: u32 = contract.common_thunk.sleep;
pub const THUNK_PROCESS_FRAME: u32 = contract.common_thunk.extension_base;
pub const THUNK_INIT_GAME: u32 = contract.common_thunk.extension_base + 1;
pub const THUNK_NEW_BLOCK: u32 = contract.common_thunk.extension_base + 2;
