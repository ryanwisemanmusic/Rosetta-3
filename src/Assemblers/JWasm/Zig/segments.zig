const std = @import("std");
const jwasm = @import("jwasm_core.zig");

const Allocator = std.mem.Allocator;

pub const Segment = struct {
    name: []const u8,
    class_name_str: []const u8 = "",
    seg_align: jwasm.SegmentAlign = .para,
    combine: jwasm.SegmentCombine = .private,
    use32: bool = false,
    use64: bool = false,
    address: u64 = 0,
    size: u64 = 0,
    data: std.ArrayListUnmanaged(u8) = .{ .items = &.{}, .capacity = 0 },
    group_index: u32 = std.math.maxInt(u32),
    frame_number: u32 = 0,
    seg_type: jwasm.seg_type = .undef,
    characteristics: u8 = 0,
    alignment: u8 = 4,
    readonly: bool = false,
    information: bool = false,
    data_in_code: bool = false,

    pub fn deinit(self: *Segment, allocator: Allocator) void {
        allocator.free(self.name);
        if (self.class_name_str.len > 0) allocator.free(self.class_name_str);
        self.data.deinit(allocator);
    }
};

pub const Group = struct {
    name: []const u8,
    segments: std.ArrayListUnmanaged(u32) = .{ .items = &.{}, .capacity = 0 },
    address: u64 = 0,

    pub fn deinit(self: *Group, allocator: Allocator) void {
        allocator.free(self.name);
        self.segments.deinit(allocator);
    }
};

pub const ModelState = struct {
    model: jwasm.model_type = .small,
    language: jwasm.lang_type = .none,
    use32: bool = false,
    use64: bool = false,
    os: u8 = 0,
    initialized: bool = false,

    pub fn isFlat(self: *const ModelState) bool {
        return self.model == .flat;
    }

    pub fn isTiny(self: *const ModelState) bool {
        return self.model == .tiny;
    }

    pub fn usesDgroup(self: *const ModelState) bool {
        return switch (self.model) {
            .tiny, .small, .medium, .compact, .large => true,
            else => false,
        };
    }

    pub fn farCode(self: *const ModelState) bool {
        return switch (self.model) {
            .medium, .large, .huge => true,
            else => false,
        };
    }

    pub fn farData(self: *const ModelState) bool {
        return switch (self.model) {
            .compact, .large, .huge => true,
            else => false,
        };
    }
};

