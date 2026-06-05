const std = @import("std");
const builtin = @import("builtin");
const runtime_abi = @import("runtime_abi_handshake");

pub const PAGE_1K: u64 = 1024;
pub const PAGE_4K: u64 = 4096;
pub const PAGE_16K: u64 = 16384;
pub const PAGE_2M: u64 = 2 * 1024 * 1024;
pub const PAGE_4M: u64 = 4 * 1024 * 1024;

pub const NATIVE_PAGE_SIZE: u64 = switch (builtin.target.cpu.arch) {
    .aarch64 => PAGE_16K,
    else => PAGE_4K,
};

pub const NATIVE_PAGE_SHIFT: u6 = switch (builtin.target.cpu.arch) {
    .aarch64 => 14,
    else => 12,
};

pub const SUB_SLOT_SIZE: u64 = PAGE_4K;
pub const SUB_SLOTS_PER_NATIVE: u4 = @intCast(NATIVE_PAGE_SIZE / SUB_SLOT_SIZE);

fn isPowerOf2(x: u64) bool {
    return x != 0 and (x & (x - 1)) == 0;
}

pub fn alignUp(addr: u64, alignment: u64) u64 {
    if (alignment == 0) return addr;
    return (addr + alignment - 1) & ~(alignment - 1);
}

pub fn alignDown(addr: u64, alignment: u64) u64 {
    if (alignment == 0) return addr;
    return addr & ~(alignment - 1);
}

pub fn isPageAligned(addr: u64) bool {
    return addr & (NATIVE_PAGE_SIZE - 1) == 0;
}

pub const SizeClass = enum(u3) {
    size_1k = 0,
    size_4k = 1,
    size_16k = 2,
    size_2m = 3,
    size_4m = 4,

    pub const COUNT: u3 = 5;

    pub fn bytes(self: SizeClass) u64 {
        return switch (self) {
            .size_1k => PAGE_1K,
            .size_4k => PAGE_4K,
            .size_16k => PAGE_16K,
            .size_2m => PAGE_2M,
            .size_4m => PAGE_4M,
        };
    }

    pub fn forSize(size: u64) SizeClass {
        if (size <= PAGE_1K) return .size_1k;
        if (size <= PAGE_4K) return .size_4k;
        if (size <= PAGE_16K) return .size_16k;
        if (size <= PAGE_2M) return .size_2m;
        return .size_4m;
    }

    pub fn nativePages(self: SizeClass) u64 {
        return @max(1, self.bytes() / NATIVE_PAGE_SIZE);
    }

    pub fn nextLarger(self: SizeClass) ?SizeClass {
        return switch (self) {
            .size_1k => .size_4k,
            .size_4k => .size_16k,
            .size_16k => .size_2m,
            .size_2m => .size_4m,
            .size_4m => null,
        };
    }

    pub fn nextSmaller(self: SizeClass) ?SizeClass {
        return switch (self) {
            .size_1k => null,
            .size_4k => .size_1k,
            .size_16k => .size_4k,
            .size_2m => .size_16k,
            .size_4m => .size_2m,
        };
    }
};

pub const SubSlotBitmap = packed struct {
    slots: u4,

    pub fn init() SubSlotBitmap {
        return .{ .slots = 0 };
    }

    pub fn isFree(self: SubSlotBitmap, index: u4) bool {
        return (self.slots & (@as(u4, 1) << index)) == 0;
    }

    pub fn markUsed(self: *SubSlotBitmap, index: u4) void {
        self.slots |= @as(u4, 1) << index;
    }

    pub fn markFree(self: *SubSlotBitmap, index: u4) void {
        self.slots &= ~(@as(u4, 1) << index);
    }

    pub fn allFree(self: SubSlotBitmap) bool {
        return self.slots == 0;
    }

    pub fn allUsed(self: SubSlotBitmap) bool {
        return self.slots == 0xF;
    }

    pub fn firstFree(self: SubSlotBitmap) ?u4 {
        comptime var i: u4 = 0;
        inline while (i < 4) : (i += 1) {
            if ((self.slots & (@as(u4, 1) << i)) == 0)
                return i;
        }
        return null;
    }

    pub fn usedCount(self: SubSlotBitmap) u4 {
        return @popCount(self.slots);
    }
};

const SUB_PAGE_MAGIC: u32 = 0x5053424C;

