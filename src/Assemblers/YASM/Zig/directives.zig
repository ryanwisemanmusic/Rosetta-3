const std = @import("std");

pub const Directive = enum(u16) {
    unknown = 0,
    absolute,
    @"align",
    bits,
    common,
    cpu,
    default,
    @"extern",
    global,
    org,
    section,
    segment,
    warning,

    pub fn fromString(name: []const u8) ?Directive {
        inline for (std.meta.fields(Directive)) |field| {
            if (field.value == 0) continue;
            if (std.ascii.eqlIgnoreCase(name, field.name)) return @field(Directive, field.name);
        }
        return null;
    }
};

pub const DataDirective = enum(u8) {
    db,
    dw,
    dd,
    dq,
    ddq,
    resb,
    resw,
    resd,
    resq,
    resdq,

    pub fn fromString(name: []const u8) ?DataDirective {
        inline for (std.meta.fields(DataDirective)) |field| {
            if (std.ascii.eqlIgnoreCase(name, field.name)) return @field(DataDirective, field.name);
        }
        return null;
    }

    pub fn byteSize(self: DataDirective) u8 {
        return switch (self) {
            .db, .resb => 1,
            .dw, .resw => 2,
            .dd, .resd => 4,
            .dq, .resq => 8,
            .ddq, .resdq => 16,
        };
    }

    pub fn reservesSpace(self: DataDirective) bool {
        return switch (self) {
            .resb, .resw, .resd, .resq, .resdq => true,
            else => false,
        };
    }
};

pub const PreprocDirective = enum(u16) {
    define,
    undef,
    include,
    macro,
    imacro,
    endm,
    ifdef,
    ifndef,
    @"if",
    elif,
    else_dir,
    endif,
    error_dir,
    warning_dir,
    fatal_dir,

    pub fn fromString(name: []const u8) ?PreprocDirective {
        if (std.ascii.eqlIgnoreCase(name, "else")) return .else_dir;
        if (std.ascii.eqlIgnoreCase(name, "error")) return .error_dir;
        if (std.ascii.eqlIgnoreCase(name, "warning")) return .warning_dir;
        if (std.ascii.eqlIgnoreCase(name, "fatal")) return .fatal_dir;
        inline for (std.meta.fields(PreprocDirective)) |field| {
            if (std.ascii.eqlIgnoreCase(name, field.name)) return @field(PreprocDirective, field.name);
        }
        return null;
    }
};

pub fn firstToken(line: []const u8) []const u8 {
    const trimmed = std.mem.trim(u8, line, " \t\r\n");
    var end: usize = 0;
    while (end < trimmed.len) : (end += 1) {
        switch (trimmed[end]) {
            ' ', '\t', ',', ':' => break,
            else => {},
        }
    }
    return trimmed[0..end];
}

test "directive lookup" {
    try std.testing.expectEqual(Directive.section, Directive.fromString("SECTION").?);
    try std.testing.expectEqual(Directive.bits, Directive.fromString("bits").?);
    try std.testing.expect(Directive.fromString("not-a-directive") == null);
}

test "data directive sizes" {
    try std.testing.expectEqual(@as(u8, 1), DataDirective.db.byteSize());
    try std.testing.expectEqual(@as(u8, 16), DataDirective.ddq.byteSize());
    try std.testing.expect(DataDirective.resq.reservesSpace());
}
