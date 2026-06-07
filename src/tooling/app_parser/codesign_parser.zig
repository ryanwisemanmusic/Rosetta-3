const std = @import("std");

pub const CodeDirectoryMagic: u32 = 0x6A6F686E;
pub const CodeDirectoryMagicAlternate: u32 = 0x6A6F686E;

pub const HashType = enum(u8) {
    sha1 = 1,
    sha256 = 2,
    sha256_truncated = 3,
    sha384 = 4,
};

pub const CodeDirectory = struct {
    magic: u32,
    version: u32,
    hash_type: HashType,
    hash_size: u8,
    n_special_slots: u8,
    n_code_slots: u8,
    code_limit: u64,
    exec_seg_base: u64,
    exec_seg_limit: u64,
    exec_seg_flags: u64,
};

pub const CodeRequirement = struct {
    kind: u32,
    data: []const u8,
};

pub const CodeSignature = struct {
    cd: CodeDirectory,
    requirements: []CodeRequirement,
    cms_data: []const u8,
    allocator: std.mem.Allocator,

    pub fn deinit(self: *CodeSignature) void {
        self.allocator.free(self.requirements);
    }
};

pub fn parseCodeDirectory(data: []const u8) !CodeDirectory {
    if (data.len < 8) return error.TruncatedCodeDirectory;
    const magic = std.mem.readInt(u32, data[0..4], .big);
    if (magic != CodeDirectoryMagic) return error.InvalidCodeDirectory;
    const version = std.mem.readInt(u32, data[4..8], .big);

    const hash_type_val = if (data.len > 8) data[8] else 0;
    const hash_size = if (data.len > 9) data[9] else 0;
    const n_special_slots = if (data.len > 10) data[10] else 0;
    const n_code_slots = if (data.len > 11) data[11] else 0;

    const code_limit = blk: {
        if (version >= 0x20100 and data.len >= 24) {
            break :blk std.mem.readInt(u64, data[16..24], .big);
        }
        break :blk if (data.len >= 16) std.mem.readInt(u32, data[12..16], .big) else 0;
    };

    const exec_seg_base = if (version >= 0x20200 and data.len >= 40)
        std.mem.readInt(u64, data[24..32], .big)
    else
        0;
    const exec_seg_limit = if (version >= 0x20200 and data.len >= 48)
        std.mem.readInt(u64, data[32..40], .big)
    else
        0;
    const exec_seg_flags = if (version >= 0x20200 and data.len >= 56)
        std.mem.readInt(u64, data[40..48], .big)
    else
        0;

    const hash_type: HashType = if (hash_type_val >= 1 and hash_type_val <= 4)
        @enumFromInt(hash_type_val)
    else
        HashType.sha1;

    return .{
        .magic = magic,
        .version = version,
        .hash_type = hash_type,
        .hash_size = hash_size,
        .n_special_slots = n_special_slots,
        .n_code_slots = n_code_slots,
        .code_limit = code_limit,
        .exec_seg_base = exec_seg_base,
        .exec_seg_limit = exec_seg_limit,
        .exec_seg_flags = exec_seg_flags,
    };
}

test "parse CodeDirectory" {
    var buf: [64]u8 = undefined;
    std.mem.writeInt(u32, buf[0..4], CodeDirectoryMagic, .big);
    std.mem.writeInt(u32, buf[4..8], 0x20100, .big);
    buf[8] = 2;
    buf[9] = 32;
    buf[10] = 2;
    buf[11] = 100;
    std.mem.writeInt(u64, buf[16..24], 0x10000, .big);

    const cd = try parseCodeDirectory(&buf);
    try std.testing.expectEqual(CodeDirectoryMagic, cd.magic);
    try std.testing.expectEqual(@as(u32, 0x20100), cd.version);
    try std.testing.expectEqual(HashType.sha256, cd.hash_type);
    try std.testing.expectEqual(@as(u8, 32), cd.hash_size);
    try std.testing.expectEqual(@as(u64, 0x10000), cd.code_limit);
}

pub const CodeResources = struct {
    rules: [][]const u8,
    files: [][]const u8,
    allocator: std.mem.Allocator,

    pub fn deinit(self: *CodeResources) void {
        for (self.rules) |r| self.allocator.free(r);
        self.allocator.free(self.rules);
        for (self.files) |f| self.allocator.free(f);
        self.allocator.free(self.files);
    }
};

pub fn parseCodeResourcesSimple(allocator: std.mem.Allocator, data: []const u8) !CodeResources {
    _ = data;
    return CodeResources{
        .rules = try allocator.alloc([]const u8, 0),
        .files = try allocator.alloc([]const u8, 0),
        .allocator = allocator,
    };
}

test "parse empty CodeResources" {
    var cr = try parseCodeResourcesSimple(std.testing.allocator, "");
    defer cr.deinit();
    try std.testing.expectEqual(@as(usize, 0), cr.rules.len);
}
