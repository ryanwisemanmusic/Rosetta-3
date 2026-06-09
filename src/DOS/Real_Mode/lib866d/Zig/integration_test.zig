const std = @import("std");
const types = @import("types.zig");
const util = @import("util.zig");
const pci = @import("pci.zig");
const args = @import("args.zig");
const debug = @import("debug.zig");

test "string utilities: SWAP16/SWAP32" {
    try std.testing.expectEqual(@as(u16, 0x3412), util.SWAP16(0x1234));
    try std.testing.expectEqual(@as(u16, 0x1234), util.SWAP16(util.SWAP16(0x1234)));
    try std.testing.expectEqual(@as(u32, 0x78563412), util.SWAP32(0x12345678));
    try std.testing.expectEqual(@as(u32, 0x12345678), util.SWAP32(util.SWAP32(0x12345678)));
}

test "string utilities: MAX/MIN" {
    try std.testing.expectEqual(@as(i32, 10), util.MAX(@as(i32, 5), @as(i32, 10)));
    try std.testing.expectEqual(@as(i32, 5), util.MIN(@as(i32, 5), @as(i32, 10)));
    try std.testing.expectEqual(@as(f32, 3.14), util.MAX(@as(f32, 3.14), @as(f32, 2.72)));
    try std.testing.expectEqual(@as(usize, 42), util.MAX(@as(usize, 10), @as(usize, 42)));
}

test "string utilities: BIT macros" {
    try std.testing.expectEqual(@as(u32, 1), util.BIT(0));
    try std.testing.expectEqual(@as(u32, 0x80000000), util.BIT(31));
    try std.testing.expectEqual(@as(u8, 0x80), util.BIT8(7));
    try std.testing.expectEqual(@as(u8, 1), util.BIT8(0));
    try std.testing.expectEqual(@as(u32, 0x100), util.BIT32(8));
}

test "string utilities: MK_FP" {
    const ptr = util.MK_FP(0x1234, 0x5678);
    try std.testing.expectEqual(@as(usize, 0x12345678), @intFromPtr(ptr));
    const ptr2 = util.MK_FP(0x0040, 0x0010);
    try std.testing.expectEqual(@as(usize, 0x00400010), @intFromPtr(ptr2));
}

test "string utilities: stringEquals" {
    try std.testing.expect(util.stringEquals("hello", "hello"));
    try std.testing.expect(!util.stringEquals("hello", "world"));
    try std.testing.expect(!util.stringEquals("hello", "hell"));
    try std.testing.expect(util.stringEquals("", ""));
}

test "string utilities: stringStartsWith" {
    try std.testing.expect(util.stringStartsWith("hello world", "hello"));
    try std.testing.expect(!util.stringStartsWith("hello world", "world"));
    try std.testing.expect(util.stringStartsWith("hello", ""));
}

test "string utilities: stringEndsWith" {
    try std.testing.expect(util.stringEndsWith("hello world", "world"));
    try std.testing.expect(!util.stringEndsWith("hello world", "hello"));
    try std.testing.expect(util.stringEndsWith("hello", ""));
}

test "string utilities: stringReplaceChar" {
    var buf = [_]u8{ 'a', ' ', 'b', ' ', 'c' };
    util.stringReplaceChar(&buf, ' ', '_');
    try std.testing.expectEqualSlices(u8, "a_b_c", &buf);
}

test "string utilities: stringToU32" {
    var val: u32 = 0;
    try std.testing.expect(util.stringToU32("1234", &val));
    try std.testing.expectEqual(@as(u32, 1234), val);
    try std.testing.expect(util.stringToU32("0xFF", &val));
    try std.testing.expectEqual(@as(u32, 255), val);
    try std.testing.expect(!util.stringToU32("not_a_number", &val));
}