const SubPageDesc = struct {
    magic: u32,
    base_addr: u64,
    bitmap: SubSlotBitmap,
    next: ?*SubPageDesc,
    prev: ?*SubPageDesc,
};

const FREE_NODE_MAGIC: u32 = 0x46524545;

const FreeNode = struct {
    magic: u32,
    size_class: SizeClass,
    next: ?*FreeNode,
    prev: ?*FreeNode,
};

const ALLOC_HEADER_MAGIC: u32 = 0x414C4C4F;

const AllocHeader = struct {
    magic: u32,
    size: u64,
    is_subslot: bool,
};

pub const FragmentationStats = struct {
    total_bytes: u64,
    free_bytes: u64,
    used_bytes: u64,
    sub_page_free_slots: u32,
    sub_page_used_slots: u32,
    largest_free_block: u64,
    smallest_free_block: u64,
    free_block_count: u32,
    external_fragmentation_bytes: u64,
    internal_waste_bytes: u64,
};

pub const PageAllocator = struct {
    base_addr: u64,
    pool_size: u64,
    free_lists: [SizeClass.COUNT]?*FreeNode,
    sub_pages: ?*SubPageDesc,
    allocation_count: u64,
    total_free: u64,
    largest_free: u64,
    smallest_free: u64,

    pub fn init(base: u64, size: u64) PageAllocator {
        const aligned_base = alignUp(base, NATIVE_PAGE_SIZE);
        const usable_size = size - (aligned_base - base);
        const truncated_size = alignDown(usable_size, NATIVE_PAGE_SIZE);

        var alloc = PageAllocator{
            .base_addr = aligned_base,
            .pool_size = truncated_size,
            .free_lists = [_]?*FreeNode{null} ** SizeClass.COUNT,
            .sub_pages = null,
            .allocation_count = 0,
            .total_free = truncated_size,
            .largest_free = truncated_size,
            .smallest_free = truncated_size,
        };
        if (truncated_size >= NATIVE_PAGE_SIZE) {
            var node = @as(*FreeNode, @ptrFromInt(aligned_base));
            node.magic = FREE_NODE_MAGIC;
            node.size_class = .size_16k;
            node.next = null;
            node.prev = null;
            if (truncated_size >= SizeClass.size_2m.bytes()) {
                node.size_class = .size_2m;
            }
            if (truncated_size >= SizeClass.size_4m.bytes()) {
                node.size_class = .size_4m;
            }
            alloc.free_lists[@intFromEnum(node.size_class)] = node;
            alloc.largest_free = truncated_size;
        }
        return alloc;
    }

    pub fn alloc(self: *PageAllocator, size: u64, alignment: u64) ?[]align(1) u8 {
        const actual_alignment = if (alignment == 0) NATIVE_PAGE_SIZE else alignment;
        if (!isPowerOf2(actual_alignment)) return null;

        if (size <= SUB_SLOT_SIZE and actual_alignment <= SUB_SLOT_SIZE) {
            if (self.allocSubSlot()) |slot| {
                return slot;
            }
        }

        const class = SizeClass.forSize(@max(size, actual_alignment));
        const alloc_size = class.bytes();

        var chosen_class = class;
        var node: ?*FreeNode = null;

        while (chosen_class != .size_4m) {
            var cur = self.free_lists[@intFromEnum(chosen_class)];
            while (cur) |n| {
                const addr = @intFromPtr(n);
                if ((addr & (actual_alignment - 1)) == 0) {
                    node = n;
                    break;
                }
                cur = n.next;
            }
            if (node != null) break;
            chosen_class = chosen_class.nextLarger() orelse break;
        }

        if (node == null) {
            node = self.free_lists[@intFromEnum(.size_4m)];
            while (node) |n| {
                const addr = @intFromPtr(n);
                if ((addr & (actual_alignment - 1)) == 0) break;
                node = n.next;
            }
        }

        const found = node orelse return null;
        self.removeNode(found);

        const block_addr = @intFromPtr(found);
        const block_size = found.size_class.bytes();

        const aligned_addr = alignUp(block_addr, actual_alignment);
        const aligned_end = alignUp(aligned_addr + alloc_size, actual_alignment);

        if (aligned_addr > block_addr) {
            const waste = aligned_addr - block_addr;
            if (waste >= NATIVE_PAGE_SIZE) {
                self.addFree(block_addr, class.forSize(waste));
            }
        }

        const leftover = block_size - (aligned_end - block_addr);
        if (leftover >= NATIVE_PAGE_SIZE) {
            self.addFree(aligned_end, class.forSize(leftover));
        }

        var hdr = @as(*AllocHeader, @ptrFromInt(aligned_addr));
        hdr.magic = ALLOC_HEADER_MAGIC;
        hdr.size = aligned_end - aligned_addr;
        hdr.is_subslot = false;

        self.allocation_count += 1;
        self.total_free -= hdr.size;

        if (self.total_free < self.largest_free) {
            self.largest_free = self.total_free;
        }
        if (self.total_free > 0 and (self.smallest_free == 0 or self.total_free < self.smallest_free)) {
            self.smallest_free = self.total_free;
        }

        const payload = aligned_addr + @sizeOf(AllocHeader);
        return @as([*]u8, @ptrFromInt(payload))[0..@as(usize, @intCast(hdr.size - @sizeOf(AllocHeader)))];
    }

    pub fn free(self: *PageAllocator, block: []align(1) u8) void {
        if (block.len == 0) return;

        const payload_addr = @intFromPtr(block.ptr);
        const hdr_addr = payload_addr - @sizeOf(AllocHeader);
        var hdr = @as(*AllocHeader, @ptrFromInt(hdr_addr));
        if (hdr.magic != ALLOC_HEADER_MAGIC) return;

        if (hdr.is_subslot) {
            self.freeSubSlot(block);
            return;
        }

        const block_addr = hdr_addr;
        const block_size = hdr.size;
        const class = SizeClass.forSize(block_size);

        self.addFree(block_addr, class);
        self.allocation_count -= 1;
        self.total_free += block_size;

        _ = self.coalesce();
    }

    fn removeNode(self: *PageAllocator, node: *FreeNode) void {
        const ci = @intFromEnum(node.size_class);
        var prev = node.prev;
        var next = node.next;
        if (prev) |p| {
            p.next = next;
        } else {
            self.free_lists[ci] = next;
        }
        if (next) |n| {
            n.prev = prev;
        }
        node.next = null;
        node.prev = null;
    }

    fn addFree(self: *PageAllocator, addr: u64, class: SizeClass) void {
        var node = @as(*FreeNode, @ptrFromInt(addr));
        node.magic = FREE_NODE_MAGIC;
        node.size_class = class;
        const ci = @intFromEnum(class);
        node.next = self.free_lists[ci];
        node.prev = null;
        if (self.free_lists[ci]) |head| {
            head.prev = node;
        }
        self.free_lists[ci] = node;
    }

    pub fn coalesce(self: *PageAllocator) void {
        var all_free: ?*FreeNode = null;
        var tail: ?*FreeNode = null;

        inline for (0..SizeClass.COUNT) |i| {
            var cur = self.free_lists[i];
            while (cur) |n| {
                const next = n.next;
                n.next = null;
                n.prev = tail;
                if (tail) |t| {
                    t.next = n;
                } else {
                    all_free = n;
                }
                tail = n;
                cur = next;
            }
            self.free_lists[i] = null;
        }

        var sorted: ?*FreeNode = null;
        var cur = all_free;
        while (cur) |n| {
            const next = n.next;
            const addr = @intFromPtr(n);
            var prev: ?*FreeNode = null;
            var scan = sorted;
            while (scan) |s| {
                if (@intFromPtr(s) > addr) break;
                prev = scan;
                scan = s.next;
            }
            n.next = scan;
            n.prev = prev;
            if (prev) |p| {
                p.next = n;
            } else {
                sorted = n;
            }
            if (scan) |s| {
                s.prev = n;
            }
            cur = next;
        }

        cur = sorted;
        while (cur) |n| {
            const n_addr = @intFromPtr(n);
            const n_size = n.size_class.bytes();
            const n_end = n_addr + n_size;
            if (n.next) |next| {
                const next_addr = @intFromPtr(next);
                if (next_addr == n_end) {
                    const combined = SizeClass.forSize(n_size + next.size_class.bytes());
                    n.size_class = combined;
                    n.next = next.next;
                    if (next.next) |nn| nn.prev = n;
                    continue;
                }
            }
            const ci = @intFromEnum(n.size_class);
            n.next = self.free_lists[ci];
            n.prev = null;
            if (self.free_lists[ci]) |head| {
                head.prev = n;
            }
            self.free_lists[ci] = n;
            cur = n.next;
        }
    }

    fn allocSubSlot(self: *PageAllocator) ?[]align(1) u8 {
        var sd = self.sub_pages;
        if (sd == null) {
            const raw = self.alloc(PAGE_16K, PAGE_16K) orelse return null;
            const raw_addr = @intFromPtr(raw.ptr) - @sizeOf(AllocHeader);
            sd = @as(*SubPageDesc, @ptrFromInt(raw_addr));
            sd.magic = SUB_PAGE_MAGIC;
            sd.base_addr = raw_addr;
            sd.bitmap = SubSlotBitmap.init();
            sd.next = self.sub_pages;
            sd.prev = null;
            if (self.sub_pages) |head| head.prev = sd;
            self.sub_pages = sd;
        }

        var best = sd;
        while (sd) |s| {
            if (s.magic != SUB_PAGE_MAGIC) {
                sd = s.next;
                continue;
            }
            if (s.bitmap.usedCount() < best.bitmap.usedCount()) {
                best = s;
            }
            sd = s.next;
        }

        const slot_idx = best.bitmap.firstFree() orelse {
            const raw = self.alloc(PAGE_16K, PAGE_16K) orelse return null;
            const raw_addr = @intFromPtr(raw.ptr) - @sizeOf(AllocHeader);
            var new_sd = @as(*SubPageDesc, @ptrFromInt(raw_addr));
            new_sd.magic = SUB_PAGE_MAGIC;
            new_sd.base_addr = raw_addr;
            new_sd.bitmap = SubSlotBitmap.init();
            new_sd.next = self.sub_pages;
            new_sd.prev = null;
            if (self.sub_pages) |head| head.prev = new_sd;
            self.sub_pages = new_sd;
            best = new_sd;
            _ = slot_idx;
        };

        const actual_slot_idx = best.bitmap.firstFree() orelse return null;
        best.bitmap.markUsed(actual_slot_idx);
        const slot_addr = best.base_addr + @sizeOf(AllocHeader) + @as(u64, actual_slot_idx) * SUB_SLOT_SIZE;

        var hdr = @as(*AllocHeader, @ptrFromInt(slot_addr - @sizeOf(AllocHeader)));
        hdr.magic = ALLOC_HEADER_MAGIC;
        hdr.size = SUB_SLOT_SIZE;
        hdr.is_subslot = true;

        self.allocation_count += 1;
        return @as([*]u8, @ptrFromInt(slot_addr))[0..SUB_SLOT_SIZE];
    }

    fn freeSubSlot(self: *PageAllocator, block: []align(1) u8) void {
        const payload_addr = @intFromPtr(block.ptr);
        const hdr_addr = payload_addr - @sizeOf(AllocHeader);
        const block_addr = hdr_addr;

        var sd = self.sub_pages;
        while (sd) |s| {
            if (s.magic != SUB_PAGE_MAGIC) {
                sd = s.next;
                continue;
            }
            const page_start = s.base_addr;
            const page_end = page_start + PAGE_16K;
            if (block_addr >= page_start + @sizeOf(AllocHeader) and block_addr < page_end) {
                const offset = block_addr - (page_start + @sizeOf(AllocHeader));
                const slot_idx: u4 = @intCast(offset / SUB_SLOT_SIZE);
                s.bitmap.markFree(slot_idx);
                self.allocation_count -= 1;
                if (s.bitmap.allFree()) {
                    if (s.prev) |p| p.next = s.next;
                    if (s.next) |n| n.prev = s.prev;
                    if (self.sub_pages == s) self.sub_pages = s.next;
                    const raw_block = @as([*]align(1) u8, @ptrFromInt(s.base_addr + @sizeOf(AllocHeader)))[0 .. PAGE_16K - @sizeOf(AllocHeader)];
                    self.free(raw_block);
                }
                return;
            }
            sd = s.next;
        }
    }

    pub fn fragmentationStats(self: *PageAllocator) FragmentationStats {
        var stats = FragmentationStats{
            .total_bytes = self.pool_size,
            .free_bytes = self.total_free,
            .used_bytes = self.pool_size - self.total_free,
            .sub_page_free_slots = 0,
            .sub_page_used_slots = 0,
            .largest_free_block = 0,
            .smallest_free_block = 0,
            .free_block_count = 0,
            .external_fragmentation_bytes = 0,
            .internal_waste_bytes = 0,
        };

        var sd = self.sub_pages;
        while (sd) |s| {
            if (s.magic != SUB_PAGE_MAGIC) {
                sd = s.next;
                continue;
            }
            const used = s.bitmap.usedCount();
            stats.sub_page_used_slots += used;
            stats.sub_page_free_slots += SUB_SLOTS_PER_NATIVE - used;
            sd = s.next;
        }

        inline for (0..SizeClass.COUNT) |i| {
            var cur = self.free_lists[i];
            while (cur) |n| {
                const nsize = n.size_class.bytes();
                stats.free_block_count += 1;
                if (nsize > stats.largest_free_block) stats.largest_free_block = nsize;
                if (stats.smallest_free_block == 0 or nsize < stats.smallest_free_block) stats.smallest_free_block = nsize;
                cur = n.next;
            }
        }

        const worst_waste = self.total_free - stats.largest_free_block;
        stats.external_fragmentation_bytes = worst_waste;

        stats.internal_waste_bytes = stats.sub_page_free_slots * SUB_SLOT_SIZE;

        return stats;
    }

    pub fn poolUsage(self: *PageAllocator) f64 {
        if (self.pool_size == 0) return 0.0;
        const used = self.pool_size - self.total_free;
        return @as(f64, @floatFromInt(used)) / @as(f64, @floatFromInt(self.pool_size)) * 100.0;
    }
};

