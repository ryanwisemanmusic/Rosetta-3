const std = @import("std");
const fmt = @import("pe_format.zig");
const parser = @import("pe_parser.zig");
const pkg = @import("rosette_package.zig");
const trace = @import("mandatory_trace.zig");
const opcodeName = @import("../disasm_logger/x86_opcode_names.zig").opcodeName;
const x86_disasm = @import("../disasm_logger/x86_disasm.zig");

fn machineName(machine: u16) []const u8 {
    return switch (machine) {
        fmt.coff.machine_i386 => "i386",
        fmt.coff.machine_amd64 => "amd64",
        else => "unknown",
    };
}

fn writeFileUri(buffer: []u8, path: []const u8) ![]const u8 {
    var index: usize = 0;
    if (buffer.len < 7) return error.NoSpaceLeft;
    std.mem.copyForwards(u8, buffer[index..], "file://");
    index += 7;

    for (path) |ch| {
        if (ch == ' ') {
            if (index + 3 > buffer.len) return error.NoSpaceLeft;
            std.mem.copyForwards(u8, buffer[index..], "%20");
            index += 3;
        } else {
            if (index + 1 > buffer.len) return error.NoSpaceLeft;
            buffer[index] = ch;
            index += 1;
        }
    }

    return buffer[0..index];
}

