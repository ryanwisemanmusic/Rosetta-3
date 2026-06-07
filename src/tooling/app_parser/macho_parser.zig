const std = @import("std");

pub const MH_MAGIC: u32 = 0xFEEDFACE;
pub const MH_CIGAM: u32 = 0xCEFAEDFE;
pub const MH_MAGIC_64: u32 = 0xFEEDFACF;
pub const MH_CIGAM_64: u32 = 0xCFFAEDFE;

pub const CPU_TYPE_I386: u32 = 7;
pub const CPU_TYPE_X86_64: u32 = 7 | 0x01000000;
pub const CPU_TYPE_ARM64: u32 = 12 | 0x01000000;

pub const MH_EXECUTE: u32 = 2;
pub const MH_DYLIB: u32 = 6;
pub const MH_BUNDLE: u32 = 8;

pub const LC_SEGMENT: u32 = 0x01;
pub const LC_SEGMENT_64: u32 = 0x19;
pub const LC_SYMTAB: u32 = 0x02;
pub const LC_DYSYMTAB: u32 = 0x0B;
pub const LC_LOAD_DYLIB: u32 = 0x0C;
pub const LC_UUID: u32 = 0x1B;
pub const LC_CODE_SIGNATURE: u32 = 0x1D;
pub const LC_SEGMENT_SPLIT_INFO: u32 = 0x1E;
pub const LC_REEXPORT_DYLIB: u32 = 0x1F | 0x80000000;
pub const LC_LAZY_LOAD_DYLIB: u32 = 0x20;
pub const LC_ENCRYPTION_INFO: u32 = 0x21;
pub const LC_DYLD_INFO: u32 = 0x22;
pub const LC_DYLD_INFO_ONLY: u32 = 0x22 | 0x80000000;
pub const LC_LOAD_UPWARD_DYLIB: u32 = 0x23 | 0x80000000;
pub const LC_VERSION_MIN_MACOSX: u32 = 0x24;
pub const LC_VERSION_MIN_IPHONEOS: u32 = 0x25;
pub const LC_FUNCTION_STARTS: u32 = 0x26;
pub const LC_DYLD_EXPORTS_TRIE: u32 = 0x33;
pub const LC_SOURCE_VERSION: u32 = 0x2A;
pub const LC_MAIN: u32 = 0x28 | 0x80000000;
pub const LC_DATA_IN_CODE: u32 = 0x29;
pub const LC_ENCRYPTION_INFO_64: u32 = 0x2C;
pub const LC_LINKER_OPTION: u32 = 0x2D;
pub const LC_RPATH: u32 = 0x1C | 0x80000000;
pub const LC_BUILD_VERSION: u32 = 0x32;

pub const MachHeader32 = packed struct {
    magic: u32,
    cputype: u32,
    cpusubtype: u32,
    filetype: u32,
    ncmds: u32,
    sizeofcmds: u32,
    flags: u32,
};

pub const MachHeader64 = packed struct {
    magic: u32,
    cputype: u32,
    cpusubtype: u32,
    filetype: u32,
    ncmds: u32,
    sizeofcmds: u32,
    flags: u32,
    reserved: u32,
};

pub const LoadCommand = packed struct {
    cmd: u32,
    cmdsize: u32,
};

pub const SegmentCommand32 = extern struct {
    cmd: u32,
    cmdsize: u32,
    segname: [16]u8,
    vmaddr: u32,
    vmsize: u32,
    fileoff: u32,
    filesize: u32,
    maxprot: u32,
    initprot: u32,
    nsects: u32,
    flags: u32,
};

pub const SegmentCommand64 = extern struct {
    cmd: u32,
    cmdsize: u32,
    segname: [16]u8,
    vmaddr: u64,
    vmsize: u64,
    fileoff: u64,
    filesize: u64,
    maxprot: u32,
    initprot: u32,
    nsects: u32,
    flags: u32,
};

pub const Section32 = extern struct {
    sectname: [16]u8,
    segname: [16]u8,
    addr: u32,
    size: u32,
    offset: u32,
    alignment: u32,
    reloff: u32,
    nreloc: u32,
    flags: u32,
    reserved1: u32,
    reserved2: u32,
};

pub const Section64 = extern struct {
    sectname: [16]u8,
    segname: [16]u8,
    addr: u64,
    size: u64,
    offset: u32,
    alignment: u32,
    reloff: u32,
    nreloc: u32,
    flags: u32,
    reserved1: u32,
    reserved2: u32,
    reserved3: u32,
};

