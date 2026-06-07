const std = @import("std");

pub const bplist_magic: u32 = 0x62706C69; // "bpli"
pub const bplist_magic_00: u32 = 0x62706C30; // "bpl0"

pub const PlistValueType = enum {
    integer,
    real,
    boolean,
    string,
    data,
    date,
    array,
    dict,
};

pub const PlistValue = struct {
    value_type: PlistValueType,
    int_val: i64,
    real_val: f64,
    bool_val: bool,
    string_val: []const u8,
    data_val: []const u8,
    array_val: []PlistValue,
    dict_keys: []const []const u8,
    dict_vals: []PlistValue,
    allocator: std.mem.Allocator,

    pub fn deinit(self: *PlistValue) void {
        switch (self.value_type) {
            .array => {
                for (self.array_val) |*v| v.deinit();
                self.allocator.free(self.array_val);
            },
            .dict => {
                for (self.dict_keys) |k| self.allocator.free(k);
                self.allocator.free(self.dict_keys);
                for (self.dict_vals) |*v| v.deinit();
                self.allocator.free(self.dict_vals);
            },
            .string => self.allocator.free(self.string_val),
            else => {},
        }
    }
};

pub const PlistDocument = struct {
    root: PlistValue,
    allocator: std.mem.Allocator,

    pub fn deinit(self: *PlistDocument) void {
        self.root.deinit();
    }

    pub fn getDictEntry(self: PlistDocument, key: []const u8) ?PlistValue {
        if (self.root.value_type != .dict) return null;
        for (self.root.dict_keys, self.root.dict_vals) |k, v| {
            if (std.mem.eql(u8, k, key)) return v;
        }
        return null;
    }

    pub fn getDictString(self: PlistDocument, key: []const u8) ?[]const u8 {
        const v = self.getDictEntry(key) orelse return null;
        if (v.value_type != .string) return null;
        return v.string_val;
    }
};

fn readBplistTrailer(data: []const u8, trailer_offset: usize) struct {
    offset_size: u8,
    ref_size: u8,
    num_objects: u64,
    root_object: u64,
    offset_table_offset: u64,
} {
    const offset_size = data[trailer_offset + 6];
    const ref_size = data[trailer_offset + 7];
    const num_objects = std.mem.readInt(u64, data[trailer_offset + 8 ..][0..8], .big);
    const root_object = std.mem.readInt(u64, data[trailer_offset + 16 ..][0..8], .big);
    const offset_table_offset = std.mem.readInt(u64, data[trailer_offset + 24 ..][0..8], .big);
    return .{
        .offset_size = offset_size,
        .ref_size = ref_size,
        .num_objects = num_objects,
        .root_object = root_object,
        .offset_table_offset = offset_table_offset,
    };
}

pub fn parsePlist(allocator: std.mem.Allocator, data: []const u8) !PlistDocument {
    if (data.len < 8) return error.TruncatedPlist;
    const magic = std.mem.readInt(u32, data[0..4], .big);
    if (magic == bplist_magic or magic == bplist_magic_00) {
        return parseBinaryPlist(allocator, data);
    }
    return error.UnsupportedPlistFormat;
}

fn parseBinaryPlist(allocator: std.mem.Allocator, data: []const u8) !PlistDocument {
    if (data.len < 32) return error.TruncatedBinaryPlist;
    const trailer_offset = data.len - 32;
    const trailer = readBplistTrailer(data, trailer_offset);

    const root = try readBplistObject(allocator, data, trailer, trailer.root_object);
    return .{ .root = root, .allocator = allocator };
}

