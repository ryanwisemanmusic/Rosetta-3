const std = @import("std");
const runtime_abi = @import("runtime_abi_handshake");
const c = @cImport({
    @cInclude("errno.h");
    @cInclude("stdio.h");
    @cInclude("stdlib.h");
    @cInclude("sys/stat.h");
    @cInclude("unistd.h");
});

const win = struct {
    const mz_signature: u16 = 0x5A4D;
    const pe_signature: u32 = 0x0000_4550;
    const pe32_magic: u16 = 0x10B;
    const pe64_magic: u16 = 0x20B;
    const image_numberof_directory_entries = 16;
    const resource_directory_index = 2;
    const rt_icon: u32 = 3;
    const rt_group_icon: u32 = 14;
};

const ParseError = error{
    BadDosHeader,
    BadPeHeader,
    UnsupportedPeMagic,
    MissingResourceDirectory,
    RvaNotMapped,
    TruncatedFile,
    IconIndexOutOfRange,
    NoGroupIcons,
};

const Section = struct {
    virtual_address: u32,
    virtual_size: u32,
    raw_size: u32,
    raw_offset: u32,
};

pub const ResourceDumpEntry = struct {
    type_id: u32,
    resource_id: u32,
    lang_id: u32,
    codepage: u32,
    size: u32,
    file_name: []u8,
};

const PeInfo = struct {
    resource_rva: u32,
    resource_size: u32,
    sections: []Section,
};

fn readU16(bytes: []const u8, offset: usize) ParseError!u16 {
    if (offset + 2 > bytes.len) return error.TruncatedFile;
    return @as(u16, bytes[offset]) |
        (@as(u16, bytes[offset + 1]) << 8);
}

fn readU32(bytes: []const u8, offset: usize) ParseError!u32 {
    if (offset + 4 > bytes.len) return error.TruncatedFile;
    return @as(u32, bytes[offset]) |
        (@as(u32, bytes[offset + 1]) << 8) |
        (@as(u32, bytes[offset + 2]) << 16) |
        (@as(u32, bytes[offset + 3]) << 24);
}

fn alignUp(value: u32, alignment: u32) u32 {
    if (alignment == 0) return value;
    return (value + alignment - 1) & ~(alignment - 1);
}

fn parsePe(allocator: std.mem.Allocator, bytes: []const u8) !PeInfo {
    if (try readU16(bytes, 0) != win.mz_signature) return error.BadDosHeader;
    const pe_offset = try readU32(bytes, 0x3C);
    if (try readU32(bytes, pe_offset) != win.pe_signature) return error.BadPeHeader;

    const file_header_offset = pe_offset + 4;
    const number_of_sections = try readU16(bytes, file_header_offset + 2);
    const size_of_optional_header = try readU16(bytes, file_header_offset + 16);
    const optional_header_offset = file_header_offset + 20;
    const optional_magic = try readU16(bytes, optional_header_offset);
    const data_dir_offset: usize = switch (optional_magic) {
        win.pe32_magic => optional_header_offset + 96,
        win.pe64_magic => optional_header_offset + 112,
        else => return error.UnsupportedPeMagic,
    };

    if (size_of_optional_header < data_dir_offset - optional_header_offset + (win.image_numberof_directory_entries * 8))
        return error.MissingResourceDirectory;

    const resource_dir_offset = data_dir_offset + (win.resource_directory_index * 8);
    const resource_rva = try readU32(bytes, resource_dir_offset);
    const resource_size = try readU32(bytes, resource_dir_offset + 4);
    if (resource_rva == 0 or resource_size == 0) return error.MissingResourceDirectory;

    const section_table_offset = optional_header_offset + size_of_optional_header;
    const sections = try allocator.alloc(Section, number_of_sections);
    errdefer allocator.free(sections);

    for (sections, 0..) |*section, i| {
        const entry_offset = section_table_offset + (i * 40);
        section.* = .{
            .virtual_size = try readU32(bytes, entry_offset + 8),
            .virtual_address = try readU32(bytes, entry_offset + 12),
            .raw_size = try readU32(bytes, entry_offset + 16),
            .raw_offset = try readU32(bytes, entry_offset + 20),
        };
    }

    return .{
        .resource_rva = resource_rva,
        .resource_size = resource_size,
        .sections = sections,
    };
}

