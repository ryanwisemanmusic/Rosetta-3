const std = @import("std");

pub const max_segments = 32;

pub const CheckStatus = enum {
    valid,
    empty_image,
    null_pointer,
    below_image,
    beyond_image,
    crosses_image,
    non_executable,
    crosses_segment,
};

pub const Segment = struct {
    start: u32,
    size: u32,
    executable: bool = true,
    name: [8]u8 = [_]u8{0} ** 8,

    pub fn init(start: u32, size: u32, executable: bool, name: []const u8) Segment {
        var out = Segment{
            .start = start,
            .size = size,
            .executable = executable,
        };
        const copy_len = @min(name.len, out.name.len);
        @memcpy(out.name[0..copy_len], name[0..copy_len]);
        return out;
    }

    pub fn end(self: Segment) u64 {
        return @as(u64, self.start) + @as(u64, self.size);
    }

    pub fn nameSlice(self: *const Segment) []const u8 {
        var len: usize = 0;
        while (len < self.name.len and self.name[len] != 0) : (len += 1) {}
        return self.name[0..len];
    }

    pub fn containsAddress(self: Segment, addr: u32) bool {
        const wide = @as(u64, addr);
        return wide >= self.start and wide < self.end();
    }

    pub fn containsRange(self: Segment, addr: u32, width: usize) bool {
        if (!self.containsAddress(addr)) return false;
        const end_addr = @as(u64, addr) + @as(u64, @max(width, 1));
        return end_addr <= self.end();
    }
};

pub const Guard = struct {
    image_base: u32,
    image_size: u32,
    segments: []const Segment = &.{},

    pub fn imageEnd(self: Guard) u64 {
        return @as(u64, self.image_base) + @as(u64, self.image_size);
    }

    pub fn firstExecutableSegment(self: Guard) ?Segment {
        for (self.segments) |segment| {
            if (segment.executable and segment.size != 0) return segment;
        }
        return null;
    }
};

pub const CheckResult = struct {
    status: CheckStatus,
    eip: u32,
    width: usize,
    image_base: u32,
    image_end: u64,
    segment: ?Segment = null,

    pub fn isValid(self: CheckResult) bool {
        return self.status == .valid;
    }
};

fn makeResult(guard: Guard, eip: u32, width: usize, status: CheckStatus, segment: ?Segment) CheckResult {
    return .{
        .status = status,
        .eip = eip,
        .width = @max(width, 1),
        .image_base = guard.image_base,
        .image_end = guard.imageEnd(),
        .segment = segment,
    };
}

pub fn checkInstructionPointer(guard: Guard, eip: u32, width: usize) CheckResult {
    const effective_width = @max(width, 1);
    if (guard.image_size == 0) return makeResult(guard, eip, effective_width, .empty_image, null);
    if (eip == 0) return makeResult(guard, eip, effective_width, .null_pointer, null);

    const start = @as(u64, eip);
    const end = start + @as(u64, effective_width);
    const image_base = @as(u64, guard.image_base);
    const image_end = guard.imageEnd();

    if (start < image_base) return makeResult(guard, eip, effective_width, .below_image, null);
    if (start >= image_end) return makeResult(guard, eip, effective_width, .beyond_image, null);
    if (end > image_end) return makeResult(guard, eip, effective_width, .crosses_image, null);

    if (guard.segments.len == 0) return makeResult(guard, eip, effective_width, .valid, null);

    for (guard.segments) |segment| {
        if (segment.size == 0) continue;
        if (!segment.containsAddress(eip)) continue;
        if (!segment.executable) return makeResult(guard, eip, effective_width, .non_executable, segment);
        if (!segment.containsRange(eip, effective_width)) return makeResult(guard, eip, effective_width, .crosses_segment, segment);
        return makeResult(guard, eip, effective_width, .valid, segment);
    }

    return makeResult(guard, eip, effective_width, .non_executable, null);
}

pub fn rvaToVaIfInImage(guard: Guard, value: u32) ?u32 {
    if (value >= guard.image_size) return null;
    const va = @as(u64, guard.image_base) + @as(u64, value);
    if (va > std.math.maxInt(u32)) return null;
    return @intCast(va);
}

pub fn statusDescription(status: CheckStatus) []const u8 {
    return switch (status) {
        .valid => "EIP is inside executable image text",
        .empty_image => "loaded image has zero size",
        .null_pointer => "EIP is null",
        .below_image => "EIP is below the loaded image base",
        .beyond_image => "EIP is beyond the loaded image",
        .crosses_image => "instruction fetch crosses the loaded image boundary",
        .non_executable => "EIP is not inside an executable text segment",
        .crosses_segment => "instruction fetch crosses the executable text segment boundary",
    };
}

pub fn formatImageRange(buffer: []u8, guard: Guard) ![]const u8 {
    return std.fmt.bufPrint(buffer, "[0x{X:0>8}..0x{X:0>8}]", .{ guard.image_base, guard.imageEnd() });
}

test "checks executable text segment bounds" {
    const segments = [_]Segment{
        Segment.init(0x0040_2000, 0x1000, true, ".text"),
        Segment.init(0x0040_4000, 0x1000, false, ".rsrc"),
    };
    const guard = Guard{
        .image_base = 0x0040_0000,
        .image_size = 0x3E000,
        .segments = &segments,
    };

    try std.testing.expect(checkInstructionPointer(guard, 0x0040_2000, 6).isValid());
    try std.testing.expectEqual(CheckStatus.below_image, checkInstructionPointer(guard, 0x0001_F782, 1).status);
    try std.testing.expectEqual(CheckStatus.non_executable, checkInstructionPointer(guard, 0x0040_4000, 1).status);
    try std.testing.expectEqual(@as(u32, 0x0041_F782), rvaToVaIfInImage(guard, 0x0001_F782).?);
}
