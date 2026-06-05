const std = @import("std");
const builtin = @import("builtin");

pub const KiB: u64 = 1024;
pub const MiB: u64 = KiB * 1024;
pub const GiB: u64 = MiB * 1024;

pub const SOURCE_SYSCTL: u32 = 1 << 0;
pub const SOURCE_CPU_FAMILY: u32 = 1 << 1;
pub const SOURCE_BRAND_STRING: u32 = 1 << 2;
pub const SOURCE_MODEL_STRING: u32 = 1 << 3;
pub const SOURCE_FALLBACK: u32 = 1 << 31;

pub const ChipGeneration = enum(u8) {
    unknown = 0,
    m1 = 1,
    m2 = 2,
    m3 = 3,
    m4 = 4,
    m5 = 5,
    future_apple_silicon = 250,
    intel_or_other = 251,
};

pub const HardwareProfile = extern struct {
    l1i_bytes: u64,
    l1d_bytes: u64,
    l2_bytes: u64,
    l3_slc_bytes: u64,
    ram_bytes: u64,
    logical_cpus: u32,
    performance_cpus: u32,
    efficiency_cpus: u32,
    cpu_family: u32,
    generation: u8,
    brand_len: u8,
    model_len: u8,
    _pad: [5]u8,
    source_flags: u32,
    brand: [64]u8,
    model: [64]u8,

    pub fn initFallback() HardwareProfile {
        var profile = HardwareProfile{
            .l1i_bytes = 128 * KiB,
            .l1d_bytes = 64 * KiB,
            .l2_bytes = 4 * MiB,
            .l3_slc_bytes = 8 * MiB,
            .ram_bytes = 8 * GiB,
            .logical_cpus = 8,
            .performance_cpus = 4,
            .efficiency_cpus = 4,
            .cpu_family = 0,
            .generation = @intFromEnum(ChipGeneration.unknown),
            .brand_len = 0,
            .model_len = 0,
            ._pad = [_]u8{0} ** 5,
            .source_flags = SOURCE_FALLBACK,
            .brand = [_]u8{0} ** 64,
            .model = [_]u8{0} ** 64,
        };
        profile.setBrand("Apple Silicon");
        profile.setModel("unknown-mac");
        return profile;
    }

    pub fn generationTag(self: *const HardwareProfile) ChipGeneration {
        return @enumFromInt(self.generation);
    }

    pub fn setGeneration(self: *HardwareProfile, generation: ChipGeneration) void {
        self.generation = @intFromEnum(generation);
    }

    pub fn brandSlice(self: *const HardwareProfile) []const u8 {
        return self.brand[0..self.brand_len];
    }

    pub fn modelSlice(self: *const HardwareProfile) []const u8 {
        return self.model[0..self.model_len];
    }

    pub fn setBrand(self: *HardwareProfile, value: []const u8) void {
        self.brand_len = copyFixed(&self.brand, value);
    }

    pub fn setModel(self: *HardwareProfile, value: []const u8) void {
        self.model_len = copyFixed(&self.model, value);
    }
};

pub const BudgetOptions = struct {
    min_software_l3_bytes: u64 = 16 * MiB,
    max_software_l3_bytes: u64 = 0,
    ibtc_share_percent: u8 = 25,
    dyld_table_share_percent: u8 = 12,
};

pub const CacheBudget = extern struct {
    l1i_translation_window_bytes: u64,
    l1d_metadata_window_bytes: u64,
    l2_block_window_bytes: u64,
    software_l3_min_bytes: u64,
    software_l3_target_bytes: u64,
    macho_block_bytes: u64,
    ibtc_bytes: u64,
    dyld_table_bytes: u64,
    eviction_batch_bytes: u64,
    ram_budget_ceiling_bytes: u64,
};

