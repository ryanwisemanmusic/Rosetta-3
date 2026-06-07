const std = @import("std");
const macho = @import("macho_parser.zig");
const fat = @import("fat_binary.zig");
const bundle = @import("bundle_parser.zig");
const plist = @import("plist_parser.zig");
const nib = @import("nib_converter.zig");
const icns = @import("icns_parser.zig");
const codesign = @import("codesign_parser.zig");
const scpt = @import("scpt_parser.zig");
const rsrc = @import("rsrc_parser.zig");
const strings = @import("strings_parser.zig");

pub const FileCategory = enum {
    macho_32_bit,
    macho_64_bit,
    universal_binary,
    plist,
    nib_archive,
    icns_icon,
    codesignature,
    applescript,
    resource_fork,
    strings_file,
    image,
    text,
    unknown,
};

pub const AnalyzedFile = struct {
    path: []const u8,
    category: FileCategory,
    size: u64,
    needs_conversion: bool,
    details: union {
        macho: ?macho.MachImage,
        universal: ?fat.UniversalBinary,
        icon: ?icns.IconFamily,
        codesig: ?codesign.CodeDirectory,
    },
    allocator: std.mem.Allocator,

    pub fn deinit(self: *AnalyzedFile) void {
        self.allocator.free(self.path);
        if (self.details == .macho and self.details.macho) |*m| m.deinit();
        if (self.details == .universal and self.details.universal) |*u| u.deinit();
        if (self.details == .icon and self.details.icon) |*i| i.deinit();
    }
};

pub const AppAnalysis = struct {
    bundle_layout: bundle.BundleLayout,
    files: []AnalyzedFile,
    allocator: std.mem.Allocator,

    pub fn deinit(self: *AppAnalysis) void {
        self.bundle_layout.deinit();
        for (self.files) |*f| f.deinit();
        self.allocator.free(self.files);
    }

    pub fn count32BitExecutables(self: AppAnalysis) usize {
        var count: usize = 0;
        for (self.files) |f| {
            if (f.category == .macho_32_bit) count += 1;
        }
        return count;
    }

    pub fn countNeedingConversion(self: AppAnalysis) usize {
        var count: usize = 0;
        for (self.files) |f| {
            if (f.needs_conversion) count += 1;
        }
        return count;
    }
};

pub fn classifyFile(path: []const u8) FileCategory {
    if (std.mem.endsWith(u8, path, ".plist")) return .plist;
    if (std.mem.endsWith(u8, path, ".nib")) return .nib_archive;
    if (std.mem.endsWith(u8, path, ".xib")) return .plist;
    if (std.mem.endsWith(u8, path, ".icns")) return .icns_icon;
    if (std.mem.endsWith(u8, path, ".scpt")) return .applescript;
    if (std.mem.endsWith(u8, path, ".rsrc")) return .resource_fork;
    if (std.mem.endsWith(u8, path, ".strings")) return .strings_file;
    if (std.mem.endsWith(u8, path, ".png")) return .image;
    if (std.mem.endsWith(u8, path, ".jpg") or std.mem.endsWith(u8, path, ".jpeg")) return .image;
    if (std.mem.endsWith(u8, path, ".tiff") or std.mem.endsWith(u8, path, ".tif")) return .image;
    if (std.mem.endsWith(u8, path, ".pdf")) return .image;
    if (std.mem.endsWith(u8, path, ".html") or std.mem.endsWith(u8, path, ".htm")) return .text;
    if (std.mem.endsWith(u8, path, ".css")) return .text;
    if (std.mem.endsWith(u8, path, ".js")) return .text;
    if (std.mem.endsWith(u8, path, ".txt")) return .text;
    if (std.mem.endsWith(u8, path, ".rtf")) return .text;
    if (std.mem.endsWith(u8, path, ".xml")) return .text;
    if (std.mem.endsWith(u8, path, ".json")) return .text;
    if (std.mem.endsWith(u8, path, "_CodeSignature") or std.mem.endsWith(u8, path, "CodeResources")) return .codesignature;
    if (std.mem.endsWith(u8, path, "PkgInfo")) return .text;
    return .unknown;
}

pub fn analyzeApp(allocator: std.mem.Allocator, app_path: []const u8) !AppAnalysis {
    const bl = try bundle.parseAppBundle(allocator, app_path);

    var files: std.ArrayList(AnalyzedFile) = .empty;
    errdefer {
        for (files.items) |*f| f.deinit();
        files.deinit(allocator);
    }

    var dir = try std.fs.cwd().openDir(app_path, .{ .iterate = true });
    defer dir.close();

    var walker = try dir.walk(allocator);
    defer walker.deinit();

    while (try walker.next()) |entry| {
        if (entry.kind == .file) {
            const full_path = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ app_path, entry.path });
            errdefer allocator.free(full_path);

            const cat = classifyFile(entry.path);
            const size: u64 = blk: {
                const stat = dir.statFile(entry.path) catch break :blk 0;
                break :blk @intCast(stat.size);
            };

            var needs_conversion = false;
            switch (cat) {
                .macho_32_bit, .nib_archive, .resource_fork => needs_conversion = true,
                .universal_binary => needs_conversion = true,
                else => {},
            }

            try files.append(allocator, .{
                .path = full_path,
                .category = cat,
                .size = size,
                .needs_conversion = needs_conversion,
                .details = .{ .macho = null },
                .allocator = allocator,
            });
        }
    }

    return AppAnalysis{
        .bundle_layout = bl,
        .files = try files.toOwnedSlice(allocator),
        .allocator = allocator,
    };
}

test "classify by extension" {
    try std.testing.expectEqual(FileCategory.plist, classifyFile("Info.plist"));
    try std.testing.expectEqual(FileCategory.nib_archive, classifyFile("MainMenu.nib"));
    try std.testing.expectEqual(FileCategory.icns_icon, classifyFile("app.icns"));
    try std.testing.expectEqual(FileCategory.applescript, classifyFile("script.scpt"));
    try std.testing.expectEqual(FileCategory.resource_fork, classifyFile("data.rsrc"));
    try std.testing.expectEqual(FileCategory.image, classifyFile("icon.png"));
    try std.testing.expectEqual(FileCategory.text, classifyFile("readme.txt"));
    try std.testing.expectEqual(FileCategory.unknown, classifyFile("data.bin"));
}

test "classify Applescript and resource fork" {
    try std.testing.expectEqual(FileCategory.applescript, classifyFile("script.scpt"));
    try std.testing.expectEqual(FileCategory.resource_fork, classifyFile("data.rsrc"));
}
