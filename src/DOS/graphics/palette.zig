pub const Color = u32;

pub const COLOR_TEXT: Color = 0xFFFFFFFF;
pub const COLOR_BORDER: Color = 0xA55A00FF;
pub const COLOR_GRID_BG: Color = 0x1010D8FF;

pub const tetris_piece_colors = [_]Color{
    0x00FFFFFF,
    0xFFFF00FF,
    0xFF00FFFF,
    0x00FF00FF,
    0xFF0000FF,
    0xFF7F00FF,
    0xFFFF00FF,
};

pub const tetris_piece_dim_colors = [_]Color{
    0x007F7FFF,
    0x7F7F00FF,
    0x7F007FFF,
    0x007F00FF,
    0x7F0000FF,
    0x7F3F00FF,
    0x7F7F00FF,
};