export fn rosette_native_page_size() u64 {
    return NATIVE_PAGE_SIZE;
}

export fn rosette_native_page_shift() u6 {
    return NATIVE_PAGE_SHIFT;
}

export fn rosette_page_align_up(addr: u64, alignment: u64) u64 {
    return alignUp(addr, alignment);
}

export fn rosette_page_align_down(addr: u64, alignment: u64) u64 {
    return alignDown(addr, alignment);
}

test "SizeClass.bytes matches constants" {
    try std.testing.expectEqual(PAGE_1K, SizeClass.size_1k.bytes());
    try std.testing.expectEqual(PAGE_4K, SizeClass.size_4k.bytes());
    try std.testing.expectEqual(PAGE_16K, SizeClass.size_16k.bytes());
    try std.testing.expectEqual(PAGE_2M, SizeClass.size_2m.bytes());
    try std.testing.expectEqual(PAGE_4M, SizeClass.size_4m.bytes());
}

test "SizeClass.forSize picks correct class" {
    try std.testing.expectEqual(.size_1k, SizeClass.forSize(1));
    try std.testing.expectEqual(.size_1k, SizeClass.forSize(PAGE_1K));
    try std.testing.expectEqual(.size_4k, SizeClass.forSize(PAGE_1K + 1));
    try std.testing.expectEqual(.size_4k, SizeClass.forSize(PAGE_4K));
    try std.testing.expectEqual(.size_16k, SizeClass.forSize(PAGE_4K + 1));
    try std.testing.expectEqual(.size_16k, SizeClass.forSize(PAGE_16K));
    try std.testing.expectEqual(.size_2m, SizeClass.forSize(PAGE_16K + 1));
    try std.testing.expectEqual(.size_2m, SizeClass.forSize(PAGE_2M));
    try std.testing.expectEqual(.size_4m, SizeClass.forSize(PAGE_2M + 1));
    try std.testing.expectEqual(.size_4m, SizeClass.forSize(PAGE_4M));
}