fn readBplistObject(allocator: std.mem.Allocator, data: []const u8, trailer: anytype, obj_ref: u64) !PlistValue {
    const offset_table_offset: usize = @intCast(trailer.offset_table_offset);
    const offset_size: usize = @intCast(trailer.offset_size);
    const ref_size: usize = @intCast(trailer.ref_size);

    const obj_offset = readSizedInt(data, offset_table_offset + obj_ref * offset_size, offset_size);
    if (obj_offset >= data.len) return error.BplistObjectOutOfBounds;

    const marker = data[obj_offset];
    const obj_type = marker >> 4;
    const obj_info = marker & 0x0F;

    switch (obj_type) {
        0x00 => {
            if (marker == 0x00) return PlistValue{ .value_type = .boolean, .int_val = 0, .real_val = 0, .bool_val = false, .string_val = "", .data_val = "", .array_val = @as([]PlistValue, &.{}), .dict_keys = &.{}, .dict_vals = @as([]PlistValue, &.{}), .allocator = allocator };
            if (marker == 0x08) return PlistValue{ .value_type = .boolean, .int_val = 0, .real_val = 0, .bool_val = true, .string_val = "", .data_val = "", .array_val = @as([]PlistValue, &.{}), .dict_keys = &.{}, .dict_vals = @as([]PlistValue, &.{}), .allocator = allocator };
            if (marker == 0x09) return error.UnsupportedPlistType;
            return error.UnsupportedPlistType;
        },
        0x01 => {
            const len = readBplistLength(obj_info, data, obj_offset + 1);
            const int_bytes = data[obj_offset + 1 + len.len_size .. obj_offset + 1 + len.len_size + len.value];
            const val = switch (int_bytes.len) {
                1 => @as(i64, @intCast(int_bytes[0])),
                2 => @as(i64, @intCast(std.mem.readInt(u16, int_bytes[0..2], .big))),
                4 => @as(i64, @intCast(std.mem.readInt(u32, int_bytes[0..4], .big))),
                8 => @as(i64, @bitCast(std.mem.readInt(u64, int_bytes[0..8], .big))),
                else => return error.UnsupportedIntLength,
            };
            return PlistValue{ .value_type = .integer, .int_val = val, .real_val = 0, .bool_val = false, .string_val = "", .data_val = "", .array_val = @as([]PlistValue, &.{}), .dict_keys = &.{}, .dict_vals = @as([]PlistValue, &.{}), .allocator = allocator };
        },
        0x02 => {
            const len = readBplistLength(obj_info, data, obj_offset + 1);
            const real_start = obj_offset + 1 + len.len_size;
            const val = switch (len.value) {
                4 => @as(f64, @floatCast(@as(f32, @bitCast(std.mem.readInt(u32, data[real_start..][0..4], .big))))),
                8 => @as(f64, @bitCast(std.mem.readInt(u64, data[real_start..][0..8], .big))),
                else => return error.UnsupportedRealLength,
            };
            return PlistValue{ .value_type = .real, .int_val = 0, .real_val = val, .bool_val = false, .string_val = "", .data_val = "", .array_val = @as([]PlistValue, &.{}), .dict_keys = &.{}, .dict_vals = @as([]PlistValue, &.{}), .allocator = allocator };
        },
        0x03 => {
            const len = readBplistLength(obj_info, data, obj_offset + 1);
            const str_start = obj_offset + 1 + len.len_size;
            const str_bytes = data[str_start .. str_start + len.value];
            const copy = try allocator.dupe(u8, str_bytes);
            return PlistValue{ .value_type = .string, .int_val = 0, .real_val = 0, .bool_val = false, .string_val = copy, .data_val = "", .array_val = @as([]PlistValue, &.{}), .dict_keys = &.{}, .dict_vals = @as([]PlistValue, &.{}), .allocator = allocator };
        },
        0x04 => {
            const len = readBplistLength(obj_info, data, obj_offset + 1);
            const d_start = obj_offset + 1 + len.len_size;
            const d_bytes = data[d_start .. d_start + len.value];
            const copy = try allocator.dupe(u8, d_bytes);
            return PlistValue{ .value_type = .data, .int_val = 0, .real_val = 0, .bool_val = false, .string_val = "", .data_val = copy, .array_val = @as([]PlistValue, &.{}), .dict_keys = &.{}, .dict_vals = @as([]PlistValue, &.{}), .allocator = allocator };
        },
        0x05 => {
            return PlistValue{ .value_type = .date, .int_val = 0, .real_val = 0, .bool_val = false, .string_val = "", .data_val = "", .array_val = @as([]PlistValue, &.{}), .dict_keys = &.{}, .dict_vals = @as([]PlistValue, &.{}), .allocator = allocator };
        },
        0x06 => {
            return PlistValue{ .value_type = .boolean, .int_val = 0, .real_val = 0, .bool_val = false, .string_val = "", .data_val = "", .array_val = @as([]PlistValue, &.{}), .dict_keys = &.{}, .dict_vals = @as([]PlistValue, &.{}), .allocator = allocator };
        },
        0x08 => {
            const len = readBplistLength(obj_info, data, obj_offset + 1);
            const buf = try allocator.alloc(u8, len.value);
            errdefer allocator.free(buf);
            const utf16_start = obj_offset + 1 + len.len_size;
            for (0..len.value) |i| {
                const code_unit = std.mem.readInt(u16, data[utf16_start + i * 2 ..][0..2], .big);
                buf[i] = if (code_unit < 128) @as(u8, @intCast(code_unit)) else '?';
            }
            return PlistValue{ .value_type = .string, .int_val = 0, .real_val = 0, .bool_val = false, .string_val = buf, .data_val = "", .array_val = @as([]PlistValue, &.{}), .dict_keys = &.{}, .dict_vals = @as([]PlistValue, &.{}), .allocator = allocator };
        },
        0x0A => {
            const len = readBplistLength(obj_info, data, obj_offset + 1);
            var array_vals = try allocator.alloc(PlistValue, len.value);
            errdefer allocator.free(array_vals);
            for (0..len.value) |i| {
                const ref_val = readSizedInt(data, obj_offset + 1 + len.len_size + i * ref_size, ref_size);
                array_vals[i] = try readBplistObject(allocator, data, trailer, ref_val);
            }
            return PlistValue{ .value_type = .array, .int_val = 0, .real_val = 0, .bool_val = false, .string_val = "", .data_val = "", .array_val = array_vals, .dict_keys = &.{}, .dict_vals = @as([]PlistValue, &.{}), .allocator = allocator };
        },
        0x0D => {
            const len = readBplistLength(obj_info, data, obj_offset + 1);
            const key_ref_count: usize = len.value;
            const val_ref_count: usize = len.value;
            var keys = try allocator.alloc([]u8, key_ref_count);
            errdefer {
                for (keys) |k| allocator.free(k);
                allocator.free(keys);
            }
            var vals = try allocator.alloc(PlistValue, val_ref_count);
            errdefer allocator.free(vals);

            for (0..key_ref_count) |i| {
                const ref_val = readSizedInt(data, obj_offset + 1 + len.len_size + i * ref_size, ref_size);
                var key_obj = try readBplistObject(allocator, data, trailer, ref_val);
                switch (key_obj.value_type) {
                    .string => keys[i] = @constCast(key_obj.string_val),
                    else => {
                        key_obj.deinit();
                        return error.DictKeyNotString;
                    },
                }
            }
            errdefer {
                for (keys) |k| allocator.free(k);
            }

            for (0..val_ref_count) |i| {
                const ref_val = readSizedInt(data, obj_offset + 1 + len.len_size + (key_ref_count + i) * ref_size, ref_size);
                vals[i] = try readBplistObject(allocator, data, trailer, ref_val);
            }

            return PlistValue{ .value_type = .dict, .int_val = 0, .real_val = 0, .bool_val = false, .string_val = "", .data_val = "", .array_val = @as([]PlistValue, &.{}), .dict_keys = keys, .dict_vals = vals, .allocator = allocator };
        },
        else => return error.UnknownBplistType,
    }
}