pub fn detectHostProfile() HardwareProfile {
    var profile = HardwareProfile.initFallback();

    if (builtin.target.os.tag == .macos) {
        if (darwinSysctlU64("hw.l1icachesize")) |value| {
            profile.l1i_bytes = value;
            profile.source_flags |= SOURCE_SYSCTL;
        }
        if (darwinSysctlU64("hw.l1dcachesize")) |value| {
            profile.l1d_bytes = value;
            profile.source_flags |= SOURCE_SYSCTL;
        }
        if (darwinSysctlU64("hw.l2cachesize")) |value| {
            profile.l2_bytes = value;
            profile.source_flags |= SOURCE_SYSCTL;
        }
        if (darwinSysctlU64("hw.l3cachesize")) |value| {
            profile.l3_slc_bytes = value;
            profile.source_flags |= SOURCE_SYSCTL;
        }
        if (darwinSysctlU64("hw.memsize")) |value| {
            profile.ram_bytes = value;
            profile.source_flags |= SOURCE_SYSCTL;
        }
        if (darwinSysctlU64("hw.logicalcpu")) |value| {
            profile.logical_cpus = narrowU32(value);
            profile.source_flags |= SOURCE_SYSCTL;
        }
        if (darwinSysctlU64("hw.perflevel0.logicalcpu")) |value| {
            profile.performance_cpus = narrowU32(value);
            profile.source_flags |= SOURCE_SYSCTL;
        }
        if (darwinSysctlU64("hw.perflevel1.logicalcpu")) |value| {
            profile.efficiency_cpus = narrowU32(value);
            profile.source_flags |= SOURCE_SYSCTL;
        }

        if (darwinSysctlString("machdep.cpu.brand_string", &profile.brand)) |len| {
            profile.brand_len = len;
            profile.source_flags |= SOURCE_BRAND_STRING;
        }
        if (darwinSysctlString("hw.model", &profile.model)) |len| {
            profile.model_len = len;
            profile.source_flags |= SOURCE_MODEL_STRING;
        }
        if (darwinSysctlU32("hw.cpufamily")) |family| {
            profile.cpu_family = family;
            profile.source_flags |= SOURCE_CPU_FAMILY;
        }
    } else {
        profile.setGeneration(.intel_or_other);
    }

    normalizeProfile(&profile);
    return profile;
}

pub fn deriveDefaultBudget(profile: HardwareProfile) CacheBudget {
    return deriveBudget(profile, .{});
}

pub fn deriveBudget(profile: HardwareProfile, options: BudgetOptions) CacheBudget {
    const slc_source = largestNonZero(profile.l3_slc_bytes, profile.l2_bytes);
    const slc = if (slc_source == 0) 8 * MiB else slc_source;
    const ram = if (profile.ram_bytes == 0) 8 * GiB else profile.ram_bytes;

    var ram_ceiling = ram / 128;
    if (ram_ceiling < options.min_software_l3_bytes) ram_ceiling = options.min_software_l3_bytes;
    if (options.max_software_l3_bytes != 0 and ram_ceiling > options.max_software_l3_bytes) {
        ram_ceiling = options.max_software_l3_bytes;
    }

    var software_min = ceilPowerOfTwo(saturatingMul(slc, 4));
    if (software_min < options.min_software_l3_bytes) software_min = options.min_software_l3_bytes;
    if (software_min > ram_ceiling) software_min = ram_ceiling;

    var software_target = ceilPowerOfTwo(saturatingMul(slc, 8));
    if (software_target < software_min) software_target = software_min;
    if (software_target > ram_ceiling) software_target = ram_ceiling;

    const ibtc_share = boundedPercent(options.ibtc_share_percent, 10, 50);
    const dyld_share = boundedPercent(options.dyld_table_share_percent, 4, 30);
    var ibtc_bytes = (software_target * ibtc_share) / 100;
    var dyld_table_bytes = (software_target * dyld_share) / 100;
    if (ibtc_bytes < 1 * MiB) ibtc_bytes = 1 * MiB;
    if (dyld_table_bytes < 1 * MiB) dyld_table_bytes = 1 * MiB;
    if (ibtc_bytes + dyld_table_bytes > software_target) {
        ibtc_bytes = software_target / 4;
        dyld_table_bytes = software_target / 8;
    }
    const macho_block_bytes = software_target - ibtc_bytes - dyld_table_bytes;

    return CacheBudget{
        .l1i_translation_window_bytes = ceilPowerOfTwo(@max(profile.l1i_bytes * 2, 256 * KiB)),
        .l1d_metadata_window_bytes = ceilPowerOfTwo(@max(profile.l1d_bytes * 2, 128 * KiB)),
        .l2_block_window_bytes = ceilPowerOfTwo(@max(profile.l2_bytes * 2, 4 * MiB)),
        .software_l3_min_bytes = software_min,
        .software_l3_target_bytes = software_target,
        .macho_block_bytes = macho_block_bytes,
        .ibtc_bytes = ibtc_bytes,
        .dyld_table_bytes = dyld_table_bytes,
        .eviction_batch_bytes = @max(software_target / 32, 1 * MiB),
        .ram_budget_ceiling_bytes = ram_ceiling,
    };
}