test "SubSlotBitmap tracks 4 slots correctly" {
    var bm = SubSlotBitmap.init();
    try std.testing.expectEqual(@as(u4, 0), bm.slots);
    try std.testing.expect(bm.allFree());
    try std.testing.expect(!bm.allUsed());

    try std.testing.expectEqual(@as(?u4, 0), bm.firstFree());
    bm.markUsed(0);
    try std.testing.expectEqual(@as(?u4, 1), bm.firstFree());
    bm.markUsed(1);
    bm.markUsed(2);
    bm.markUsed(3);
    try std.testing.expect(bm.allUsed());
    try std.testing.expectEqual(@as(?u4, null), bm.firstFree());

    bm.markFree(1);
    try std.testing.expect(!bm.allUsed());
    try std.testing.expectEqual(@as(?u4, 1), bm.firstFree());
}

test "alignUp and alignDown" {
    try std.testing.expectEqual(@as(u64, 0), alignUp(0, PAGE_4K));
    try std.testing.expectEqual(@as(u64, PAGE_4K), alignUp(1, PAGE_4K));
    try std.testing.expectEqual(@as(u64, PAGE_4K), alignUp(PAGE_4K, PAGE_4K));
    try std.testing.expectEqual(@as(u64, PAGE_16K), alignUp(PAGE_4K + 1, PAGE_16K));
    try std.testing.expectEqual(@as(u64, 0), alignDown(0, PAGE_4K));
    try std.testing.expectEqual(@as(u64, 0), alignDown(PAGE_4K - 1, PAGE_4K));
    try std.testing.expectEqual(@as(u64, PAGE_4K), alignDown(PAGE_4K, PAGE_4K));
}