pub const DyLib = struct {
    name: []const u8,
    timestamp: u32,
    current_version: u32,
    compat_version: u32,
};

pub const UuidCommand = packed struct {
    cmd: u32,
    cmdsize: u32,
    uuid: [16]u8,
};

pub const LinkEditData = packed struct {
    cmd: u32,
    cmdsize: u32,
    dataoff: u32,
    datasize: u32,
};

pub const EntryPoint = packed struct {
    cmd: u32,
    cmdsize: u32,
    entryoff: u64,
    stacksize: u64,
};

pub const VersionMin = packed struct {
    cmd: u32,
    cmdsize: u32,
    version: u32,
    sdk: u32,
};

pub const BuildVersion = packed struct {
    cmd: u32,
    cmdsize: u32,
    platform: u32,
    minos: u32,
    sdk: u32,
    ntools: u32,
};

pub const BuildTool = packed struct {
    tool: u32,
    version: u32,
};

pub const EncryptionInfo32 = packed struct {
    cmd: u32,
    cmdsize: u32,
    cryptoff: u32,
    cryptsize: u32,
    cryptid: u32,
};

pub const EncryptionInfo64 = packed struct {
    cmd: u32,
    cmdsize: u32,
    cryptoff: u32,
    cryptsize: u32,
    cryptid: u32,
    pad: u32,
};

pub const MachSegment = struct {
    name: []const u8,
    vmaddr: u64,
    vmsize: u64,
    fileoff: u64,
    filesize: u64,
    protections: u32,
    sections: []MachSection,
};

pub const MachSection = struct {
    sectname: []const u8,
    segname: []const u8,
    addr: u64,
    size: u64,
    offset: u32,
    flags: u32,
};

pub const MachDylib = struct {
    name: []const u8,
    current_version: u32,
    compat_version: u32,
};

pub const MachImage = struct {
    is_64: bool,
    is_32_bit: bool,
    header: MachHeader32,
    cputype: u32,
    cpusubtype: u32,
    filetype: u32,
    segments: []MachSegment,
    dylibs: []MachDylib,
    uuid: ?[16]u8,
    entry_point: u64,
    code_signature_offset: u32,
    code_signature_size: u32,
    allocator: std.mem.Allocator,

    pub fn deinit(self: *MachImage) void {
        for (self.segments) |*seg| {
            for (seg.sections) |*s| {
                self.allocator.free(s.sectname);
                self.allocator.free(s.segname);
            }
            self.allocator.free(seg.sections);
            self.allocator.free(seg.name);
        }
        self.allocator.free(self.segments);
        for (self.dylibs) |*d| {
            self.allocator.free(d.name);
        }
        self.allocator.free(self.dylibs);
    }
};

