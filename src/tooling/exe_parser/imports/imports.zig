const std = @import("std");
const fmt = @import("../pe_format.zig");
const parser = @import("../pe_parser.zig");

pub const ImportDescriptor = struct {
    dll_name: []const u8,
    function_name: []const u8,
    iat_rva: u32,
};

pub const ImportDirectory = struct {
    descriptors: []ImportDescriptor,
};

pub const ParseError = error{
    ImportDirectoryNotFound,
    TruncatedImportTable,
    RvaResolutionFailed,
    OutOfMemory,
};

fn readU16(bytes: []const u8, offset: usize) ParseError!u16 {
    if (offset + 2 > bytes.len) return error.TruncatedImportTable;
    return @as(u16, bytes[offset]) |
        (@as(u16, bytes[offset + 1]) << 8);
}

fn readU32(bytes: []const u8, offset: usize) ParseError!u32 {
    if (offset + 4 > bytes.len) return error.TruncatedImportTable;
    return @as(u32, bytes[offset]) |
        (@as(u32, bytes[offset + 1]) << 8) |
        (@as(u32, bytes[offset + 2]) << 16) |
        (@as(u32, bytes[offset + 3]) << 24);
}

fn rvaToOffset(image: *const parser.Image, rva: u32) ParseError!u32 {
    for (image.sections) |section| {
        const section_end = section.virtual_address + section.raw_size;
        if (rva >= section.virtual_address and rva < section_end) {
            if (section.raw_offset == 0 and section.raw_size == 0) continue;
            return section.raw_offset + (rva - section.virtual_address);
        }
    }
    return error.RvaResolutionFailed;
}

fn countImportsInThunkArray(bytes: []const u8, ilt_offset: u32) u32 {
    var count: u32 = 0;
    var off = ilt_offset;
    while (off + 4 <= bytes.len) {
        const thunk = readU32(bytes, off) catch break;
        if (thunk == 0) break;
        if ((thunk & fmt.import.ordinal_flag32) == 0) {
            count += 1;
        }
        off += 4;
    }
    return count;
}

fn parseStringAtOffset(bytes: []const u8, offset: usize) []const u8 {
    var end = offset;
    while (end < bytes.len and bytes[end] != 0) : (end += 1) {}
    return bytes[offset..end];
}

pub fn parseImportDirectory(allocator: std.mem.Allocator, bytes: []const u8, image: *const parser.Image) ParseError!ImportDirectory {
    const pe_offset = try readU32(bytes, 0x3C);
    const optional_offset = pe_offset + 24;
    const optional_magic = try readU16(bytes, optional_offset);

    const num_rva_sizes_off: u32 = switch (optional_magic) {
        fmt.coff.optional_magic_pe32 => @intCast(fmt.opt32.number_of_rva_and_sizes_off),
        fmt.coff.optional_magic_pe32_plus => @intCast(fmt.opt64.number_of_rva_and_sizes_off),
        else => return error.ImportDirectoryNotFound,
    };
    const data_dir_off: u32 = switch (optional_magic) {
        fmt.coff.optional_magic_pe32 => @intCast(fmt.opt32.data_dir_off),
        fmt.coff.optional_magic_pe32_plus => @intCast(fmt.opt64.data_dir_off),
        else => return error.ImportDirectoryNotFound,
    };

    const num_data_dirs = try readU32(bytes, optional_offset + num_rva_sizes_off);
    if (fmt.data_dir.entry_import >= num_data_dirs) return error.ImportDirectoryNotFound;

    const import_dir_rva = try readU32(bytes, optional_offset + data_dir_off + fmt.data_dir.entry_import * 8);
    if (import_dir_rva == 0) return error.ImportDirectoryNotFound;

    const import_dir_off = try rvaToOffset(image, import_dir_rva);

    var total_func_imports: u32 = 0;
    var desc_off = import_dir_off;
    while (desc_off + fmt.import.descriptor_size <= bytes.len) {
        const oft = readU32(bytes, desc_off) catch break;
        if (oft == 0) break;
        const ilt_actual = if (oft != 0) oft else readU32(bytes, desc_off + 16) catch break;
        const ilt_off = rvaToOffset(image, ilt_actual) catch break;
        total_func_imports += countImportsInThunkArray(bytes, ilt_off);
        desc_off += fmt.import.descriptor_size;
    }

    const descriptors = try allocator.alloc(ImportDescriptor, total_func_imports);
    errdefer allocator.free(descriptors);

    var written: u32 = 0;
    desc_off = import_dir_off;
    while (desc_off + fmt.import.descriptor_size <= bytes.len and written < total_func_imports) {
        const oft = readU32(bytes, desc_off) catch break;
        if (oft == 0) break;
        const ilt_rva = oft;
        const iat_rva = readU32(bytes, desc_off + 16) catch break;
        const name_rva = readU32(bytes, desc_off + 12) catch break;

        const ilt_actual = if (ilt_rva != 0) ilt_rva else iat_rva;
        const ilt_off = rvaToOffset(image, ilt_actual) catch break;
        const dll_name = parseStringAtOffset(bytes, try rvaToOffset(image, name_rva));

        var thunk_off = ilt_off;
        var func_index: u32 = 0;
        while (thunk_off + 4 <= bytes.len and written < total_func_imports) {
            const thunk = readU32(bytes, thunk_off) catch break;
            if (thunk == 0) break;

            if ((thunk & fmt.import.ordinal_flag32) != 0) {
                thunk_off += 4;
                func_index += 1;
                continue;
            }

            const func_name_off = rvaToOffset(image, thunk) catch {
                thunk_off += 4;
                func_index += 1;
                continue;
            };
            const func_name = parseStringAtOffset(bytes, func_name_off + 2);

            if (func_name.len > 0) {
                const dll_copy = try allocator.alloc(u8, dll_name.len);
                @memcpy(dll_copy, dll_name);
                const func_copy = try allocator.alloc(u8, func_name.len);
                @memcpy(func_copy, func_name);
                descriptors[written] = .{
                    .dll_name = dll_copy,
                    .function_name = func_copy,
                    .iat_rva = iat_rva + func_index * 4,
                };
                written += 1;
            }

            thunk_off += 4;
            func_index += 1;
        }

        desc_off += fmt.import.descriptor_size;
    }

    if (written < total_func_imports) {
        return .{ .descriptors = try allocator.realloc(descriptors, written) };
    }

    return .{ .descriptors = descriptors };
}
