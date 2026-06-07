const std = @import("std");

pub const BundleType = enum {
    app,
    framework,
    bblm,
    kext,
    unknown,
};

pub const BundleKind = struct {
    bundle_type: BundleType,
    name: []const u8,
    path: []const u8,
    info_plist_path: ?[]const u8,
    executable_path: ?[]const u8,
    resources_path: ?[]const u8,
    frameworks_path: ?[]const u8,
    plugins_path: ?[]const u8,
    helpers_path: ?[]const u8,
    allocator: std.mem.Allocator,

    pub fn deinit(self: *BundleKind) void {
        self.allocator.free(self.name);
        self.allocator.free(self.path);
        if (self.info_plist_path) |p| self.allocator.free(p);
        if (self.executable_path) |p| self.allocator.free(p);
        if (self.resources_path) |p| self.allocator.free(p);
        if (self.frameworks_path) |p| self.allocator.free(p);
        if (self.plugins_path) |p| self.allocator.free(p);
        if (self.helpers_path) |p| self.allocator.free(p);
    }
};

pub const BundleLayout = struct {
    bundles: []BundleKind,
    allocator: std.mem.Allocator,

    pub fn deinit(self: *BundleLayout) void {
        for (self.bundles) |*b| b.deinit();
        self.allocator.free(self.bundles);
    }

    pub fn findMainExecutable(self: BundleLayout) ?[]const u8 {
        for (self.bundles) |b| {
            if (b.bundle_type == .app) return b.executable_path;
        }
        return null;
    }

    pub fn findPlugins(self: BundleLayout, allocator: std.mem.Allocator) ![][]const u8 {
        var list: std.ArrayList([]const u8) = .empty;
        errdefer list.deinit(allocator);
        for (self.bundles) |b| {
            if (b.bundle_type == .bblm) {
                if (b.executable_path) |ep| try list.append(allocator, ep);
            }
        }
        return list.toOwnedSlice(allocator);
    }

    pub fn findHelpers(self: BundleLayout, allocator: std.mem.Allocator) ![][]const u8 {
        var list: std.ArrayList([]const u8) = .empty;
        errdefer list.deinit(allocator);
        for (self.bundles) |b| {
            if (b.bundle_type == .app and b.helpers_path) |hp| {
                try list.append(allocator, hp);
            }
        }
        return list.toOwnedSlice(allocator);
    }
};

pub fn inferBundleType(name: []const u8) BundleType {
    if (std.mem.endsWith(u8, name, ".app")) return .app;
    if (std.mem.endsWith(u8, name, ".framework")) return .framework;
    if (std.mem.endsWith(u8, name, ".bblm")) return .bblm;
    if (std.mem.endsWith(u8, name, ".kext")) return .kext;
    return .unknown;
}