pub fn ceilPowerOfTwo(value: u64) u64 {
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

fn normalizeProfile(profile: *HardwareProfile) void {
    if (profile.l1i_bytes == 0) profile.l1i_bytes = 128 * KiB;
    if (profile.l1d_bytes == 0) profile.l1d_bytes = 64 * KiB;
    if (profile.l2_bytes == 0) profile.l2_bytes = 4 * MiB;
    if (profile.l3_slc_bytes == 0) profile.l3_slc_bytes = 8 * MiB;
    if (profile.ram_bytes == 0) profile.ram_bytes = 8 * GiB;
    if (profile.logical_cpus == 0) profile.logical_cpus = @max(profile.performance_cpus + profile.efficiency_cpus, 1);

    const brand_generation = classifyGenerationFromBrand(profile.brandSlice());
    if (brand_generation) |generation| {
        profile.setGeneration(generation);
        return;
    }

    const family_generation = classifyGenerationFromCpuFamily(profile.cpu_family);
    if (family_generation) |generation| {
        profile.setGeneration(generation);
        return;
    }

    if (builtin.target.cpu.arch == .aarch64 and builtin.target.os.tag == .macos) {
        profile.setGeneration(.future_apple_silicon);
    }
}

fn classifyGenerationFromBrand(brand: []const u8) ?ChipGeneration {
    var i: usize = 0;
    while (i < brand.len) : (i += 1) {
        if (brand[i] != 'M') continue;
        if (i + 1 >= brand.len or !std.ascii.isDigit(brand[i + 1])) continue;

        var value: u8 = 0;
        var j = i + 1;
        while (j < brand.len and std.ascii.isDigit(brand[j])) : (j += 1) {
            value = std.math.mul(u8, value, 10) catch return .future_apple_silicon;
            value = std.math.add(u8, value, brand[j] - '0') catch return .future_apple_silicon;
        }
        return switch (value) {
            1 => .m1,
            2 => .m2,
            3 => .m3,
            4 => .m4,
            5 => .m5,
            else => .future_apple_silicon,
        };
    }
    return null;
}

fn classifyGenerationFromCpuFamily(cpu_family: u32) ?ChipGeneration {
    return switch (cpu_family) {
        0x1b588bb3 => .m1, // Firestorm/Icestorm
        0xda33d83d => .m2, // Blizzard/Avalanche
        0x8765edea => .m3, // Everest/Sawtooth
        0x2876f5b5,
        0xfa33415e,
        0x5f4dea93,
        0x72015832,
        0x6f5129ac,
        0x17d5b93a,
        0x75d4acb9,
        0x204526d0,
        => .future_apple_silicon,
        else => null,
    };
}

fn darwinSysctlU64(name: [*:0]const u8) ?u64 {
    if (builtin.target.os.tag != .macos) return null;

    var value64: u64 = 0;
    var len64: usize = @sizeOf(u64);
    switch (std.posix.errno(std.posix.system.sysctlbyname(name, &value64, &len64, null, 0))) {
        .SUCCESS => return value64,
        .FAULT => unreachable,
        else => {},
    }

    var value32: u32 = 0;
    var len32: usize = @sizeOf(u32);
    switch (std.posix.errno(std.posix.system.sysctlbyname(name, &value32, &len32, null, 0))) {
        .SUCCESS => return value32,
        .FAULT => unreachable,
        else => return null,
    }
}

fn darwinSysctlU32(name: [*:0]const u8) ?u32 {
    const value = darwinSysctlU64(name) orelse return null;
    return narrowU32(value);
}

fn darwinSysctlString(name: [*:0]const u8, dest: *[64]u8) ?u8 {
    if (builtin.target.os.tag != .macos) return null;

    @memset(dest, 0);
    var len: usize = dest.len;
    switch (std.posix.errno(std.posix.system.sysctlbyname(name, dest, &len, null, 0))) {
        .SUCCESS => {
            const bounded = @min(len, dest.len);
            const nul = std.mem.indexOfScalar(u8, dest[0..bounded], 0) orelse bounded;
            return @intCast(nul);
        },
        .FAULT => unreachable,
        else => return null,
    }
}

fn copyFixed(dest: *[64]u8, value: []const u8) u8 {
    @memset(dest, 0);
    const len = @min(value.len, dest.len);
    @memcpy(dest[0..len], value[0..len]);
    return @intCast(len);
}

fn largestNonZero(a: u64, b: u64) u64 {
    if (a == 0) return b;
    if (b == 0) return a;
    return @max(a, b);
}

fn saturatingMul(value: u64, multiplier: u64) u64 {
    return std.math.mul(u64, value, multiplier) catch std.math.maxInt(u64);
}

fn boundedPercent(value: u8, low: u8, high: u8) u64 {
    return @intCast(@min(@max(value, low), high));
}

fn narrowU32(value: u64) u32 {
    return if (value > std.math.maxInt(u32)) std.math.maxInt(u32) else @intCast(value);
}

test "budget follows adaptive SLC and RAM table" {
    var profile = HardwareProfile.initFallback();

    profile.l3_slc_bytes = 8 * MiB;
    profile.ram_bytes = 8 * GiB;
    var budget = deriveDefaultBudget(profile);
    try std.testing.expectEqual(32 * MiB, budget.software_l3_min_bytes);
    try std.testing.expectEqual(64 * MiB, budget.software_l3_target_bytes);

    profile.l3_slc_bytes = 12 * MiB;
    profile.ram_bytes = 16 * GiB;
    budget = deriveDefaultBudget(profile);
    try std.testing.expectEqual(64 * MiB, budget.software_l3_min_bytes);
    try std.testing.expectEqual(128 * MiB, budget.software_l3_target_bytes);

    profile.l3_slc_bytes = 24 * MiB;
    profile.ram_bytes = 32 * GiB;
    budget = deriveDefaultBudget(profile);
    try std.testing.expectEqual(128 * MiB, budget.software_l3_min_bytes);
    try std.testing.expectEqual(256 * MiB, budget.software_l3_target_bytes);

    profile.l3_slc_bytes = 48 * MiB;
    profile.ram_bytes = 64 * GiB;
    budget = deriveDefaultBudget(profile);
    try std.testing.expectEqual(256 * MiB, budget.software_l3_min_bytes);
    try std.testing.expectEqual(512 * MiB, budget.software_l3_target_bytes);
}

test "brand string classifies Apple M generation" {
    var profile = HardwareProfile.initFallback();
    profile.setBrand("Apple M2 Max");
    normalizeProfile(&profile);
    try std.testing.expectEqual(ChipGeneration.m2, profile.generationTag());

    profile.setBrand("Apple M5 Ultra");
    profile.setGeneration(.unknown);
    normalizeProfile(&profile);
    try std.testing.expectEqual(ChipGeneration.m5, profile.generationTag());

    profile.setBrand("Apple M-Unknown");
    profile.setGeneration(.unknown);
    normalizeProfile(&profile);
    try std.testing.expectEqual(ChipGeneration.future_apple_silicon, profile.generationTag());
}

test "fallback profile remains usable without sysctl" {
    const profile = HardwareProfile.initFallback();
    const budget = deriveDefaultBudget(profile);
    try std.testing.expect(profile.l1i_bytes >= 128 * KiB);
    try std.testing.expect(profile.l1d_bytes >= 64 * KiB);
    try std.testing.expect(budget.ibtc_bytes > 0);
    try std.testing.expect(budget.macho_block_bytes > budget.ibtc_bytes);
}