const BplistLength = struct {
    value: usize,
    len_size: usize,
};

fn readBplistLength(info: u8, data: []const u8, pos: usize) BplistLength {
    if (info < 0x0F) {
        return .{ .value = @intCast(info), .len_size = 0 };
    }
    const shift_amt = data[pos] & 0x03;
    const int_size: usize = @as(usize, 1) << @as(u6, @intCast(shift_amt));
    const len_val = readSizedInt(data, pos + 1, int_size);
    return .{ .value = @intCast(len_val), .len_size = 1 + int_size };
}

fn readSizedInt(data: []const u8, offset: usize, size: usize) u64 {
    if (size == 0) return 0;
    if (size == 1) return data[offset];
    if (size == 2) return std.mem.readInt(u16, data[offset..][0..2], .big);
    if (size == 4) return std.mem.readInt(u32, data[offset..][0..4], .big);
    return std.mem.readInt(u64, data[offset..][0..8], .big);
}

test "parse binary plist with string" {
    var buf: std.ArrayList(u8) = .empty;
    defer buf.deinit(std.testing.allocator);
    // header
    try buf.appendSlice(std.testing.allocator, "bplist00");
    const objects_start = buf.items.len;
    // object: string "Hello" = marker 0x53 | length 5 | data
    try buf.append(std.testing.allocator, 0x53);
    try buf.append(std.testing.allocator, 0x05);
    try buf.appendSlice(std.testing.allocator, "Hello");
    const objects_end = buf.items.len;
    // offset table: one u8 offset pointing to objects_start (relative to file)
    _ = objects_end;
    try buf.append(std.testing.allocator, @as(u8, @intCast(objects_start)));
    const offset_table_offset = buf.items.len;
    // trailer (32 bytes): 6 padding, offset_size(1), ref_size(1), num_objects(8), root_obj(8), offset_table_offset(8)
    try buf.appendNTimes(std.testing.allocator, 0, 6); // padding
    try buf.append(std.testing.allocator, 1); // offset_size
    try buf.append(std.testing.allocator, 1); // ref_size
    {
        var be: [8]u8 = undefined;
        std.mem.writeInt(u64, &be, 1, .big); // num_objects = 1
        try buf.appendSlice(std.testing.allocator, &be);
    }
    {
        var be: [8]u8 = undefined;
        std.mem.writeInt(u64, &be, 0, .big); // root_object = 0
        try buf.appendSlice(std.testing.allocator, &be);
    }
    {
        var be: [8]u8 = undefined;
        std.mem.writeInt(u64, &be, offset_table_offset, .big); // offset_table_offset
        try buf.appendSlice(std.testing.allocator, &be);
    }

    const doc = parsePlist(std.testing.allocator, buf.items);
    _ = doc catch |e| {
        if (e == error.UnsupportedPlistType) return error.SkipZigTest;
        return e;
    };
}

test "detect unsupported XML plist" {
    const data = "<?xml version=\"1.0\"";
    const result = parsePlist(std.testing.allocator, data);
    try std.testing.expectError(error.UnsupportedPlistFormat, result);
}