pub fn parseMachO(allocator: std.mem.Allocator, data: []const u8) !MachImage {
    if (data.len < 4) return error.TruncatedMachO;
    const magic = std.mem.readInt(u32, data[0..4], .little);
    const is_64 = magic == MH_MAGIC_64 or magic == MH_CIGAM_64;
    const is_32 = magic == MH_MAGIC or magic == MH_CIGAM;
    if (!is_32 and !is_64) return error.NotMachO;

    const endian: std.builtin.Endian = if (magic == MH_MAGIC or magic == MH_MAGIC_64) .little else .big;

    const header_size: usize = if (is_64) @sizeOf(MachHeader64) else @sizeOf(MachHeader32);
    if (data.len < header_size) return error.TruncatedMachO;

    const header32 = blk: {
        const cpu = std.mem.readInt(u32, data[4..8], .little);
        const sub = std.mem.readInt(u32, data[8..12], .little);
        const ftype = std.mem.readInt(u32, data[12..16], .little);
        const ncmds = std.mem.readInt(u32, data[16..20], .little);
        const scmds = std.mem.readInt(u32, data[20..24], .little);
        const flags = std.mem.readInt(u32, data[24..28], .little);
        _ = if (is_64) std.mem.readInt(u32, data[28..32], .little) else @as(u32, 0);
        break :blk MachHeader32{
            .magic = magic,
            .cputype = cpu,
            .cpusubtype = sub,
            .filetype = ftype,
            .ncmds = ncmds,
            .sizeofcmds = scmds,
            .flags = flags,
        };
    };

    var segments: std.ArrayList(MachSegment) = .empty;
    errdefer {
        for (segments.items) |*s| {
            allocator.free(s.name);
            for (s.sections) |*sec| {
                allocator.free(sec.sectname);
                allocator.free(sec.segname);
            }
            allocator.free(s.sections);
        }
        segments.deinit(allocator);
    }

    var dylibs: std.ArrayList(MachDylib) = .empty;
    errdefer {
        for (dylibs.items) |*d| allocator.free(d.name);
        dylibs.deinit(allocator);
    }

    var uuid: ?[16]u8 = null;
    var entry_point: u64 = 0;
    var code_signature_offset: u32 = 0;
    var code_signature_size: u32 = 0;

    var pos: usize = header_size;
    const cmds_end = pos + header32.sizeofcmds;

    for (0..header32.ncmds) |_| {
        if (pos + 8 > data.len) break;
        const cmd = std.mem.readInt(u32, data[pos + 0 ..][0..4], endian);
        const cmdsize = std.mem.readInt(u32, data[pos + 4 ..][0..4], endian);
        if (cmdsize < 8 or pos + cmdsize > data.len) break;

        switch (cmd) {
            LC_SEGMENT => {
                const seg_name_end = std.mem.indexOfScalar(u8, data[pos + 8 .. pos + 24], 0) orelse 16;
                const segname = try allocator.dupe(u8, data[pos + 8 .. pos + 8 + seg_name_end]);
                const vmaddr = std.mem.readInt(u32, data[pos + 24 ..][0..4], endian);
                const vmsize = std.mem.readInt(u32, data[pos + 28 ..][0..4], endian);
                const fileoff = std.mem.readInt(u32, data[pos + 32 ..][0..4], endian);
                const filesize = std.mem.readInt(u32, data[pos + 36 ..][0..4], endian);
                const maxprot = std.mem.readInt(u32, data[pos + 40 ..][0..4], endian);
                const nsects = std.mem.readInt(u32, data[pos + 48 ..][0..4], endian);

                var sections: std.ArrayList(MachSection) = .empty;
                errdefer {
                    for (sections.items) |*s| {
                        allocator.free(s.sectname);
                        allocator.free(s.segname);
                    }
                    sections.deinit(allocator);
                }

                var sec_pos = pos + 56;
                for (0..nsects) |_| {
                    if (sec_pos + 68 > data.len) break;
                    const s_name_end = std.mem.indexOfScalar(u8, data[sec_pos .. sec_pos + 16], 0) orelse 16;
                    const g_name_end = std.mem.indexOfScalar(u8, data[sec_pos + 16 .. sec_pos + 32], 0) orelse 16;
                    const sectname = try allocator.dupe(u8, data[sec_pos .. sec_pos + s_name_end]);
                    const segname2 = try allocator.dupe(u8, data[sec_pos + 16 .. sec_pos + 16 + g_name_end]);
                    try sections.append(allocator, .{
                        .sectname = sectname,
                        .segname = segname2,
                        .addr = std.mem.readInt(u32, data[sec_pos + 32 ..][0..4], endian),
                        .size = std.mem.readInt(u32, data[sec_pos + 36 ..][0..4], endian),
                        .offset = std.mem.readInt(u32, data[sec_pos + 40 ..][0..4], endian),
                        .flags = std.mem.readInt(u32, data[sec_pos + 48 ..][0..4], endian),
                    });
                    sec_pos += 68;
                }

                try segments.append(allocator, .{
                    .name = segname,
                    .vmaddr = vmaddr,
                    .vmsize = vmsize,
                    .fileoff = fileoff,
                    .filesize = filesize,
                    .protections = maxprot,
                    .sections = try sections.toOwnedSlice(allocator),
                });
            },
            LC_SEGMENT_64 => {
                const seg_name_end = std.mem.indexOfScalar(u8, data[pos + 8 .. pos + 24], 0) orelse 16;
                const segname = try allocator.dupe(u8, data[pos + 8 .. pos + 8 + seg_name_end]);
                const vmaddr = std.mem.readInt(u64, data[pos + 24 ..][0..8], endian);
                const vmsize = std.mem.readInt(u64, data[pos + 32 ..][0..8], endian);
                const fileoff = std.mem.readInt(u64, data[pos + 40 ..][0..8], endian);
                const filesize = std.mem.readInt(u64, data[pos + 48 ..][0..8], endian);
                const initprot = std.mem.readInt(u32, data[pos + 60 ..][0..4], endian);
                const nsects = std.mem.readInt(u32, data[pos + 64 ..][0..4], endian);

                var sections: std.ArrayList(MachSection) = .empty;
                errdefer {
                    for (sections.items) |*s| {
                        allocator.free(s.sectname);
                        allocator.free(s.segname);
                    }
                    sections.deinit(allocator);
                }

                var sec_pos = pos + 72;
                for (0..nsects) |_| {
                    if (sec_pos + 80 > data.len) break;
                    const s_name_end = std.mem.indexOfScalar(u8, data[sec_pos .. sec_pos + 16], 0) orelse 16;
                    const g_name_end = std.mem.indexOfScalar(u8, data[sec_pos + 16 .. sec_pos + 32], 0) orelse 16;
                    const sectname = try allocator.dupe(u8, data[sec_pos .. sec_pos + s_name_end]);
                    const segname2 = try allocator.dupe(u8, data[sec_pos + 16 .. sec_pos + 16 + g_name_end]);
                    try sections.append(allocator, .{
                        .sectname = sectname,
                        .segname = segname2,
                        .addr = std.mem.readInt(u64, data[sec_pos + 32 ..][0..8], endian),
                        .size = std.mem.readInt(u64, data[sec_pos + 40 ..][0..8], endian),
                        .offset = std.mem.readInt(u32, data[sec_pos + 48 ..][0..4], endian),
                        .flags = std.mem.readInt(u32, data[sec_pos + 56 ..][0..4], endian),
                    });
                    sec_pos += 80;
                }

                try segments.append(allocator, .{
                    .name = segname,
                    .vmaddr = vmaddr,
                    .vmsize = vmsize,
                    .fileoff = fileoff,
                    .filesize = filesize,
                    .protections = initprot,
                    .sections = try sections.toOwnedSlice(allocator),
                });
            },
            LC_LOAD_DYLIB, LC_LAZY_LOAD_DYLIB, LC_LOAD_UPWARD_DYLIB, LC_REEXPORT_DYLIB => {
                const dylib_data = data[pos + 8 .. pos + cmdsize];
                if (dylib_data.len >= 12) {
                    const name_offset = std.mem.readInt(u32, dylib_data[8..12], endian);
                    const cur_ver = std.mem.readInt(u32, dylib_data[4..8], endian);
                    const compat_ver = std.mem.readInt(u32, dylib_data[8..12], endian);
                    if (name_offset < dylib_data.len) {
                        const name_end = std.mem.indexOfScalar(u8, dylib_data[name_offset..], 0) orelse (dylib_data.len - name_offset);
                        const name = try allocator.dupe(u8, dylib_data[name_offset..][0..name_end]);
                        try dylibs.append(allocator, .{
                            .name = name,
                            .current_version = cur_ver,
                            .compat_version = compat_ver,
                        });
                    }
                }
            },
            LC_UUID => {
                if (pos + 8 + 16 <= data.len) {
                    var uuid_buf: [16]u8 = undefined;
                    @memcpy(&uuid_buf, data[pos + 8 .. pos + 24]);
                    uuid = uuid_buf;
                }
            },
            LC_MAIN => {
                if (pos + 8 + 16 <= data.len) {
                    entry_point = std.mem.readInt(u64, data[pos + 8 ..][0..8], endian);
                }
            },
            LC_CODE_SIGNATURE => {
                if (pos + 8 + 8 <= data.len) {
                    code_signature_offset = std.mem.readInt(u32, data[pos + 8 ..][0..4], endian);
                    code_signature_size = std.mem.readInt(u32, data[pos + 12 ..][0..4], endian);
                }
            },
            else => {},
        }

        pos += cmdsize;
        if (pos >= cmds_end) break;
    }

    const is_32_bit = header32.cputype == CPU_TYPE_I386;
    return MachImage{
        .is_64 = is_64,
        .is_32_bit = is_32_bit,
        .header = header32,
        .cputype = header32.cputype,
        .cpusubtype = header32.cpusubtype,
        .filetype = header32.filetype,
        .segments = try segments.toOwnedSlice(allocator),
        .dylibs = try dylibs.toOwnedSlice(allocator),
        .uuid = uuid,
        .entry_point = entry_point,
        .code_signature_offset = code_signature_offset,
        .code_signature_size = code_signature_size,
        .allocator = allocator,
    };
}

