pub const ExecutionMode = enum {
    real_mode_16,
    protected_mode_32_bridge,
};

pub const GraphicsBackend = enum {
    dos_scene_host,
};

pub const profile = struct {
    pub const execution_mode: ExecutionMode = .real_mode_16;
    pub const graphics_backend: GraphicsBackend = .dos_scene_host;
    pub const target_name = "DOS";
};
