const title_runtime = @import("../title_runtime.zig");
const program = @import("stack_program.zig");
const thunks = @import("stack_thunks.zig");

extern "C" fn rosetta3_cli_init() void;
extern "C" fn rosetta3_cli_deinit() void;

pub export fn rosetta3_run_tetrisx86() void {
    rosetta3_cli_init();
    defer rosetta3_cli_deinit();

    title_runtime.runTitle(.{
        .register_thunks = thunks.registerThunks,
        .load_program = program.loadProgram,
    });
}