pub const SegmentManager = struct {
    allocator: Allocator,
    segments: std.ArrayListUnmanaged(Segment) = .{ .items = &.{}, .capacity = 0 },
    groups: std.ArrayListUnmanaged(Group) = .{ .items = &.{}, .capacity = 0 },
    current_segment: ?u32 = null,
    model_state: ModelState = .{},
    seg_order: jwasm.seg_order = .seq,
    flat_group_idx: ?u32 = null,

    pub fn init(allocator: Allocator) SegmentManager {
        return SegmentManager{ .allocator = allocator };
    }

    pub fn deinit(self: *SegmentManager) void {
        for (self.segments.items) |*seg| seg.deinit(self.allocator);
        self.segments.deinit(self.allocator);
        for (self.groups.items) |*grp| grp.deinit(self.allocator);
        self.groups.deinit(self.allocator);
    }

    pub fn findSegment(self: *const SegmentManager, name: []const u8) ?u32 {
        for (self.segments.items, 0..) |seg, i| {
            if (std.ascii.eqlIgnoreCase(seg.name, name)) return @as(u32, @intCast(i));
        }
        return null;
    }

    pub fn addSegment(self: *SegmentManager, name: []const u8, seg_align: jwasm.SegmentAlign, combine: jwasm.SegmentCombine, use32: bool, class_name: []const u8) !u32 {
        if (self.findSegment(name)) |idx| return idx;
        const idx = @as(u32, @intCast(self.segments.items.len));
        try self.segments.append(self.allocator, Segment{
            .name = try self.allocator.dupe(u8, name),
            .class_name_str = try self.allocator.dupe(u8, class_name),
            .seg_align = seg_align,
            .combine = combine,
            .use32 = use32,
            .alignment = @as(u8, @truncate(@as(u32, 1) << @as(u5, @intCast(@intFromEnum(seg_align))))),
        });
        return idx;
    }

    pub fn addSegmentFull(self: *SegmentManager, name: []const u8, seg_type: jwasm.seg_type, alignment_val: u8, combine: u8, use32: bool, use64: bool, class_name: []const u8) !u32 {
        const idx = @as(u32, @intCast(self.segments.items.len));
        try self.segments.append(self.allocator, Segment{
            .name = try self.allocator.dupe(u8, name),
            .class_name_str = try self.allocator.dupe(u8, class_name),
            .use32 = use32,
            .use64 = use64,
            .seg_type = seg_type,
            .combine = @as(jwasm.SegmentCombine, @enumFromInt(combine)),
            .alignment = alignment_val,
        });
        return idx;
    }

    pub fn findGroup(self: *const SegmentManager, name: []const u8) ?u32 {
        for (self.groups.items, 0..) |grp, i| {
            if (std.ascii.eqlIgnoreCase(grp.name, name)) return @as(u32, @intCast(i));
        }
        return null;
    }

    pub fn addGroup(self: *SegmentManager, name: []const u8) !u32 {
        if (self.findGroup(name)) |idx| return idx;
        const idx = @as(u32, @intCast(self.groups.items.len));
        try self.groups.append(self.allocator, Group{
            .name = try self.allocator.dupe(u8, name),
        });
        return idx;
    }

    pub fn addSegmentToGroup(self: *SegmentManager, seg_idx: u32, group_idx: u32) !void {
        if (seg_idx < self.segments.items.len and group_idx < self.groups.items.len) {
            self.segments.items[seg_idx].group_index = group_idx;
            try self.groups.items[group_idx].segments.append(self.allocator, seg_idx);
        }
    }

    pub fn setModel(self: *SegmentManager, model: jwasm.model_type, lang: jwasm.lang_type, use32: bool) !void {
        self.model_state = ModelState{
            .model = model,
            .language = lang,
            .use32 = use32,
            .initialized = true,
        };
    }

    pub fn setModelFull(self: *SegmentManager, model: jwasm.model_type, lang: jwasm.lang_type, use32: bool, use64: bool) !void {
        self.model_state = ModelState{
            .model = model,
            .language = lang,
            .use32 = use32,
            .use64 = use64,
            .initialized = true,
        };
    }

    pub fn currentAddress(self: *const SegmentManager) u64 {
        const idx = self.current_segment orelse return 0;
        return self.segments.items[idx].address;
    }

    pub fn emit(self: *SegmentManager, bytes: []const u8) !void {
        const idx = self.current_segment orelse return;
        try self.segments.items[idx].data.appendSlice(self.allocator, bytes);
        self.segments.items[idx].address += bytes.len;
        self.segments.items[idx].size += bytes.len;
    }

    pub fn alignCurrent(self: *SegmentManager, alignment: u64) !void {
        const idx = self.current_segment orelse return;
        const seg = &self.segments.items[idx];
        const misalign = seg.address % alignment;
        if (misalign > 0) {
            const padding = alignment - misalign;
            try seg.data.appendNTimes(self.allocator, 0, @as(usize, @intCast(padding)));
            seg.address += padding;
            seg.size += padding;
        }
    }

    pub fn org(self: *SegmentManager, new_address: u64) !void {
        const idx = self.current_segment orelse return;
        const seg = &self.segments.items[idx];
        if (new_address < seg.size) {
            seg.address = new_address;
        } else {
            const padding = new_address - seg.size;
            try seg.data.appendNTimes(self.allocator, 0, @as(usize, @intCast(padding)));
            seg.address = new_address;
            seg.size = new_address;
        }
    }

    pub fn setSegOrder(self: *SegmentManager, order: jwasm.seg_order) void {
        self.seg_order = order;
    }

    pub fn getGroupOfSegment(self: *const SegmentManager, seg_idx: u32) ?u32 {
        if (seg_idx < self.segments.items.len) {
            const gi = self.segments.items[seg_idx].group_index;
            if (gi != std.math.maxInt(u32)) return gi;
        }
        return null;
    }

    pub fn selectOutputFormat(_: *SegmentManager, _: jwasm.OutputFormat) void {}
};

test "segment management" {
    var sm = SegmentManager.init(std.testing.allocator);
    defer sm.deinit();

    const idx = try sm.addSegment("_TEXT", .para, .public, false, "CODE");
    try std.testing.expectEqual(@as(u32, 0), idx);
    try std.testing.expect(sm.findSegment("_TEXT") != null);
}

test "model state queries" {
    var state = ModelState{ .model = .small, .language = .c };
    try std.testing.expect(!state.farCode());
    try std.testing.expect(!state.farData());
    try std.testing.expect(state.usesDgroup());

    state.model = .large;
    try std.testing.expect(state.farCode());
    try std.testing.expect(state.farData());
}

test "segment alignment" {
    var sm = SegmentManager.init(std.testing.allocator);
    defer sm.deinit();

    _ = try sm.addSegment("_DATA", .para, .public, false, "DATA");
    sm.current_segment = 0;
    try sm.alignCurrent(16);
    try std.testing.expectEqual(@as(u64, 0), sm.currentAddress());

    try sm.emit(&.{0x90});
    try sm.alignCurrent(16);
    try std.testing.expectEqual(@as(u64, 16), sm.currentAddress());
}

test "group management" {
    var sm = SegmentManager.init(std.testing.allocator);
    defer sm.deinit();

    const gidx = try sm.addGroup("DGROUP");
    try std.testing.expectEqual(@as(u32, 0), gidx);
    const sidx = try sm.addSegment("_DATA", .para, .public, false, "DATA");
    try sm.addSegmentToGroup(sidx, gidx);
    try std.testing.expectEqual(gidx, sm.getGroupOfSegment(sidx).?);
}

test "model state flat" {
    var state = ModelState{ .model = .flat, .language = .c, .use32 = true };
    try std.testing.expect(state.isFlat());
}

test "segment order" {
    var sm = SegmentManager.init(std.testing.allocator);
    defer sm.deinit();
    sm.setSegOrder(.dosseg);
    try std.testing.expectEqual(@as(jwasm.seg_order, .dosseg), sm.seg_order);
}