fn deinitPe(allocator: std.mem.Allocator, pe: PeInfo) void {
    allocator.free(pe.sections);
}

fn rvaToOffset(pe: PeInfo, rva: u32) ParseError!usize {
    for (pe.sections) |section| {
        const mapped_size = @max(section.virtual_size, section.raw_size);
        const section_end = section.virtual_address + alignUp(mapped_size, 0x1000);
        if (rva >= section.virtual_address and rva < section_end) {
            const delta = rva - section.virtual_address;
            return @as(usize, section.raw_offset + delta);
        }
    }
    return error.RvaNotMapped;
}

fn resourceRootOffset(pe: PeInfo) ParseError!usize {
    return try rvaToOffset(pe, pe.resource_rva);
}

fn resourceEntryCount(bytes: []const u8, dir_offset: usize) ParseError!usize {
    const named = try readU16(bytes, dir_offset + 12);
    const ids = try readU16(bytes, dir_offset + 14);
    return named + ids;
}

fn resourceEntryId(bytes: []const u8, entry_offset: usize) ParseError!?u32 {
    const name = try readU32(bytes, entry_offset);
    if ((name & 0x8000_0000) != 0) return null;
    return name;
}

fn resourceEntryChildOffset(bytes: []const u8, root_offset: usize, entry_offset: usize) ParseError!struct { is_dir: bool, offset: usize } {
    const child = try readU32(bytes, entry_offset + 4);
    return .{
        .is_dir = (child & 0x8000_0000) != 0,
        .offset = root_offset + @as(usize, @intCast(child & 0x7FFF_FFFF)),
    };
}

fn resourceDataForEntry(bytes: []const u8, pe: PeInfo, root_offset: usize, entry_offset: usize) ParseError!struct {
    lang_id: u32,
    codepage: u32,
    size: u32,
    bytes: []const u8,
} {
    const name_child = try resourceEntryChildOffset(bytes, root_offset, entry_offset);
    if (!name_child.is_dir) return error.TruncatedFile;

    const lang_count = try resourceEntryCount(bytes, name_child.offset);
    if (lang_count == 0) return error.TruncatedFile;

    const lang_entry_offset = name_child.offset + 16;
    const lang_id = (try resourceEntryId(bytes, lang_entry_offset)) orelse 0;
    const lang_child = try resourceEntryChildOffset(bytes, root_offset, lang_entry_offset);
    if (lang_child.is_dir) return error.TruncatedFile;

    const data_rva = try readU32(bytes, lang_child.offset);
    const size = try readU32(bytes, lang_child.offset + 4);
    const codepage = try readU32(bytes, lang_child.offset + 8);
    const file_offset = try rvaToOffset(pe, data_rva);
    if (file_offset + size > bytes.len) return error.TruncatedFile;

    return .{
        .lang_id = lang_id,
        .codepage = codepage,
        .size = size,
        .bytes = bytes[file_offset .. file_offset + size],
    };
}

fn findResourceSubdirById(bytes: []const u8, root_offset: usize, dir_offset: usize, want_id: u32) ParseError!?usize {
    const count = try resourceEntryCount(bytes, dir_offset);
    const entries_offset = dir_offset + 16;
    for (0..count) |i| {
        const entry_offset = entries_offset + (i * 8);
        const name = try readU32(bytes, entry_offset);
        const child = try readU32(bytes, entry_offset + 4);
        if ((name & 0x8000_0000) != 0) continue;
        if (name != want_id) continue;
        if ((child & 0x8000_0000) == 0) return null;
        return root_offset + (child & 0x7FFF_FFFF);
    }
    return null;
}

fn nthResourceSubdir(bytes: []const u8, root_offset: usize, dir_offset: usize, index: usize) ParseError!?usize {
    const count = try resourceEntryCount(bytes, dir_offset);
    if (index >= count) return null;
    const entry_offset = dir_offset + 16 + (index * 8);
    const child = try readU32(bytes, entry_offset + 4);
    if ((child & 0x8000_0000) == 0) return null;
    return root_offset + (child & 0x7FFF_FFFF);
}