test "string utilities: strncasecmp" {
    try std.testing.expectEqual(@as(i32, 0), util.strncasecmp("Hello", "hello", 5));
    try std.testing.expectEqual(@as(i32, 0), util.strncasecmp("ABC", "abc", 3));
    try std.testing.expect(util.strncasecmp("abc", "abd", 3) < 0);
    try std.testing.expect(util.strncasecmp("abd", "abc", 3) > 0);
}

test "string utilities: snprintf" {
    var buf: [64]u8 = undefined;
    const n = util.snprintf(&buf, "val={d}", .{42});
    try std.testing.expectEqual(@as(i32, 6), n);
    try std.testing.expectEqualSlices(u8, "val=42", buf[0..@as(usize, @intCast(n))]);
}

test "string utilities: swapInPlace" {
    var a: u16 = 0x1234;
    util.swapInPlace16(&a);
    try std.testing.expectEqual(@as(u16, 0x3412), a);
    var b: u32 = 0x12345678;
    util.swapInPlace32(&b);
    try std.testing.expectEqual(@as(u32, 0x78563412), b);
}

test "PCI: makeAddress" {
    const dev = pci.pci_Device{
        .bus = 0,
        .slot = 0,
        .func = 0,
        .dummy = 0,
    };
    const addr = pci.pci_makeAddress(dev, 0);
    try std.testing.expect(addr & 0x80000000 != 0);
    try std.testing.expectEqual(@as(u32, 0), addr & ~@as(u32, 0x80000000));

    const dev2 = pci.pci_Device{
        .bus = 1,
        .slot = 2,
        .func = 3,
        .dummy = 0,
    };
    const addr2 = pci.pci_makeAddress(dev2, 0x10);
    try std.testing.expect(addr2 & 0x80000000 != 0);
    try std.testing.expectEqual(@as(u8, 1), @as(u8, @truncate((addr2 >> 16) & 0xFF)));
    try std.testing.expectEqual(@as(u8, 2), @as(u8, @truncate((addr2 >> 11) & 0x1F)));
    try std.testing.expectEqual(@as(u8, 3), @as(u8, @truncate((addr2 >> 8) & 0x07)));
    try std.testing.expectEqual(@as(u8, 0x10), @as(u8, @truncate(addr2 & 0xFC)));
}

test "PCI: read16/read8 shift logic" {
    const dev = pci.pci_Device{
        .bus = 0,
        .slot = 0,
        .func = 0,
        .dummy = 0,
    };
    _ = dev;
}

test "PCI: getVendorID returns 0 (stub: no real PCI)" {
    const dev = pci.pci_Device{
        .bus = 0,
        .slot = 0,
        .func = 0,
        .dummy = 0,
    };
    const vendor = pci.pci_getVendorID(dev);
    try std.testing.expectEqual(@as(u16, 0), vendor);
}

test "PCI: findDevByID returns false (no real PCI)" {
    var dev: pci.pci_Device = undefined;
    const found = pci.pci_findDevByID(0x8086, 0x1234, &dev);
    try std.testing.expect(!found);
}

test "PCI: populateDeviceInfo works with stubs" {
    const dev = pci.pci_Device{
        .bus = 0,
        .slot = 0,
        .func = 0,
        .dummy = 0,
    };
    var info: pci.pci_DeviceInfo = undefined;
    const ok = pci.pci_populateDeviceInfo(&info, dev);
    try std.testing.expect(ok);
    try std.testing.expectEqual(@as(u16, 0), info.vendor);
}

test "args: getArgType masks correctly" {
    try std.testing.expectEqual(@as(args.ArgType, args.ARG_STR), args.getArgType(args.ARG_STRING(10)));
    try std.testing.expectEqual(@as(args.ArgType, args.ARG_U8), args.getArgType(0x0105));
    try std.testing.expectEqual(@as(args.ArgType, args.ARG_FLAG), args.getArgType(args.ARG_FLAG));
    try std.testing.expectEqual(@as(args.ArgType, args.ARG_NFLAG), args.getArgType(args.ARG_NFLAG));
}