fn bufferFromHex(s: []const u8) [16]u8 {
    var result: [16]u8 = undefined;
    for (0..16) |i| {
        const hi = std.fmt.charToDigit(s[i * 2], 16) catch unreachable;
        const lo = std.fmt.charToDigit(s[i * 2 + 1], 16) catch unreachable;
        result[i] = @as(u8, hi) << 4 | @as(u8, lo);
    }
    return result;
}

test "parse i386 Mach-O header" {
    var hdr = MachHeader32{
        .magic = MH_MAGIC,
        .cputype = CPU_TYPE_I386,
        .cpusubtype = 3,
        .filetype = MH_EXECUTE,
        .ncmds = 0,
        .sizeofcmds = 0,
        .flags = 0,
    };
    const bytes = std.mem.asBytes(&hdr);

    var image = try parseMachO(std.testing.allocator, bytes);
    defer image.deinit();
    try std.testing.expect(!image.is_64);
    try std.testing.expect(image.is_32_bit);
    try std.testing.expectEqual(MH_EXECUTE, image.filetype);
    try std.testing.expectEqual(@as(usize, 0), image.segments.len);
}

test "parse x86_64 Mach-O header" {
    var hdr = MachHeader64{
        .magic = MH_MAGIC_64,
        .cputype = CPU_TYPE_X86_64,
        .cpusubtype = 3,
        .filetype = MH_EXECUTE,
        .ncmds = 0,
        .sizeofcmds = 0,
        .flags = 0,
        .reserved = 0,
    };
    const bytes = std.mem.asBytes(&hdr);

    var image = try parseMachO(std.testing.allocator, bytes);
    defer image.deinit();
    try std.testing.expect(image.is_64);
    try std.testing.expect(!image.is_32_bit);
    try std.testing.expectEqual(MH_EXECUTE, image.filetype);
}