fn groupIconCount(bytes: []const u8, pe: PeInfo) !usize {
    const root_offset = try resourceRootOffset(pe);
    const type_dir = try findResourceSubdirById(bytes, root_offset, root_offset, win.rt_group_icon);
    if (type_dir == null) return 0;
    return try resourceEntryCount(bytes, type_dir.?);
}

fn validateIconIndex(bytes: []const u8, pe: PeInfo, index: usize) !void {
    const count = try groupIconCount(bytes, pe);
    if (count == 0) return error.NoGroupIcons;
    if (index >= count) return error.IconIndexOutOfRange;

    const root_offset = try resourceRootOffset(pe);
    const type_dir = (try findResourceSubdirById(bytes, root_offset, root_offset, win.rt_group_icon)).?;
    const name_dir = try nthResourceSubdir(bytes, root_offset, type_dir, index);
    if (name_dir == null) return error.IconIndexOutOfRange;
}

fn pathCandidates(allocator: std.mem.Allocator, path: []const u8) ![][]u8 {
    const prefixed_1 = try std.fmt.allocPrint(allocator, "dll/{s}", .{path});
    defer allocator.free(prefixed_1);
    const prefixed_2 = try std.fmt.allocPrint(allocator, "../dll/{s}", .{path});
    defer allocator.free(prefixed_2);
    const prefixed_3 = try std.fmt.allocPrint(allocator, "../../dll/{s}", .{path});
    defer allocator.free(prefixed_3);

    const out = try allocator.alloc([]u8, 4);
    errdefer {
        for (out) |item| {
            if (item.len != 0) allocator.free(item);
        }
        allocator.free(out);
    }

    out[0] = try allocator.dupe(u8, path);
    out[1] = try allocator.dupe(u8, prefixed_1);
    out[2] = try allocator.dupe(u8, prefixed_2);
    out[3] = try allocator.dupe(u8, prefixed_3);
    return out;
}

fn readFileAlloc(allocator: std.mem.Allocator, path: []const u8, max_bytes: usize) ![]u8 {
    const path_z = try allocator.dupeZ(u8, path);
    defer allocator.free(path_z);

    const fp = c.fopen(path_z.ptr, "rb");
    if (fp == null) return error.FileNotFound;
    defer _ = c.fclose(fp);

    if (c.fseek(fp, 0, c.SEEK_END) != 0) return error.FileNotFound;
    const end_pos = c.ftell(fp);
    if (end_pos < 0) return error.FileNotFound;
    if (@as(usize, @intCast(end_pos)) > max_bytes) return error.FileTooBig;
    if (c.fseek(fp, 0, c.SEEK_SET) != 0) return error.FileNotFound;

    const bytes = try allocator.alloc(u8, @intCast(end_pos));
    errdefer allocator.free(bytes);
    const read_len = c.fread(bytes.ptr, 1, bytes.len, fp);
    if (read_len != bytes.len) return error.FileNotFound;
    return bytes;
}

fn makePathRecursive(allocator: std.mem.Allocator, raw_path: []const u8) !void {
    if (raw_path.len == 0) return;

    var current: std.ArrayListUnmanaged(u8) = .empty;
    defer current.deinit(allocator);

    if (raw_path[0] == '/') {
        try current.append(allocator, '/');
    }

    var parts = std.mem.splitScalar(u8, raw_path, '/');
    while (parts.next()) |part| {
        if (part.len == 0) continue;
        if (current.items.len > 0 and current.items[current.items.len - 1] != '/') {
            try current.append(allocator, '/');
        }
        try current.appendSlice(allocator, part);
        const path_z = try allocator.dupeZ(u8, current.items);
        defer allocator.free(path_z);
        if (c.mkdir(path_z.ptr, 0o755) != 0) {
            if (c.access(path_z.ptr, 0) != 0) return error.FileNotFound;
        }
    }
}

