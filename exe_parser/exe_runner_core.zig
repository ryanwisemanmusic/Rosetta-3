const std = @import("std");
const fmt = @import("pe_format.zig");
const parser = @import("pe_parser.zig");
const pkg = @import("rosetta3_package.zig");
const trace = @import("mandatory_trace.zig");

fn machineName(machine: u16) []const u8 {
    return switch (machine) {
        fmt.coff.machine_i386 => "i386",
        fmt.coff.machine_amd64 => "amd64",
        else => "unknown",
    };
}

pub fn run(init: std.process.Init, exe_path: []const u8, log_path: [:0]const u8, launch_allowed: bool) !void {
    const allocator = init.arena.allocator();
    const exe_bytes = try std.Io.Dir.cwd().readFileAlloc(init.io, exe_path, allocator, .limited(128 * 1024 * 1024));

    trace.enable(log_path.ptr);
    defer trace.disable();

    var intro_buf: [512]u8 = undefined;
    const intro = try std.fmt.bufPrint(&intro_buf,
        "# PE intake session\nfile = {s}\nlog = {s}\n",
        .{ exe_path, log_path },
    );
    trace.logText(intro);

    const image = try parser.parse(allocator, exe_bytes);
    defer allocator.free(image.sections);

    var summary_buf: [512]u8 = undefined;
    const summary = try std.fmt.bufPrint(&summary_buf,
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
        const section_line = try std.fmt.bufPrint(&section_buf,
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
        const launch_note = try std.fmt.bufPrint(&launch_buf,
            "rosetta3_package = true\nsuite = {s}\nlaunch = {s}\ncwd = {s}\ninteractive = {s}\n",
            .{
                metadata.suite,
                metadata.launch,
                metadata.cwd,
                if (metadata.interactive) "true" else "false",
            },
        );
        trace.logText(launch_note);

        std.debug.print(
            "  package: Rosetta 3 app wrapper\n  launch: {s}\n  cwd: {s}\n",
            .{ metadata.launch, metadata.cwd },
        );

        if (!launch_allowed) {
            trace.logText("launch_skipped = parse_only\n");
            return;
        }

        var child = try std.process.spawn(init.io, .{
            .argv = &.{metadata.launch},
            .cwd = .{ .path = metadata.cwd },
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

    trace.logText("note = raw guest execution handoff is not implemented yet\n");

    std.debug.print(
        "Rosetta 3 EXE intake\n  file: {s}\n  machine: {s} (0x{X:0>4})\n  entry RVA: 0x{X:0>8}\n  sections: {d}\n  trace: {s}\n",
        .{
            exe_path,
            machineName(image.machine),
            image.machine,
            image.entry_rva,
            image.number_of_sections,
            log_path,
        },
    );
}
