const std = @import("std");

pub const ResourceType = struct {
    rsrc_type: u32,
    id: i16,
    name: []const u8,
    data: []const u8,
};

pub const ResourceFork = struct {
    types: []ResourceType,
    allocator: std.mem.Allocator,

    pub fn deinit(self: *ResourceFork) void {
        for (self.types) |*t| {
            self.allocator.free(t.name);
            self.allocator.free(t.data);
        }
        self.allocator.free(self.types);
    }

    pub fn findType(self: ResourceFork, rsrc_type: u32) ?[]const ResourceType {
        var result: ?[]const ResourceType = null;
        for (self.types, 0..) |t, i| {
            if (t.rsrc_type == rsrc_type) {
                const slice = self.types[i..];
                _ = slice;
                result = self.types[i..];
                break;
            }
        }
        return result;
    }

    pub fn findByName(self: ResourceFork, name: []const u8) ?ResourceType {
        for (self.types) |t| {
            if (std.mem.eql(u8, t.name, name)) return t;
        }
        return null;
    }
};

pub const ResourceHeader = packed struct {
    data_offset: u32,
    map_offset: u32,
    data_len: u32,
    map_len: u32,
};

pub const ResourceMapHeader = extern struct {
    reserved: [16]u8,
    reserved2: [4]u8,
    type_list_offset: u16,
    name_list_offset: u16,
};

pub fn parseResourceFork(allocator: std.mem.Allocator, data: []const u8) !ResourceFork {
    if (data.len < 16) return error.TruncatedResourceFork;

    const map_offset: usize = @intCast(std.mem.readInt(u32, data[4..8], .big));
    const data_offset: usize = @intCast(std.mem.readInt(u32, data[0..4], .big));

    if (map_offset + 4 + 4 + 4 > data.len) return error.TruncatedResourceMap;

    const type_list_offset: usize = map_offset + std.mem.readInt(u16, data[map_offset + 20 ..][0..2], .big);
    const name_list_offset: usize = map_offset + std.mem.readInt(u16, data[map_offset + 22 ..][0..2], .big);

    if (type_list_offset + 2 > data.len) return error.TruncatedTypeList;

    const type_count = std.mem.readInt(u16, data[type_list_offset..][0..2], .big);

    var types: std.ArrayList(ResourceType) = .empty;
    errdefer {
        for (types.items) |*t| {
            allocator.free(t.name);
            allocator.free(t.data);
        }
        types.deinit(allocator);
    }

    var type_pos: usize = type_list_offset + 2;
    for (0..type_count) |_| {
        if (type_pos + 8 > data.len) break;
        const rsrc_type = std.mem.readInt(u32, data[type_pos..][0..4], .big);
        const ref_count = std.mem.readInt(u16, data[type_pos + 4 ..][0..2], .big);
        const ref_offset = std.mem.readInt(u16, data[type_pos + 6 ..][0..2], .big);

        const base_ref_offset: usize = type_list_offset + ref_offset;
        var ref_pos = base_ref_offset;

        for (0..ref_count) |_| {
            if (ref_pos + 12 > data.len) break;
            const rsrc_id: i16 = @bitCast(std.mem.readInt(u16, data[ref_pos..][0..2], .big));
            const name_offset: i16 = @bitCast(std.mem.readInt(u16, data[ref_pos + 2 ..][0..2], .big));
            const rsrc_data_offset = std.mem.readInt(u32, data[ref_pos + 4 ..][0..4], .big);
            const rsrc_data_size = std.mem.readInt(u32, data[ref_pos + 8 ..][0..4], .big);

            var name: []const u8 = "";

            if (name_offset != -1) {
                const name_entry_offset = name_list_offset + @as(u16, @bitCast(name_offset));
                if (name_entry_offset + 1 < data.len) {
                    const name_len = data[name_entry_offset];
                    if (name_entry_offset + 1 + name_len <= data.len) {
                        name = data[name_entry_offset + 1 .. name_entry_offset + 1 + name_len];
                    }
                }
            }

            const actual_data_offset = data_offset + rsrc_data_offset;
            const rsrc_data = if (actual_data_offset + rsrc_data_size <= data.len)
                data[actual_data_offset .. actual_data_offset + rsrc_data_size]
            else
                data[0..0];

            const name_copy = try allocator.dupe(u8, name);
            errdefer allocator.free(name_copy);
            const data_copy = try allocator.dupe(u8, rsrc_data);
            errdefer allocator.free(data_copy);

            try types.append(allocator, .{
                .rsrc_type = rsrc_type,
                .id = rsrc_id,
                .name = name_copy,
                .data = data_copy,
            });

            ref_pos += 12;
        }

        type_pos += 8;
    }

    return ResourceFork{
        .types = try types.toOwnedSlice(allocator),
        .allocator = allocator,
    };
}

test "parse empty resource fork" {
    var buf: std.ArrayList(u8) = .empty;
    defer buf.deinit(std.testing.allocator);
    const W = std.testing.allocator;
    // ResourceHeader: data_offset(0), map_offset(16), data_len(0), map_len(0) — big endian
    {
        var be: [4]u8 = undefined;
        std.mem.writeInt(u32, &be, 0, .big);
        try buf.appendSlice(W, &be);
    }
    {
        var be: [4]u8 = undefined;
        std.mem.writeInt(u32, &be, 16, .big);
        try buf.appendSlice(W, &be);
    }
    {
        var be: [4]u8 = undefined;
        std.mem.writeInt(u32, &be, 0, .big);
        try buf.appendSlice(W, &be);
    }
    {
        var be: [4]u8 = undefined;
        std.mem.writeInt(u32, &be, 0, .big);
        try buf.appendSlice(W, &be);
    }
    // ResourceMapHeader: reserved(16 zeros), reserved2(4 zeros), type_list_offset, name_list_offset
    try buf.appendNTimes(W, 0, 24);
    {
        var be: [2]u8 = undefined;
        std.mem.writeInt(u16, &be, 24, .big);
        try buf.appendSlice(W, &be);
    }
    {
        var be: [2]u8 = undefined;
        std.mem.writeInt(u16, &be, 24, .big);
        try buf.appendSlice(W, &be);
    }
    // type_count = 0
    {
        var be: [2]u8 = undefined;
        std.mem.writeInt(u16, &be, 0, .big);
        try buf.appendSlice(W, &be);
    }

    var fork = try parseResourceFork(std.testing.allocator, buf.items);
    defer fork.deinit();
    try std.testing.expectEqual(@as(usize, 0), fork.types.len);
}