fn writeFilePath(allocator: std.mem.Allocator, path: []const u8, data: []const u8) !void {
    const path_z = try allocator.dupeZ(u8, path);
    defer allocator.free(path_z);

    const fp = c.fopen(path_z.ptr, "wb");
    if (fp == null) return error.FileNotFound;
    defer _ = c.fclose(fp);

    if (data.len != 0) {
        const wrote = c.fwrite(data.ptr, 1, data.len, fp);
        if (wrote != data.len) return error.FileNotFound;
    }
}

fn loadDllBytes(allocator: std.mem.Allocator, raw_path: []const u8) !struct { []u8, []u8 } {
    const candidates = try pathCandidates(allocator, raw_path);
    defer {
        for (candidates) |item| allocator.free(item);
        allocator.free(candidates);
    }

    for (candidates) |candidate| {
        const bytes = readFileAlloc(allocator, candidate, 16 * 1024 * 1024) catch continue;
        const chosen = try allocator.dupe(u8, candidate);
        return .{ bytes, chosen };
    }
    return error.FileNotFound;
}

fn fakeIconHandle(index: usize) usize {
    return 0xD110_0000 + index + 1;
}

fn writeStatusLine(comptime fmt: []const u8, args: anytype) void {
    runtime_abi.common.writeLine(fmt, args);
}

pub fn dumpDllResources(allocator: std.mem.Allocator, raw_path: []const u8, out_dir: []const u8) !void {
    const loaded = try loadDllBytes(allocator, raw_path);
    const bytes = loaded[0];
    const chosen_path = loaded[1];
    defer allocator.free(bytes);
    defer allocator.free(chosen_path);

    const pe = try parsePe(allocator, bytes);
    defer deinitPe(allocator, pe);

    try makePathRecursive(allocator, out_dir);

    var manifest: std.ArrayListUnmanaged(u8) = .empty;
    defer manifest.deinit(allocator);

    {
        const line = try std.fmt.allocPrint(allocator, "dll={s}\n", .{chosen_path});
        defer allocator.free(line);
        try manifest.appendSlice(allocator, line);
    }

    const root_offset = try resourceRootOffset(pe);
    const interesting_types = [_]u32{ win.rt_group_icon, win.rt_icon };
    for (interesting_types) |type_id| {
        const type_dir = try findResourceSubdirById(bytes, root_offset, root_offset, type_id);
        if (type_dir == null) continue;

        const count = try resourceEntryCount(bytes, type_dir.?);
        {
            const line = try std.fmt.allocPrint(allocator, "type={d} count={d}\n", .{ type_id, count });
            defer allocator.free(line);
            try manifest.appendSlice(allocator, line);
        }
        for (0..count) |i| {
            const entry_offset = type_dir.? + 16 + (i * 8);
            const resource_id = (try resourceEntryId(bytes, entry_offset)) orelse @as(u32, @intCast(i));
            const data = try resourceDataForEntry(bytes, pe, root_offset, entry_offset);
            const file_name = try std.fmt.allocPrint(allocator, "type-{d}_id-{d}_lang-{d}.bin", .{
                type_id,
                resource_id,
                data.lang_id,
            });
            defer allocator.free(file_name);

            const out_path = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ out_dir, file_name });
            defer allocator.free(out_path);
            try writeFilePath(allocator, out_path, data.bytes);
            const line = try std.fmt.allocPrint(allocator, "  id={d} lang={d} codepage={d} size={d} file={s}\n", .{
                resource_id,
                data.lang_id,
                data.codepage,
                data.size,
                file_name,
            });
            defer allocator.free(line);
            try manifest.appendSlice(allocator, line);
        }
    }

    const manifest_path = try std.fmt.allocPrint(allocator, "{s}/manifest.txt", .{out_dir});
    defer allocator.free(manifest_path);
    try writeFilePath(allocator, manifest_path, manifest.items);

    writeStatusLine("[runtime-abi][dll] unpacked path={s} out={s}\n", .{ chosen_path, out_dir });
}