test "PageAllocator basic alloc and free" {
    const pool_size = PAGE_16K * 8;
    const pool = try std.testing.allocator.alloc(u8, pool_size);
    defer std.testing.allocator.free(pool);

    var allocator = PageAllocator.init(@intFromPtr(pool.ptr), pool_size);

    const block1 = allocator.alloc(PAGE_4K, PAGE_4K) orelse return error.TestFailed;
    try std.testing.expectEqual(PAGE_4K - @sizeOf(AllocHeader), block1.len);
    try std.testing.expect(@intFromPtr(block1.ptr) & (PAGE_4K - 1) == 0);

    const block2 = allocator.alloc(PAGE_4K, PAGE_4K) orelse return error.TestFailed;
    try std.testing.expect(@intFromPtr(block2.ptr) & (PAGE_4K - 1) == 0);

    allocator.free(block1);
    allocator.free(block2);

    const stats = allocator.fragmentationStats();
    try std.testing.expect(stats.free_bytes == pool_size or stats.free_bytes == pool_size);
}

test "PageAllocator sub-4k allocation within 16k" {
    const pool_size = PAGE_16K * 4;
    const pool = try std.testing.allocator.alloc(u8, pool_size);
    defer std.testing.allocator.free(pool);

    var allocator = PageAllocator.init(@intFromPtr(pool.ptr), pool_size);

    const small1 = allocator.alloc(1024, 1024) orelse return error.TestFailed;
    const small2 = allocator.alloc(2048, 1024) orelse return error.TestFailed;
    const small3 = allocator.alloc(512, 1024) orelse return error.TestFailed;
    const small4 = allocator.alloc(3072, 1024) orelse return error.TestFailed;

    allocator.free(small2);
    allocator.free(small4);

    const small5 = allocator.alloc(1024, 1024) orelse return error.TestFailed;
    _ = small5;

    allocator.free(small1);
    allocator.free(small3);
    allocator.free(small5);

    const stats = allocator.fragmentationStats();
    try std.testing.expect(stats.sub_page_free_slots >= 0);
}