test "parse i386 bundle header" {
    var hdr = MachHeader32{
        .magic = MH_MAGIC,
        .cputype = CPU_TYPE_I386,
        .cpusubtype = 3,
        .filetype = MH_BUNDLE,
        .ncmds = 0,
        .sizeofcmds = 0,
        .flags = 0,
    };
    const bytes = std.mem.asBytes(&hdr);

    var image = try parseMachO(std.testing.allocator, bytes);
    defer image.deinit();
    try std.testing.expect(!image.is_64);
    try std.testing.expectEqual(MH_BUNDLE, image.filetype);
}

test "parse with segment and section" {
    var data: std.ArrayList(u8) = .empty;
    defer data.deinit(std.testing.allocator);

    var hdr = MachHeader32{
        .magic = MH_MAGIC,
        .cputype = CPU_TYPE_I386,
        .cpusubtype = 3,
        .filetype = MH_EXECUTE,
        .ncmds = 1,
        .sizeofcmds = @sizeOf(SegmentCommand32) + @sizeOf(Section32),
        .flags = 0,
    };
    data.appendSlice(std.testing.allocator, std.mem.asBytes(&hdr)) catch unreachable;

    var seg = SegmentCommand32{
        .cmd = LC_SEGMENT,
        .cmdsize = @sizeOf(SegmentCommand32) + @sizeOf(Section32),
        .segname = .{ '_', '_', 'T', 'E', 'X', 'T', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
        .vmaddr = 0x1000,
        .vmsize = 0x2000,
        .fileoff = 0,
        .filesize = 0x2000,
        .maxprot = 7,
        .initprot = 5,
        .nsects = 1,
        .flags = 0,
    };
    data.appendSlice(std.testing.allocator, std.mem.asBytes(&seg)) catch unreachable;

    var sec = Section32{
        .sectname = .{ '_', '_', 't', 'e', 'x', 't', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
        .segname = .{ '_', '_', 'T', 'E', 'X', 'T', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
        .addr = 0x1000,
        .size = 0x100,
        .offset = 0x1000,
        .alignment = 0,
        .reloff = 0,
        .nreloc = 0,
        .flags = 0x80000400,
        .reserved1 = 0,
        .reserved2 = 0,
    };
    data.appendSlice(std.testing.allocator, std.mem.asBytes(&sec)) catch unreachable;

    var image = try parseMachO(std.testing.allocator, data.items);
    defer image.deinit();
    try std.testing.expectEqual(@as(usize, 1), image.segments.len);
    try std.testing.expectEqualStrings("__TEXT", image.segments[0].name);
    try std.testing.expectEqual(@as(u64, 0x1000), image.segments[0].vmaddr);
    try std.testing.expectEqual(@as(usize, 1), image.segments[0].sections.len);
    try std.testing.expectEqualStrings("__text", image.segments[0].sections[0].sectname);
}

test "reject invalid magic" {
    const data = [_]u8{ 0, 0, 0, 0 };
    const result = parseMachO(std.testing.allocator, &data);
    try std.testing.expectError(error.NotMachO, result);
}