pub fn dllIconCountA(path_z: [*:0]const u8) c_int {
    const path = std.mem.span(path_z);
    runtime_abi.common.acquire();
    defer runtime_abi.common.release();
    runtime_abi.common.noteValidation();

    const allocator = std.heap.page_allocator;
    const loaded = loadDllBytes(allocator, path) catch |err| {
        writeStatusLine("[runtime-abi][dll] open failed path={s} err={s}\n", .{ path, @errorName(err) });
        return 0;
    };
    const bytes = loaded[0];
    const chosen_path = loaded[1];
    defer allocator.free(bytes);
    defer allocator.free(chosen_path);

    const pe = parsePe(allocator, bytes) catch |err| {
        runtime_abi.common.violation("dll-translator", "parse_pe", "path={s} err={s}", .{ chosen_path, @errorName(err) });
        return 0;
    };
    defer deinitPe(allocator, pe);

    const count = groupIconCount(bytes, pe) catch |err| {
        runtime_abi.common.violation("dll-translator", "group_icon_count", "path={s} err={s}", .{ chosen_path, @errorName(err) });
        return 0;
    };
    writeStatusLine("[runtime-abi][dll] path={s} group_icons={d}\n", .{ chosen_path, count });
    return @intCast(count);
}

pub fn dllExtractIconA(path_z: [*:0]const u8, index: c_int) usize {
    const path = std.mem.span(path_z);
    runtime_abi.common.acquire();
    defer runtime_abi.common.release();
    runtime_abi.common.noteValidation();

    if (index < 0) {
        const count = dllIconCountA(path_z);
        return @intCast(@max(count, 0));
    }

    const allocator = std.heap.page_allocator;
    const loaded = loadDllBytes(allocator, path) catch |err| {
        writeStatusLine("[runtime-abi][dll] extract open failed path={s} err={s}\n", .{ path, @errorName(err) });
        return 0;
    };
    const bytes = loaded[0];
    const chosen_path = loaded[1];
    defer allocator.free(bytes);
    defer allocator.free(chosen_path);

    const pe = parsePe(allocator, bytes) catch |err| {
        runtime_abi.common.violation("dll-translator", "parse_pe", "path={s} err={s}", .{ chosen_path, @errorName(err) });
        return 0;
    };
    defer deinitPe(allocator, pe);

    validateIconIndex(bytes, pe, @intCast(index)) catch |err| {
        writeStatusLine("[runtime-abi][dll] icon missing path={s} index={d} err={s}\n", .{ chosen_path, index, @errorName(err) });
        return 0;
    };

    const handle = fakeIconHandle(@intCast(index));
    writeStatusLine("[runtime-abi][dll] extracted icon path={s} index={d} handle=0x{x}\n", .{ chosen_path, index, handle });
    return handle;
}

fn utf16ZToUtf8Alloc(allocator: std.mem.Allocator, wide: [*:0]const u16) ![]u8 {
    const wide_slice = std.mem.sliceTo(wide, 0);
    return try std.unicode.utf16LeToUtf8Alloc(allocator, wide_slice);
}

pub fn dllIconCountW(path_z: [*:0]const u16) c_int {
    const allocator = std.heap.page_allocator;
    const utf8 = utf16ZToUtf8Alloc(allocator, path_z) catch return 0;
    defer allocator.free(utf8);
    return dllIconCountA(@ptrCast(utf8.ptr));
}

pub fn dllExtractIconW(path_z: [*:0]const u16, index: c_int) usize {
    const allocator = std.heap.page_allocator;
    const utf8 = utf16ZToUtf8Alloc(allocator, path_z) catch return 0;
    defer allocator.free(utf8);
    return dllExtractIconA(@ptrCast(utf8.ptr), index);
}

test "moricons.dll reports icon groups when present" {
    const allocator = std.testing.allocator;
    const loaded = loadDllBytes(allocator, "moricons.dll") catch return;
    const bytes = loaded[0];
    const chosen_path = loaded[1];
    defer allocator.free(bytes);
    defer allocator.free(chosen_path);
    const pe = try parsePe(allocator, bytes);
    defer deinitPe(allocator, pe);
    try std.testing.expect((try groupIconCount(bytes, pe)) > 0);
}
