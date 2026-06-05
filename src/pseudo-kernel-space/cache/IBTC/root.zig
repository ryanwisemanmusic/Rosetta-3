const std = @import("std");

pub const EntryState = enum(u8) {
    empty = 0,
    live = 1,
    tombstone = 2,
};

pub const FLAG_PINNED: u8 = 1 << 0;
pub const FLAG_EXECUTABLE: u8 = 1 << 1;

const METADATA_STATE_MASK: u64 = 0xFF;
const METADATA_FLAGS_SHIFT: u6 = 8;
const METADATA_EPOCH_SHIFT: u6 = 16;

pub const IBTCKey = extern struct {
    branch_guest_pc: u64,
    target_guest_pc: u64,
    address_space_id: u64,

    pub fn init(branch_guest_pc: u64, target_guest_pc: u64, address_space_id: u64) IBTCKey {
        return .{
            .branch_guest_pc = branch_guest_pc,
            .target_guest_pc = target_guest_pc,
            .address_space_id = address_space_id,
        };
    }

    pub fn eql(self: IBTCKey, other: IBTCKey) bool {
        return self.branch_guest_pc == other.branch_guest_pc and
            self.target_guest_pc == other.target_guest_pc and
            self.address_space_id == other.address_space_id;
    }

    pub fn hash(self: IBTCKey) u64 {
        var hasher = std.hash.Wyhash.init(0x866d_cace_1b7c);
        hasher.update(std.mem.asBytes(&self.branch_guest_pc));
        hasher.update(std.mem.asBytes(&self.target_guest_pc));
        hasher.update(std.mem.asBytes(&self.address_space_id));
        return hasher.final();
    }
};

pub const IBTCEntry = extern struct {
    branch_guest_pc: u64,
    target_guest_pc: u64,
    address_space_id: u64,
    host_pc: u64,
    macho_block_id: u64,
    hit_count: u64,
    last_access: u64,
    metadata: u64,

    pub fn empty() IBTCEntry {
        return .{
            .branch_guest_pc = 0,
            .target_guest_pc = 0,
            .address_space_id = 0,
            .host_pc = 0,
            .macho_block_id = 0,
            .hit_count = 0,
            .last_access = 0,
            .metadata = metadataFor(.empty, 0, 0),
        };
    }

    pub fn key(self: *const IBTCEntry) IBTCKey {
        return IBTCKey.init(self.branch_guest_pc, self.target_guest_pc, self.address_space_id);
    }

    pub fn state(self: *const IBTCEntry) EntryState {
        return @enumFromInt(@as(u8, @truncate(self.metadata & METADATA_STATE_MASK)));
    }

    pub fn flags(self: *const IBTCEntry) u8 {
        return @truncate((self.metadata >> METADATA_FLAGS_SHIFT) & 0xFF);
    }

    pub fn epoch(self: *const IBTCEntry) u64 {
        return self.metadata >> METADATA_EPOCH_SHIFT;
    }

    pub fn isLive(self: *const IBTCEntry) bool {
        return self.state() == .live;
    }

    pub fn isPinned(self: *const IBTCEntry) bool {
        return (self.flags() & FLAG_PINNED) != 0;
    }

    pub fn setLive(self: *IBTCEntry, key_value: IBTCKey, host_pc: u64, macho_block_id: u64, flags_value: u8, epoch_value: u64, now: u64) void {
        self.branch_guest_pc = key_value.branch_guest_pc;
        self.target_guest_pc = key_value.target_guest_pc;
        self.address_space_id = key_value.address_space_id;
        self.host_pc = host_pc;
        self.macho_block_id = macho_block_id;
        self.hit_count = 0;
        self.last_access = now;
        self.metadata = metadataFor(.live, flags_value, epoch_value);
    }

    pub fn setTombstone(self: *IBTCEntry) void {
        self.host_pc = 0;
        self.metadata = metadataFor(.tombstone, 0, self.epoch());
    }

    pub fn recordHit(self: *IBTCEntry, now: u64) void {
        _ = @atomicRmw(u64, &self.hit_count, .Add, 1, .monotonic);
        @atomicStore(u64, &self.last_access, now, .release);
    }

    comptime {
        if (@sizeOf(@This()) != 64) {
            @compileError("IBTCEntry must be one cache line");
        }
    }
};

pub const PutResult = struct {
    entry: *IBTCEntry,
    inserted: bool,
    previous_block_id: ?u64 = null,
    evicted: ?IBTCEntry = null,
};