pub fn run(init: std.process.Init, exe_path: []const u8, log_path: [:0]const u8, launch_allowed: bool) !void {
    const allocator = init.arena.allocator();
    const exe_bytes = try std.Io.Dir.cwd().readFileAlloc(init.io, exe_path, allocator, .limited(128 * 1024 * 1024));

    trace.enable(log_path.ptr);
    defer trace.disable();

    var intro_buf: [512]u8 = undefined;
    const intro = try std.fmt.bufPrint(
        &intro_buf,
        "# PE intake session\nfile = {s}\nlog = {s}\n",
        .{ exe_path, log_path },
    );
    trace.logText(intro);

    const image = try parser.parse(allocator, exe_bytes);
    defer allocator.free(image.sections);

    var summary_buf: [512]u8 = undefined;
    const summary = try std.fmt.bufPrint(
        &summary_buf,
        "machine = {s} (0x{X:0>4})\nentry_rva = 0x{X:0>8}\nimage_base = 0x{X}\nsection_alignment = 0x{X:0>8}\nfile_alignment = 0x{X:0>8}\nsize_of_image = 0x{X:0>8}\nsize_of_headers = 0x{X:0>8}\nsections = {d}\n",
        .{
            machineName(image.machine),
            image.machine,
            image.entry_rva,
            image.image_base,
            image.section_alignment,
            image.file_alignment,
            image.size_of_image,
            image.size_of_headers,
            image.number_of_sections,
        },
    );
    trace.logText(summary);

    for (image.sections, 0..) |section, index| {
        const raw_name = std.mem.sliceTo(&section.name, 0);
        const section_name = if (raw_name.len == 0) "<unnamed>" else raw_name;
        var section_buf: [256]u8 = undefined;
        const section_line = try std.fmt.bufPrint(
            &section_buf,
            "section[{d}] name={s} va=0x{X:0>8} vsz=0x{X:0>8} raw=0x{X:0>8} raw_off=0x{X:0>8} chars=0x{X:0>8}\n",
            .{
                index,
                section_name,
                section.virtual_address,
                section.virtual_size,
                section.raw_size,
                section.raw_offset,
                section.characteristics,
            },
        );
        trace.logText(section_line);
    }

    if (pkg.findSection(&image, pkg.PackageSectionName)) |section| {
        const metadata = try pkg.parseMetadata(pkg.rawSectionBytes(exe_bytes, section));
        var launch_buf: [1024]u8 = undefined;
        const launch_note = try std.fmt.bufPrint(
            &launch_buf,
            "rosette_package = true\nsuite = {s}\nlaunch = {s}\ncwd = {s}\ninteractive = {s}\n",
            .{
                metadata.suite,
                metadata.launch,
                metadata.cwd,
                if (metadata.interactive) "true" else "false",
            },
        );
        trace.logText(launch_note);

        std.debug.print(
            "  package: Rosette app wrapper\n  launch: {s}\n  cwd: {s}\n",
            .{ metadata.launch, metadata.cwd },
        );

        if (!launch_allowed) {
            trace.logText("launch_skipped = parse_only\n");
            return;
        }

        const exe_dir = std.fs.path.dirname(exe_path) orelse ".";
        const resolved_launch = if (std.fs.path.isAbsolute(metadata.launch))
            metadata.launch
        else
            try std.fs.path.join(allocator, &.{ exe_dir, metadata.launch });
        const resolved_cwd = if (std.fs.path.isAbsolute(metadata.cwd))
            metadata.cwd
        else
            try std.fs.path.join(allocator, &.{ exe_dir, metadata.cwd });

        const final_launch = blk: {
            std.Io.Dir.accessAbsolute(init.io, resolved_launch, .{}) catch {
                const fallback = try std.fmt.allocPrint(allocator, "{s}.host", .{metadata.suite});
                const fallback_path = try std.fs.path.join(allocator, &.{ exe_dir, fallback });
                std.Io.Dir.accessAbsolute(init.io, fallback_path, .{}) catch {
                    std.debug.print("  error: host binary not found at\n    {s}\n  or\n    {s}\n  ensure the .host file is placed next to the .exe\n", .{ resolved_launch, fallback_path });
                    return error.HostBinaryMissing;
                };
                break :blk fallback_path;
            };
            break :blk resolved_launch;
        };

        var child = try std.process.spawn(init.io, .{
            .argv = &.{final_launch},
            .cwd = .{ .path = resolved_cwd },
            .stdin = .inherit,
            .stdout = .inherit,
            .stderr = .inherit,
        });
        const term = try child.wait(init.io);
        var term_buf: [128]u8 = undefined;
        const term_line = try std.fmt.bufPrint(&term_buf, "launch_term = {s}\n", .{@tagName(term)});
        trace.logText(term_line);
        return;
    }

    if (launch_allowed) {
        const exec_inst = @import("../../x86-ASM/instruction_operations.zig");
        const Executor = exec_inst.Executor;
        const exec_engine = @import("../../x86-ASM/execution_engine.zig");
        const win32 = @import("../../x86-ASM/win32_thunks.zig");

        trace.logText("execution = true\n");

        const stack_size: u32 = 1024 * 1024;
        const mem_size = image.size_of_image + stack_size;
        var exec = Executor.init(allocator, mem_size);
        defer exec.deinit();

        exec.mem.base = @as(u32, @truncate(image.image_base));

        for (image.sections) |section| {
            const raw = pkg.rawSectionBytes(exe_bytes, &section);
            const dest = section.virtual_address;
            const copy_len = @min(@as(usize, section.raw_size), raw.len);
            if (dest + copy_len <= exec.mem.data.len) {
                @memcpy(exec.mem.data[dest .. dest + copy_len], raw[0..copy_len]);
            }
        }

        const image_base_u32: u32 = @as(u32, @truncate(image.image_base));
        exec.regs.eip = image_base_u32 + image.entry_rva;
        exec.regs.esp = image_base_u32 + image.size_of_image + stack_size - 16;
        exec.regs.ebp = exec.regs.esp;
        exec.regs.cs = 0x23;
        exec.regs.ds = 0x2B;
        exec.regs.ss = 0x2B;

        win32.register_win32_console_thunks(&exec);

        var thunk_table = exec_engine.ThunkTable{};
        const entry_eip = exec.regs.eip;
        exec_engine.run(&exec, &thunk_table);

        if (exec.regs.eip == entry_eip) {
            {
                const base = exec.mem.base;
                const entry_off = entry_eip -| base;
                if (entry_off < exec.mem.data.len) {
                    const window_len = @min(@as(usize, 64), exec.mem.data.len - entry_off);
                    const raw_window = exec.mem.data[entry_off .. entry_off + window_len];
                    var di_off: usize = 0;
                    var di_count: u32 = 0;
                    while (di_off < raw_window.len and di_count < 8) {
                        const line = x86_disasm.decodeInstruction(entry_eip + @as(u32, @intCast(di_off)), raw_window[di_off..]) catch break;
                        di_off += line.byte_len;
                        di_count += 1;
                        var hex_buf2: [48]u8 = undefined;
                        var hpos: usize = 0;
                        for (0..line.byte_len) |j| {
                            if (j > 0) {
                                hex_buf2[hpos] = ' ';
                                hpos += 1;
                            }
                            const hi_val = line.bytes[j] >> 4;
                            const lo_val = line.bytes[j] & 0xF;
                            hex_buf2[hpos] = @as(u8, if (hi_val < 10) '0' + hi_val else 'A' + hi_val - 10);
                            hpos += 1;
                            hex_buf2[hpos] = @as(u8, if (lo_val < 10) '0' + lo_val else 'A' + lo_val - 10);
                            hpos += 1;
                        }
                        var di_buf: [256]u8 = undefined;
                        const di_line = std.fmt.bufPrint(&di_buf, "; disasm: 0x{X:0>8}: {s}  {s}\n", .{ line.address, hex_buf2[0..hpos], line.text[0..line.text_len] }) catch break;
                        trace.logText(di_line);
                    }
                }
            }
            const base = exec.mem.base;
            const off = exec.regs.eip -| base;
            if (off + 12 <= exec.mem.data.len) {
                const raw = exec.mem.data[off .. off + 12];
                var hex_buf: [128]u8 = undefined;
                var hex_len: usize = 0;
                for (raw, 0..) |b, i| {
                    if (i > 0) {
                        hex_buf[hex_len] = ' ';
                        hex_len += 1;
                    }
                    _ = std.fmt.bufPrint(hex_buf[hex_len..], "{X:0>2}", .{b}) catch break;
                    hex_len += 2;
                }
                const x86_name = opcodeName(raw[0]);
                var bad_opcode_buf: [320]u8 = undefined;
                const bad_opcode_line = std.fmt.bufPrint(&bad_opcode_buf, "0x{X:0>8}: <bad opcode {d}> [{s}] ; {s}\n", .{ exec.regs.eip, raw[0], hex_buf[0..hex_len], x86_name }) catch unreachable;
                trace.logText(bad_opcode_line);
                std.debug.print("  {s}", .{bad_opcode_line});
            }
        }

        trace.logText("execution = false\n");

        var trace_uri_buf: [1024]u8 = undefined;
        var cwd_buf: [std.fs.max_path_bytes]u8 = undefined;
        const trace_display = blk: {
            if (std.c.getcwd(&cwd_buf, cwd_buf.len)) |cwd_ptr| {
                const cwd_abs = std.mem.sliceTo(cwd_ptr, 0);
                if (std.mem.startsWith(u8, log_path, cwd_abs) and log_path.len > cwd_abs.len and log_path[cwd_abs.len] == std.fs.path.sep) {
                    break :blk log_path[cwd_abs.len + 1 ..];
                }
            }
            break :blk try writeFileUri(&trace_uri_buf, log_path);
        };

        std.debug.print(
            "Rosette EXE intake\n  file: {s}\n  machine: {s} (0x{X:0>4})\n  entry RVA: 0x{X:0>8}\n  sections: {d}\n  trace: {s}\n  raw execution: stopped at 0x{X:0>8}\n",
            .{
                exe_path,
                machineName(image.machine),
                image.machine,
                image.entry_rva,
                image.number_of_sections,
                trace_display,
                exec.regs.eip,
            },
        );
    } else {
        trace.logText("launch_skipped = parse_only\n");

        var trace_uri_buf: [1024]u8 = undefined;
        var cwd_buf: [std.fs.max_path_bytes]u8 = undefined;
        const trace_display = blk: {
            if (std.c.getcwd(&cwd_buf, cwd_buf.len)) |cwd_ptr| {
                const cwd_abs = std.mem.sliceTo(cwd_ptr, 0);
                if (std.mem.startsWith(u8, log_path, cwd_abs) and log_path.len > cwd_abs.len and log_path[cwd_abs.len] == std.fs.path.sep) {
                    break :blk log_path[cwd_abs.len + 1 ..];
                }
            }
            break :blk try writeFileUri(&trace_uri_buf, log_path);
        };

        std.debug.print(
            "Rosette EXE intake\n  file: {s}\n  machine: {s} (0x{X:0>4})\n  entry RVA: 0x{X:0>8}\n  sections: {d}\n  trace: {s}\n",
            .{
                exe_path,
                machineName(image.machine),
                image.machine,
                image.entry_rva,
                image.number_of_sections,
                trace_display,
            },
        );
    }
}
