const title_runtime = @import("../title_runtime.zig");
const win32_thunks = @import("../win32_thunks.zig");
const program = @import("trail_program.zig");
const thunks = @import("trail_thunks.zig");

extern "C" fn rosetta3_cli_init() void;
extern "C" fn rosetta3_cli_deinit() void;

pub export fn rosetta3_run_snax86() void {
    rosetta3_cli_init();
    defer rosetta3_cli_deinit();
    rosetta3_run_snax86_core_inner();
}

fn rosetta3_run_snax86_core_inner() void {
    title_runtime.runTitle(.{
        .install_imports = win32_thunks.register_win32_console_thunks,
        .register_thunks = thunks.registerThunks,
        .load_program = program.loadProgram,
        // snake has no block grid rendering yet — skip grid source
    });
}

pub export fn rosetta3_run_snax86_core() void {
    rosetta3_run_snax86_core_inner();
}
