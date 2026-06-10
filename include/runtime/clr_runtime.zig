const std = @import("std");
const clr_assembly = @import("clr_assembly.zig");
const clr_executor = @import("clr_executor.zig");
const clr_metadata = @import("clr_metadata.zig");
const clr_format = @import("clr_pe_format.zig");
const winforms_bridge = @import("../winforms/winforms_bridge.zig");

const Allocator = std.mem.Allocator;

const RuntimeError = error{
    AssemblyLoadFailed,
    EntryPointNotFound,
    ExecutionFailed,
    OutOfMemory,
};

pub const CLRRuntime = struct {
    allocator: Allocator,
    assembly: ?clr_assembly.Assembly = null,
    pe_data: []const u8 = &[_]u8{},
    executor: ?clr_executor.ILExecutor = null,
    winforms_app: ?winforms_bridge.WinFormsApp = null,
    winforms_bridge: ?winforms_bridge.WinFormsBridge = null,
    loaded: bool = false,
    isWinForms: bool = false,

    fn init(allocator: Allocator) CLRRuntime {
        return CLRRuntime{ .allocator = allocator };
    }

    fn deinit(self: *CLRRuntime) void {
        if (self.assembly) |*a| a.deinit();
        if (self.winforms_app) |*app| app.deinit();
    }

    pub fn loadAssembly(self: *CLRRuntime, data: []const u8) RuntimeError!void {
        // Stub implementation for incremental development
        // Basic PE header detection without full metadata parsing
        if (data.len < 64 or data[0] != 0x4D or data[1] != 0x5A)
            return RuntimeError.AssemblyLoadFailed;

        var pe_offset: u32 = 0;
        @memcpy(@as([*]u8, @ptrCast(&pe_offset))[0..4], data[60..64]);
        if (pe_offset + 4 >= data.len or !std.mem.eql(u8, data[pe_offset..][0..4], "PE\x00\x00"))
            return RuntimeError.AssemblyLoadFailed;

        self.pe_data = data;

        // Don't call parseAssembly yet - it may be incomplete and cause hangs
        // Just mark as loaded for basic detection
        self.assembly = null;
        self.loaded = true;
        self.isWinForms = true;
        
        if (comptime std.debug.runtime_safety) {
            std.log.debug("CLR Runtime: loadAssembly stub - assembly loaded without full parsing", .{});
        }
    }

    fn findEntryPoint(self: *CLRRuntime) ?u32 {
        // First try the CLR header entry token
        const asmbl = &self.assembly.?;
        const entry_token = asmbl.entry_point_token;
        const table_id = clr_format.standardTokenTable(entry_token);
        const row_index = clr_format.standardTokenRow(entry_token);

        if (table_id == clr_format.TABLE_METHODDEF and row_index >= 1 and row_index <= asmbl.metadata.method_defs.items.len) {
            const md = asmbl.metadata.method_defs.items[row_index - 1];
            if (md.rva > 0 and md.impl_flags != 2) {
                return entry_token;
            }
        }

        // Fallback: find method named "Main"
        for (asmbl.metadata.method_defs.items, 0..) |md, i| {
            if (md.rva == 0) continue;
            const name = clr_metadata.readString(asmbl.metadata.heap.string, md.name);
            if (std.mem.eql(u8, name, "Main")) {
                return clr_format.makeStandardToken(clr_format.TABLE_METHODDEF, @as(u32, @intCast(i + 1)));
            }
        }

        return null;
    }

    pub fn runAssembly(self: *CLRRuntime) RuntimeError!void {
        // Stub implementation for incremental development
        // Full IL execution will be added after metadata parsing is complete
        if (comptime std.debug.runtime_safety) {
            std.log.debug("CLR Runtime: runAssembly called (stub - no IL execution yet)", .{});
        }
        
        if (!self.loaded) return RuntimeError.AssemblyLoadFailed;
        
        // Don't try to execute IL yet - this prevents hanging
        // Return immediately to let exe runner complete
        return;
    }

    pub fn getAssemblyInfo(self: *CLRRuntime) ?struct { name: []const u8, version: []const u8 } {
        const asmbl = self.assembly orelse return null;
        if (asmbl.metadata.type_defs.items.len > 0) {
            const first = asmbl.metadata.type_defs.items[0];
            const type_name = clr_metadata.readString(asmbl.metadata.heap.string, first.name);
            const ns = clr_metadata.readString(asmbl.metadata.heap.string, first.namespace);
            return .{ .name = type_name, .version = ns };
        }
        return null;
    }
};

var g_runtime: ?CLRRuntime = null;
var g_allocator: ?Allocator = null;

pub fn initRuntime(allocator: Allocator) RuntimeError!void {
    g_allocator = allocator;
    g_runtime = CLRRuntime.init(allocator);
}

pub fn setAssemblyData(data: []const u8) RuntimeError!void {
    if (g_runtime) |*r| {
        try r.loadAssembly(data);
    } else {
        return RuntimeError.AssemblyLoadFailed;
    }
}

pub fn deinitRuntime() void {
    if (g_runtime) |*r| r.deinit();
    g_runtime = null;
    g_allocator = null;
}

pub fn getRuntime() ?*CLRRuntime {
    return if (g_runtime) |*r| r else null;
}

export fn clr_runtime_init() c_int {
    _ = g_allocator;
    return 1;
}

export fn clr_runtime_load_assembly(data: [*]const u8, size: usize) c_int {
    if (g_runtime == null) return 0;
    g_runtime.?.loadAssembly(data[0..size]) catch return 0;
    return 1;
}

export fn clr_runtime_run() c_int {
    if (g_runtime == null) return 0;
    g_runtime.?.runAssembly() catch return 0;
    return 1;
}

export fn clr_runtime_cleanup() void {
    deinitRuntime();
}