pub const IBTCCache = struct {
    allocator: std.mem.Allocator,
    entries: []IBTCEntry,
    live_count: usize,
    byte_budget: u64,
    epoch: u64,

    pub fn init(allocator: std.mem.Allocator, byte_budget: u64) !IBTCCache {
        const entry_budget = @max(byte_budget / @sizeOf(IBTCEntry), 16);
        const capacity_u64 = ceilPowerOfTwo(entry_budget);
        const capacity: usize = @intCast(@min(capacity_u64, std.math.maxInt(usize)));
        const entries = try allocator.alloc(IBTCEntry, capacity);
        for (entries) |*entry| entry.* = IBTCEntry.empty();
        return .{
            .allocator = allocator,
            .entries = entries,
            .live_count = 0,
            .byte_budget = @as(u64, @intCast(capacity)) * @sizeOf(IBTCEntry),
            .epoch = 1,
        };
    }

    pub fn deinit(self: *IBTCCache) void {
        self.allocator.free(self.entries);
        self.* = undefined;
    }

    pub fn lookup(self: *IBTCCache, key: IBTCKey) ?*IBTCEntry {
        const index = self.findIndex(key) orelse return null;
        return &self.entries[index];
    }

    pub fn put(self: *IBTCCache, key: IBTCKey, host_pc: u64, macho_block_id: u64, flags: u8, now: u64) !PutResult {
        var evicted: ?IBTCEntry = null;
        if ((self.live_count + 1) * 4 >= self.entries.len * 3) {
            evicted = self.evictCold(now);
        }

        var slot = self.findInsertSlot(key);
        if (slot == null) {
            const cold = self.evictCold(now) orelse return error.IBTCCacheFull;
            evicted = cold;
            slot = self.findInsertSlot(key);
        }
        const index = slot orelse return error.IBTCCacheFull;
        const entry = &self.entries[index];

        if (entry.isLive() and entry.key().eql(key)) {
            const previous_block_id = entry.macho_block_id;
            entry.setLive(key, host_pc, macho_block_id, flags, self.nextEpoch(), now);
            return .{
                .entry = entry,
                .inserted = false,
                .previous_block_id = previous_block_id,
                .evicted = evicted,
            };
        }

        entry.setLive(key, host_pc, macho_block_id, flags, self.nextEpoch(), now);
        self.live_count += 1;
        return .{
            .entry = entry,
            .inserted = true,
            .evicted = evicted,
        };
    }

    pub fn evictKey(self: *IBTCCache, key: IBTCKey) ?IBTCEntry {
        const index = self.findIndex(key) orelse return null;
        return self.evictIndex(index);
    }

    pub fn evictBlockWithContext(
        self: *IBTCCache,
        macho_block_id: u64,
        context: anytype,
        comptime on_evict: fn (@TypeOf(context), *const IBTCEntry) void,
    ) usize {
        var removed: usize = 0;
        for (self.entries) |*entry| {
            if (!entry.isLive() or entry.macho_block_id != macho_block_id) continue;
            on_evict(context, entry);
            entry.setTombstone();
            removed += 1;
        }
        self.live_count -= removed;
        return removed;
    }

    pub fn evictBlock(self: *IBTCCache, macho_block_id: u64) usize {
        return self.evictBlockWithContext(macho_block_id, {}, noopEvict);
    }

    pub fn evictCold(self: *IBTCCache, now: u64) ?IBTCEntry {
        var victim_index: ?usize = null;
        var victim_score: u128 = std.math.maxInt(u128);

        for (self.entries, 0..) |*entry, index| {
            if (!entry.isLive() or entry.isPinned()) continue;
            const age = if (now > entry.last_access) now - entry.last_access else 0;
            const score = (@as(u128, entry.hit_count) << 64) | @as(u128, std.math.maxInt(u64) - age);
            if (score < victim_score) {
                victim_score = score;
                victim_index = index;
            }
        }

        const index = victim_index orelse return null;
        return self.evictIndex(index);
    }

    fn evictIndex(self: *IBTCCache, index: usize) IBTCEntry {
        const old = self.entries[index];
        self.entries[index].setTombstone();
        self.live_count -= 1;
        return old;
    }

    fn findIndex(self: *IBTCCache, key: IBTCKey) ?usize {
        var index = @as(usize, @intCast(key.hash())) & self.mask();
        var probes: usize = 0;
        while (probes < self.entries.len) : (probes += 1) {
            const entry = &self.entries[index];
            switch (entry.state()) {
                .empty => return null,
                .live => if (entry.key().eql(key)) return index,
                .tombstone => {},
            }
            index = (index + 1) & self.mask();
        }
        return null;
    }

    fn findInsertSlot(self: *IBTCCache, key: IBTCKey) ?usize {
        var first_tombstone: ?usize = null;
        var index = @as(usize, @intCast(key.hash())) & self.mask();
        var probes: usize = 0;
        while (probes < self.entries.len) : (probes += 1) {
            const entry = &self.entries[index];
            switch (entry.state()) {
                .empty => return first_tombstone orelse index,
                .tombstone => {
                    if (first_tombstone == null) first_tombstone = index;
                },
                .live => if (entry.key().eql(key)) return index,
            }
            index = (index + 1) & self.mask();
        }
        return first_tombstone;
    }

    fn nextEpoch(self: *IBTCCache) u64 {
        const current = self.epoch;
        self.epoch +%= 1;
        if (self.epoch == 0) self.epoch = 1;
        return current;
    }

    fn mask(self: *const IBTCCache) usize {
        return self.entries.len - 1;
    }
};