pub fn detectBundle(allocator: std.mem.Allocator, base_path: []const u8) !BundleKind {
    const name = std.fs.path.basename(base_path);
    const bundle_type = inferBundleType(name);

    switch (bundle_type) {
        .app => {
            const info_plist = try std.fmt.allocPrint(allocator, "{s}/Contents/Info.plist", .{base_path});
            const executable = try std.fmt.allocPrint(allocator, "{s}/Contents/MacOS/{s}", .{ base_path, name[0 .. name.len - 4] });
            const resources = try std.fmt.allocPrint(allocator, "{s}/Contents/Resources", .{base_path});
            const frameworks = try std.fmt.allocPrint(allocator, "{s}/Contents/Frameworks", .{base_path});
            const plugins = try std.fmt.allocPrint(allocator, "{s}/Contents/PlugIns", .{base_path});
            const helpers = try std.fmt.allocPrint(allocator, "{s}/Contents/Helpers", .{base_path});
            return BundleKind{
                .bundle_type = bundle_type,
                .name = try allocator.dupe(u8, name),
                .path = try allocator.dupe(u8, base_path),
                .info_plist_path = info_plist,
                .executable_path = executable,
                .resources_path = resources,
                .frameworks_path = frameworks,
                .plugins_path = plugins,
                .helpers_path = helpers,
                .allocator = allocator,
            };
        },
        .framework => {
            const info_plist = try std.fmt.allocPrint(allocator, "{s}/Versions/A/Resources/Info.plist", .{base_path});
            const executable = try std.fmt.allocPrint(allocator, "{s}/Versions/A/{s}", .{ base_path, name[0 .. name.len - 10] });
            return BundleKind{
                .bundle_type = bundle_type,
                .name = try allocator.dupe(u8, name),
                .path = try allocator.dupe(u8, base_path),
                .info_plist_path = info_plist,
                .executable_path = executable,
                .resources_path = null,
                .frameworks_path = null,
                .plugins_path = null,
                .helpers_path = null,
                .allocator = allocator,
            };
        },
        .bblm => {
            const info_plist = try std.fmt.allocPrint(allocator, "{s}/Contents/Info.plist", .{base_path});
            const executable = try std.fmt.allocPrint(allocator, "{s}/Contents/MacOS/{s}", .{ base_path, name[0 .. name.len - 5] });
            return BundleKind{
                .bundle_type = bundle_type,
                .name = try allocator.dupe(u8, name),
                .path = try allocator.dupe(u8, base_path),
                .info_plist_path = info_plist,
                .executable_path = executable,
                .resources_path = null,
                .frameworks_path = null,
                .plugins_path = null,
                .helpers_path = null,
                .allocator = allocator,
            };
        },
        else => {
            return BundleKind{
                .bundle_type = bundle_type,
                .name = try allocator.dupe(u8, name),
                .path = try allocator.dupe(u8, base_path),
                .info_plist_path = null,
                .executable_path = null,
                .resources_path = null,
                .frameworks_path = null,
                .plugins_path = null,
                .helpers_path = null,
                .allocator = allocator,
            };
        },
    }
}

pub fn parseAppBundle(allocator: std.mem.Allocator, base_path: []const u8) !BundleLayout {
    var bundles: std.ArrayList(BundleKind) = .empty;
    errdefer {
        for (bundles.items) |*b| b.deinit();
        bundles.deinit(allocator);
    }

    const main_bundle = try detectBundle(allocator, base_path);
    try bundles.append(allocator, main_bundle);

    // Discover sub-bundles
    const subdirs_to_check = [_][]const u8{ "Frameworks", "PlugIns/Language Modules", "Helpers" };
    for (subdirs_to_check) |subdir| {
        const check_path = try std.fmt.allocPrint(allocator, "{s}/Contents/{s}", .{ base_path, subdir });
        defer allocator.free(check_path);

        var dir = std.fs.cwd().openDir(check_path, .{ .iterate = true }) catch |err| switch (err) {
            error.FileNotFound, error.NotDir => continue,
            else => |e| return e,
        };
        defer dir.close();

        var it = dir.iterate();
        while (it.next() catch break) |entry| {
            if (entry.kind != .directory) continue;
            const full_path = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ check_path, entry.name });
            const sub_bundle = detectBundle(allocator, full_path) catch |err| switch (err) {
                error.OutOfMemory => return error.OutOfMemory,
                else => {
                    allocator.free(full_path);
                    continue;
                },
            };
            try bundles.append(allocator, sub_bundle);
        }
    }

    return BundleLayout{
        .bundles = try bundles.toOwnedSlice(allocator),
        .allocator = allocator,
    };
}

test "infer bundle types" {
    try std.testing.expectEqual(BundleType.app, inferBundleType("TextWrangler.app"));
    try std.testing.expectEqual(BundleType.framework, inferBundleType("UpdateKit.framework"));
    try std.testing.expectEqual(BundleType.bblm, inferBundleType("CSS.bblm"));
    try std.testing.expectEqual(BundleType.unknown, inferBundleType("readme.txt"));
}

test "detect bundle structure" {
    var bundle = try detectBundle(std.testing.allocator, "TextWrangler.app");
    defer bundle.deinit();
    try std.testing.expectEqual(BundleType.app, bundle.bundle_type);
    try std.testing.expectEqualStrings("TextWrangler.app", bundle.name);
    try std.testing.expect(bundle.info_plist_path != null);
    try std.testing.expect(bundle.executable_path != null);
}
