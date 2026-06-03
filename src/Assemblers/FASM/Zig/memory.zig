const std = @import("std");
const fasm = @import("fasm_core.zig");

const Allocator = std.mem.Allocator;

const MemoryBlock = struct {
    data: []u8,
    offset: usize,
    capacity: usize,
    prev: ?*MemoryBlock,
};

const RootBlock = struct {
    data: []u8,
    offset: usize,
    capacity: usize,
};

pub const VariableArea = struct {
    _block: RootBlock,

    pub fn init(size: usize) Allocator.Error!VariableArea {
        const data = try std.heap.page_allocator.alloc(u8, size);
        return VariableArea{
            ._block = RootBlock{
                .data = data,
                .offset = 0,
                .capacity = size,
            },
        };
    }

    pub fn deinit(self: *VariableArea) void {
        std.heap.page_allocator.free(self._block.data);
        self._block.offset = 0;
    }

    pub fn reset(self: *VariableArea) void {
        self._block.offset = 0;
    }

    pub fn alloc(self: *VariableArea, comptime T: type, count: usize) Allocator.Error![]T {
        const bytes = count * @sizeOf(T);
        if (self._block.offset + bytes > self._block.capacity) return Allocator.Error.OutOfMemory;
        defer self._block.offset += bytes;
        const ptr: [*]T = @ptrCast(@alignCast(&self._block.data[self._block.offset]));
        return ptr[0..count];
    }

    pub fn allocAligned(self: *VariableArea, comptime T: type, count: usize, alignment: u32) Allocator.Error![]T {
        const align_mask = alignment - 1;
        const aligned_offset = (self._block.offset + align_mask) & ~align_mask;
        const bytes = count * @sizeOf(T);
        if (aligned_offset + bytes > self._block.capacity) return Allocator.Error.OutOfMemory;
        self._block.offset = aligned_offset + bytes;
        const ptr: [*]T = @ptrCast(@alignCast(&self._block.data[aligned_offset]));
        return ptr[0..count];
    }

    pub fn totalUsed(self: *const VariableArea) usize {
        return self._block.offset;
    }

    pub fn remaining(self: *const VariableArea) usize {
        return self._block.capacity - self._block.offset;
    }
};

pub const MemoryPool = struct {
    allocator: Allocator,
    blocks: std.ArrayListUnmanaged(MemoryBlock) = .{ .items = &.{}, .capacity = 0 },

    const BlockSize: usize = 64 * 1024;

    pub fn init(allocator: Allocator) MemoryPool {
        return MemoryPool{ .allocator = allocator };
    }

    pub fn deinit(self: *MemoryPool) void {
        for (self.blocks.items) |*block| {
            self.allocator.free(block.data);
        }
        self.blocks.deinit(self.allocator);
    }

    pub fn allocate(self: *MemoryPool, size: usize) Allocator.Error![]u8 {
        if (self.blocks.items.len == 0 or
            self.blocks.items[self.blocks.items.len - 1].offset + size > BlockSize)
        {
            const data = try self.allocator.alloc(u8, BlockSize);
            try self.blocks.append(self.allocator, .{
                .data = data,
                .offset = 0,
                .capacity = BlockSize,
                .prev = if (self.blocks.items.len > 0) &self.blocks.items[self.blocks.items.len - 1] else null,
            });
        }
        const block = &self.blocks.items[self.blocks.items.len - 1];
        const result = block.data[block.offset .. block.offset + size];
        block.offset += size;
        return result;
    }
};

test "VariableArea basic alloc" {
    var va = try VariableArea.init(1024);
    defer va.deinit();
    const ints = try va.alloc(u32, 10);
    try std.testing.expectEqual(@as(usize, 10), ints.len);
    try std.testing.expectEqual(@as(usize, 40), va.totalUsed());
}

test "MemoryPool allocation" {
    var pool = MemoryPool.init(std.testing.allocator);
    defer pool.deinit();
    const data = try pool.allocate(128);
    try std.testing.expectEqual(@as(usize, 128), data.len);
}