fn metadataFor(state: EntryState, flags: u8, epoch: u64) u64 {
    return @as(u64, @intFromEnum(state)) |
        (@as(u64, flags) << METADATA_FLAGS_SHIFT) |
        (epoch << METADATA_EPOCH_SHIFT);
}

fn ceilPowerOfTwo(value: u64) u64 {
    if (value <= 1) return 1;
    var x = value - 1;
    x |= x >> 1;
    x |= x >> 2;
    x |= x >> 4;
    x |= x >> 8;
    x |= x >> 16;
    x |= x >> 32;
    return x + 1;
}

fn noopEvict(_: void, _: *const IBTCEntry) void {}

test "IBTCEntry is cache-line sized" {
    try std.testing.expectEqual(@as(usize, 64), @sizeOf(IBTCEntry));
}

test "IBTC cache inserts resolves and evicts keys" {
    var cache = try IBTCCache.init(std.testing.allocator, 4 * 1024);
    defer cache.deinit();

    const key = IBTCKey.init(0x1000, 0x2000, 1);
    const put_result = try cache.put(key, 0x8000, 7, FLAG_EXECUTABLE, 1);
    try std.testing.expect(put_result.inserted);
    try std.testing.expectEqual(@as(usize, 1), cache.live_count);

    const found = cache.lookup(key) orelse return error.TestFailed;
    try std.testing.expectEqual(@as(u64, 0x8000), found.host_pc);
    found.recordHit(2);
    try std.testing.expectEqual(@as(u64, 1), found.hit_count);

    const evicted = cache.evictKey(key) orelse return error.TestFailed;
    try std.testing.expectEqual(@as(u64, 7), evicted.macho_block_id);
    try std.testing.expect(cache.lookup(key) == null);
}

test "IBTC cache invalidates all entries for a Mach-O block" {
    var cache = try IBTCCache.init(std.testing.allocator, 4 * 1024);
    defer cache.deinit();

    _ = try cache.put(IBTCKey.init(0x1000, 0x2000, 0), 0x8000, 1, 0, 1);
    _ = try cache.put(IBTCKey.init(0x1008, 0x2010, 0), 0x8010, 1, 0, 2);
    _ = try cache.put(IBTCKey.init(0x3000, 0x4000, 0), 0x9000, 2, 0, 3);

    const removed = cache.evictBlock(1);
    try std.testing.expectEqual(@as(usize, 2), removed);
    try std.testing.expectEqual(@as(usize, 1), cache.live_count);
    try std.testing.expect(cache.lookup(IBTCKey.init(0x3000, 0x4000, 0)) != null);
}

test "IBTC cold eviction prefers entries with fewer hits" {
    var cache = try IBTCCache.init(std.testing.allocator, 16 * @sizeOf(IBTCEntry));
    defer cache.deinit();

    const hot = IBTCKey.init(0x10, 0x20, 0);
    const cold = IBTCKey.init(0x30, 0x40, 0);
    _ = try cache.put(hot, 0x1000, 1, 0, 1);
    _ = try cache.put(cold, 0x2000, 1, 0, 2);
    cache.lookup(hot).?.recordHit(3);

    const evicted = cache.evictCold(4) orelse return error.TestFailed;
    try std.testing.expectEqual(cold.branch_guest_pc, evicted.branch_guest_pc);
    try std.testing.expect(cache.lookup(hot) != null);
}