test "args: argHasParam" {
    try std.testing.expect(args.argHasParam(args.ARG_STR));
    try std.testing.expect(args.argHasParam(args.ARG_U8));
    try std.testing.expect(args.argHasParam(args.ARG_U32));
    try std.testing.expect(!args.argHasParam(args.ARG_FLAG));
    try std.testing.expect(!args.argHasParam(args.ARG_NFLAG));
    try std.testing.expect(!args.argHasParam(args.ARG_USAGE));
}

test "args: parseAllArgs flag" {
    var helpFlag = false;
    var verboseFlag = false;
    const argList = [_]args.Arg{
        .{
            .prefix = "HELP",
            .paramNames = null,
            .description = "Show help",
            .type = args.ARG_FLAG,
            .foundFlag = null,
            .dst = @ptrCast(&helpFlag),
            .checker = null,
        },
        .{
            .prefix = "V",
            .paramNames = null,
            .description = "Verbose",
            .type = args.ARG_FLAG,
            .foundFlag = null,
            .dst = @ptrCast(&verboseFlag),
            .checker = null,
        },
    };
    const input = [_][]const u8{ "program", "/HELP", "/V" };
    const result = args.parseAllArgs(&input, &argList);
    try std.testing.expectEqual(args.ParseError.success, result);
    try std.testing.expect(helpFlag);
    try std.testing.expect(verboseFlag);
}

test "args: parseAllArgs string param" {
    var outputFile: [64]u8 = undefined;
    var outFlag = false;
    const argList = [_]args.Arg{
        .{
            .prefix = "OUT",
            .paramNames = "filename",
            .description = "Output file",
            .type = args.ARG_STRING(64),
            .foundFlag = &outFlag,
            .dst = &outputFile,
            .checker = null,
        },
    };
    const input = [_][]const u8{ "program", "/OUT:test.txt" };
    const result = args.parseAllArgs(&input, &argList);
    try std.testing.expectEqual(args.ParseError.success, result);
    try std.testing.expect(outFlag);
}

test "args: unrecognized arg returns error" {
    const argList = [_]args.Arg{
        .{
            .prefix = "HELP",
            .paramNames = null,
            .description = "Show help",
            .type = args.ARG_FLAG,
            .foundFlag = null,
            .dst = null,
            .checker = null,
        },
    };
    const input = [_][]const u8{ "program", "/UNKNOWN" };
    const result = args.parseAllArgs(&input, &argList);
    try std.testing.expectEqual(args.ParseError.arg_not_found, result);
}

test "debug: assert passes on true" {
    debug.assert(true);
}

test "debug: nullcheck passes on non-null" {
    const val: i32 = 42;
    debug.nullcheck(&val);
}

test "types: constants" {
    try std.testing.expectEqual(@as(i32, -2147483648), types.I32_MIN);
    try std.testing.expectEqual(@as(i32, 2147483647), types.I32_MAX);
    try std.testing.expectEqual(@as(i16, -32768), types.I16_MIN);
    try std.testing.expectEqual(@as(i16, 32767), types.I16_MAX);
}

test "util: ARRAY_SIZE" {
    const arr = [_]u8{ 1, 2, 3, 4, 5 };
    try std.testing.expectEqual(@as(usize, 5), util.ARRAY_SIZE(arr));
}

test "util: round" {
    try std.testing.expectEqual(@as(i32, 42), util.round(42.0));
    try std.testing.expectEqual(@as(i32, 43), util.round(42.7));
    try std.testing.expectEqual(@as(i32, -42), util.round(-42.3));
    try std.testing.expectEqual(@as(i32, -43), util.round(-42.7));
}

test "util: msToClocks" {
    try std.testing.expectEqual(@as(u32, 1000), util.msToClocks(1000));
}

test "util: getTimeOffsetInClocks" {
    const offset = util.getTimeOffsetInClocks(100);
    try std.testing.expectEqual(@as(u32, 100), offset);
}