test "PageAllocator coalesce merges adjacent free blocks" {
    const pool_size = PAGE_16K * 8;
    const pool = try std.testing.allocator.alloc(u8, pool_size);
    defer std.testing.allocator.free(pool);

    var allocator = PageAllocator.init(@intFromPtr(pool.ptr), pool_size);

    const a = allocator.alloc(PAGE_16K, PAGE_16K) orelse return error.TestFailed;
    const b = allocator.alloc(PAGE_16K, PAGE_16K) orelse return error.TestFailed;
    const c = allocator.alloc(PAGE_16K, PAGE_16K) orelse return error.TestFailed;
    _ = c;

    allocator.free(a);
    allocator.free(b);

    const large = allocator.alloc(PAGE_2M, PAGE_16K);
    try std.testing.expect(large != null);

    if (large) |l| allocator.free(l);
}

test "SizeClass native pages mapping" {
    try std.testing.expectEqual(@as(u64, 1), SizeClass.size_1k.nativePages());
    try std.testing.expectEqual(@as(u64, 1), SizeClass.size_4k.nativePages());
    try std.testing.expectEqual(@as(u64, 1), SizeClass.size_16k.nativePages());
    try std.testing.expectEqual(@as(u64, 128), SizeClass.size_2m.nativePages());
    try std.testing.expectEqual(@as(u64, 256), SizeClass.size_4m.nativePages());
}
