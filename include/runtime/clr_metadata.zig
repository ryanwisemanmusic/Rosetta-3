const std = @import("std");
const clr_format = @import("clr_pe_format.zig");

const Allocator = std.mem.Allocator;

// Helper: read little-endian integer
fn readIntLE(comptime T: type, data: []const u8, offset: u32) T {
    const bytes = @sizeOf(T);
    var result: T = 0;
    inline for (0..bytes) |i| {
        result |= (@as(T, data[offset + i]) << (i * 8));
    }
    return result;
}

// Error types for metadata parsing
const MetadataError = error{
    InvalidSignature,
    InvalidStream,
    InvalidTable,
    OutOfMemory,
    InvalidToken,
};

// Metadata stream data
pub const MetadataStream = struct {
    data: []const u8,
    offset: u32,
    size: u32,
};

// Metadata tables heap
pub const MetadataHeap = struct {
    string: []const u8, // #String heap
    blob: []const u8, // #Blob heap
    guid: []const u8, // #GUID heap
    user_string: []const u8, // #US heap
};

// Metadata tables presence bitmask
pub const TablePresence = struct {
    valid: u64 = 0, // Which tables are present (64-bit mask)
    sorted: u64 = 0, // Which tables are sorted (64-bit mask)
    large_strings: bool = false,
    large_guids: bool = false,
    large_blob: bool = false,
};

// Method definition row
pub const MethodDef = struct {
    rva: u32,
    impl_flags: u16,
    flags: u16,
    name: u32, // Offset into #String heap
    signature: u32, // Offset into #Blob heap
    param_list: u32, // Index into Param table
};

// Type definition row
pub const TypeDef = struct {
    flags: u32,
    name: u32, // Offset into #String heap
    namespace: u32, // Offset into #String heap
    extends: u32, // TypeDef or TypeRef token
    field_list: u32, // Index into Field table
    method_list: u32, // Index into MethodDef table
};

// Member reference row
pub const MemberRef = struct {
    class: u32, // TypeDef, TypeRef, ModuleRef, MethodDef, or TypeSpec token
    name: u32, // Offset into #String heap
    signature: u32, // Offset into #Blob heap
};

// Type reference row
pub const TypeRef = struct {
    resolution_scope: u32, // ModuleRef, AssemblyRef, or TypeRef token
    name: u32, // Offset into #String heap
    namespace: u32, // Offset into #String heap
};

// Assembly reference row
pub const AssemblyRef = struct {
    flags: u32,
    major_version: u16,
    minor_version: u16,
    build_number: u16,
    revision_number: u16,
    public_key: u32, // Offset into #Blob heap
    name: u32, // Offset into #String heap
    culture: u32, // Offset into #String heap
    hash_value: u32, // Offset into #Blob heap
};

// Field definition row
pub const FieldDef = struct {
    flags: u16,
    name: u32, // Offset into #String heap
    signature: u32, // Offset into #Blob heap
};

// Parameter definition row
pub const ParamDef = struct {
    flags: u16,
    sequence: u16,
    name: u32, // Offset into #String heap
};

// Parsed metadata
pub const Metadata = struct {
    header: clr_format.METADATA_HEADER,
    heap: MetadataHeap,
    tables: TablePresence,

    // Table rows
    method_defs: std.ArrayListUnmanaged(MethodDef),
    type_defs: std.ArrayListUnmanaged(TypeDef),
    member_refs: std.ArrayListUnmanaged(MemberRef),
    type_refs: std.ArrayListUnmanaged(TypeRef),
    assembly_refs: std.ArrayListUnmanaged(AssemblyRef),
    field_defs: std.ArrayListUnmanaged(FieldDef),
    param_defs: std.ArrayListUnmanaged(ParamDef),

    allocator: Allocator,

    pub fn init(allocator: Allocator) Metadata {
        return Metadata{
            .header = undefined,
            .heap = .{ .string = &[_]u8{}, .blob = &[_]u8{}, .guid = &[_]u8{}, .user_string = &[_]u8{} },
            .tables = .{},
            .method_defs = std.ArrayListUnmanaged(MethodDef).empty,
            .type_defs = std.ArrayListUnmanaged(TypeDef).empty,
            .member_refs = std.ArrayListUnmanaged(MemberRef).empty,
            .type_refs = std.ArrayListUnmanaged(TypeRef).empty,
            .assembly_refs = std.ArrayListUnmanaged(AssemblyRef).empty,
            .field_defs = std.ArrayListUnmanaged(FieldDef).empty,
            .param_defs = std.ArrayListUnmanaged(ParamDef).empty,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Metadata) void {
        self.method_defs.deinit(self.allocator);
        self.type_defs.deinit(self.allocator);
        self.member_refs.deinit(self.allocator);
        self.type_refs.deinit(self.allocator);
        self.assembly_refs.deinit(self.allocator);
        self.field_defs.deinit(self.allocator);
        self.param_defs.deinit(self.allocator);
    }
};

// String helper: read null-terminated string from heap
pub fn readString(heap: []const u8, offset: u32) []const u8 {
    if (offset == 0) return "";
    const start = offset;
    var i: u32 = offset;
    while (i < heap.len and heap[i] != 0) : (i += 1) {}
    return heap[start..i];
}

// Blob helper: read compressed integer from blob heap
pub fn readBlobU32(blob: []const u8, offset: *u32) !u32 {
    if (offset.* >= blob.len) return error.InvalidBlob;

    const first = blob[offset.*];
    offset.* += 1;

    if (first & 0x80 == 0) {
        return first; // 1-byte encoding
    } else if (first & 0xC0 == 0x80) {
        // 2-byte encoding
        if (offset.* >= blob.len) return error.InvalidBlob;
        const second = blob[offset.*];
        offset.* += 1;
        return ((@as(u32, first) & 0x3F) << 8) | second;
    } else {
        // 4-byte encoding
        if (offset.* + 3 >= blob.len) return error.InvalidBlob;
        const second = blob[offset.*];
        const third = blob[offset.* + 1];
        const fourth = blob[offset.* + 2];
        offset.* += 3;
        return ((@as(u32, first) & 0x3F) << 24) | (@as(u32, second) << 16) | (@as(u32, third) << 8) | fourth;
    }
}

// Parse metadata header
pub fn parseMetadataHeader(data: []const u8) !clr_format.METADATA_HEADER {
    if (data.len < 16) return MetadataError.InvalidSignature;

    const signature = readIntLE(u32, data, 0);
    if (signature != 0x424A5342) return MetadataError.InvalidSignature; // "BSJB"

    return clr_format.METADATA_HEADER{
        .signature = signature,
        .major_version = readIntLE(u16, data, 4),
        .minor_version = readIntLE(u16, data, 6),
        .reserved = readIntLE(u32, data, 8),
        .version_length = readIntLE(u32, data, 12),
        .flags = undefined, // Skip version string
        .streams = undefined,
    };
}

// Parse metadata tables header
pub const TablesHeader = struct {
    reserved: u32,
    major_version: u8,
    minor_version: u8,
    heap_sizes: u8,
    valid: u64,
    sorted: u64,

    fn isLargeStrings(self: *const TablesHeader) bool {
        return (self.heap_sizes & 0x01) != 0;
    }

    fn isLargeGuids(self: *const TablesHeader) bool {
        return (self.heap_sizes & 0x02) != 0;
    }

    fn isLargeBlob(self: *const TablesHeader) bool {
        return (self.heap_sizes & 0x04) != 0;
    }
};

pub fn parseTablesHeader(data: []const u8) !TablesHeader {
    if (data.len < 24) return MetadataError.InvalidTable;

    return TablesHeader{
        .reserved = readIntLE(u32, data, 0),
        .major_version = data[4],
        .minor_version = data[5],
        .heap_sizes = data[6],
        .valid = readIntLE(u64, data, 8),
        .sorted = readIntLE(u64, data, 16),
    };
}

// Get row count for a specific table by reading from the tables data stream.
// After the 24-byte tables header, there are N u32 row counts (one per set bit in Valid).
pub fn getRowCount(data: []const u8, base_offset: u32, header: TablesHeader, table_id: u8) u32 {
    const mask = @as(u64, 1) << @as(u6, @intCast(table_id));
    if ((header.valid & mask) == 0) return 0;

    // Count bits before this table to determine index into row count array
    var idx: u32 = 0;
    var i: u6 = 0;
    while (i < table_id) : (i += 1) {
        if ((header.valid & (@as(u64, 1) << i)) != 0) {
            idx += 1;
        }
    }
    // Read row count at base_offset + 24 + idx * 4
    const count_offset = base_offset + 24 + idx * 4;
    const result = if (count_offset + 4 > data.len) @as(u32, 0) else readIntLE(u32, data, count_offset);
    std.debug.print("CLR getRowCount: table=0x{x}, idx={d}, count_offset=0x{x}, result={d}\n", .{ table_id, idx, count_offset, result });
    return result;
}

// Parse complete metadata from assembly data
pub fn parseMetadata(allocator: Allocator, data: []const u8, metadata_offset: u32) !Metadata {
    var metadata = Metadata.init(allocator);
    errdefer metadata.deinit();

    // Parse metadata header
    const header = try parseMetadataHeader(data[metadata_offset..]);
    metadata.header = header;

    // Skip version string (4 bytes for length + variable string)
    var offset: u32 = 16 + header.version_length;
    // Align to 4-byte boundary
    offset = (offset + 3) & ~@as(u32, 3);

    // Parse flags and stream count
    if (offset + 2 > data.len) return MetadataError.InvalidStream;
    const flags_value = readIntLE(u16, data, metadata_offset + offset);
    offset += 2;
    _ = flags_value;
    const stream_count = readIntLE(u16, data, metadata_offset + offset);
    offset += 2;

    // Parse stream headers
    var string_heap_offset: u32 = 0;
    var string_heap_size: u32 = 0;
    var blob_heap_offset: u32 = 0;
    var blob_heap_size: u32 = 0;
    var guid_heap_offset: u32 = 0;
    var guid_heap_size: u32 = 0;
    var tables_offset: u32 = 0;
    var tables_size: u32 = 0;

    var stream_idx: u16 = 0;
    while (stream_idx < stream_count) : (stream_idx += 1) {
        if (offset + 8 > data.len) return MetadataError.InvalidStream;

        const stream_offset = readIntLE(u32, data, metadata_offset + offset);
        const stream_size = readIntLE(u32, data, metadata_offset + offset + 4);
        offset += 8;

        // Read stream name (null-terminated, padded to 4 bytes)
        const name_start = offset;
        while (offset < data.len and data[metadata_offset + offset] != 0) : (offset += 1) {}
        const name = data[metadata_offset + name_start .. metadata_offset + offset];
        offset += 1;
        // Pad to 4-byte boundary
        offset = (offset + 3) & ~@as(u32, 3);

        std.debug.print("CLR metadata: stream name='{s}' (len={d})\n", .{ name, name.len });

        // Identify stream (stream_offset is relative to metadata root)
        if (std.mem.eql(u8, name, clr_format.STREAM_STRING)) {
            std.debug.print("CLR metadata: matched #Strings at {d}\n", .{stream_offset});
            string_heap_offset = metadata_offset + stream_offset;
            string_heap_size = stream_size;
        } else if (std.mem.eql(u8, name, clr_format.STREAM_BLOB)) {
            blob_heap_offset = metadata_offset + stream_offset;
            blob_heap_size = stream_size;
        } else if (std.mem.eql(u8, name, clr_format.STREAM_GUID)) {
            guid_heap_offset = metadata_offset + stream_offset;
            guid_heap_size = stream_size;
        } else if (std.mem.eql(u8, name, clr_format.STREAM_US)) {
            metadata.heap.user_string = data[metadata_offset + stream_offset .. metadata_offset + stream_offset + stream_size];
        } else if (std.mem.eql(u8, name, clr_format.STREAM_TABLES) or std.mem.eql(u8, name, "#-")) {
            std.debug.print("CLR metadata: matched tables stream at {d}\n", .{stream_offset});
            tables_offset = metadata_offset + stream_offset;
            tables_size = stream_size;
        } else {
            std.debug.print("CLR metadata: UNMATCHED stream '{s}'\n", .{name});
        }
    }

    // Set up heap references
    if (string_heap_size > 0) {
        metadata.heap.string = data[string_heap_offset .. string_heap_offset + string_heap_size];
    }
    if (blob_heap_size > 0) {
        metadata.heap.blob = data[blob_heap_offset .. blob_heap_offset + blob_heap_size];
    }
    if (guid_heap_size > 0) {
        metadata.heap.guid = data[guid_heap_offset .. guid_heap_offset + guid_heap_size];
    }

    std.debug.print("CLR metadata: streams found, tables_offset=0x{x}, tables_size={d}\n", .{ tables_offset, tables_size });
    std.debug.print("CLR metadata: string_heap_offset=0x{x}, blob_heap_offset=0x{x}, guid_heap_offset=0x{x}\n", .{ string_heap_offset, blob_heap_offset, guid_heap_offset });

    // Parse tables header
    if (tables_size > 0) {
        const tables_header = try parseTablesHeader(data[tables_offset..]);
        std.debug.print("CLR metadata: valid=0x{x}, sorted=0x{x}, heap_sizes=0x{x}\n", .{ tables_header.valid, tables_header.sorted, tables_header.heap_sizes });
        metadata.tables.valid = tables_header.valid;
        metadata.tables.sorted = tables_header.sorted;
        metadata.tables.large_strings = tables_header.isLargeStrings();
        metadata.tables.large_guids = tables_header.isLargeGuids();
        metadata.tables.large_blob = tables_header.isLargeBlob();

        // Pre-read all row counts
        var row_counts: [64]u32 = [_]u32{0} ** 64;
        var bit_idx: u32 = 0;
        var count_pos: u32 = 0;
        while (bit_idx < 64) : (bit_idx += 1) {
            if ((tables_header.valid & (@as(u64, 1) << @as(u6, @intCast(bit_idx)))) != 0) {
                const row_count = readIntLE(u32, data, tables_offset + 24 + count_pos * 4);
                row_counts[bit_idx] = row_count;
                count_pos += 1;
            }
        }

        // Parse individual tables
        try parseMethodDefTable(&metadata, data, tables_offset, tables_header, &row_counts);
        try parseTypeDefTable(&metadata, data, tables_offset, tables_header, &row_counts);
        try parseMemberRefTable(&metadata, data, tables_offset, tables_header, &row_counts);
        try parseTypeRefTable(&metadata, data, tables_offset, tables_header, &row_counts);
        try parseAssemblyRefTable(&metadata, data, tables_offset, tables_header, &row_counts);
        try parseFieldDefTable(&metadata, data, tables_offset, tables_header, &row_counts);
        try parseParamDefTable(&metadata, data, tables_offset, tables_header, &row_counts);
    }

    return metadata;
}

fn parseMethodDefTable(metadata: *Metadata, data: []const u8, base_offset: u32, header: TablesHeader, row_counts: *const [64]u32) !void {
    const table_id = clr_format.TABLE_METHODDEF;
    if ((header.valid & (@as(u64, 1) << table_id)) == 0) return;

    const row_count = row_counts[table_id];
    var row_offset = base_offset + calculateTableOffset(header, table_id, row_counts);
    const param_idx_sz = tableIndexSize(row_counts[8]);
    const row_size: u32 = 4 + 2 + 2 + (if (header.isLargeStrings()) @as(u32, 4) else @as(u32, 2)) + (if (header.isLargeBlob()) @as(u32, 4) else @as(u32, 2)) + param_idx_sz;
    std.debug.print("CLR parseMethodDefTable: base_offset=0x{x}, row_offset=0x{x}, row_count={d}, row_size={d}\n", .{ base_offset, row_offset, row_count, row_size });
    if (row_count > 0) {
        std.debug.print("CLR parseMethodDefTable: first row RVA raw bytes: {x} {x} {x} {x}\n", .{ data[row_offset], data[row_offset+1], data[row_offset+2], data[row_offset+3] });
    }

    try metadata.method_defs.ensureTotalCapacity(metadata.allocator, row_count);

    var i: u32 = 0;
    while (i < row_count) : (i += 1) {
        if (row_offset + row_size > data.len) return MetadataError.InvalidTable;

        const rva = readIntLE(u32, data, row_offset);
        const impl_flags = readIntLE(u16, data, row_offset + 4);
        const flags = readIntLE(u16, data, row_offset + 6);

        var name_off: u32 = 0;
        var sig_off: u32 = 0;
        var param_list: u32 = 0;

        var curr: u32 = 8;
        if (header.isLargeStrings()) {
            name_off = readIntLE(u32, data, row_offset + curr);
            curr += 4;
        } else {
            name_off = readIntLE(u16, data, row_offset + curr);
            curr += 2;
        }

        if (header.isLargeBlob()) {
            sig_off = readIntLE(u32, data, row_offset + curr);
            curr += 4;
        } else {
            sig_off = readIntLE(u16, data, row_offset + curr);
            curr += 2;
        }

        if (param_idx_sz == 4) {
            param_list = readIntLE(u32, data, row_offset + curr);
            curr += 4;
        } else {
            param_list = readIntLE(u16, data, row_offset + curr);
            curr += 2;
        }

        metadata.method_defs.appendAssumeCapacity(MethodDef{
            .rva = rva,
            .impl_flags = impl_flags,
            .flags = flags,
            .name = name_off,
            .signature = sig_off,
            .param_list = param_list,
        });

        row_offset += row_size;
    }
}

fn parseTypeDefTable(metadata: *Metadata, data: []const u8, base_offset: u32, header: TablesHeader, row_counts: *const [64]u32) !void {
    const table_id = clr_format.TABLE_TYPEDEF;
    if ((header.valid & (@as(u64, 1) << table_id)) == 0) return;

    const row_count = row_counts[table_id];
    var row_offset = base_offset + calculateTableOffset(header, table_id, row_counts);
    const extends_sz = codedIndexSize(&[_]u32{ 2, 1, 27 }, 2, row_counts);
    const field_list_sz = tableIndexSize(row_counts[4]);
    const method_list_sz = tableIndexSize(row_counts[6]);
    const row_size: u32 = 4 + (if (header.isLargeStrings()) @as(u32, 4) else @as(u32, 2)) + (if (header.isLargeStrings()) @as(u32, 4) else @as(u32, 2)) + extends_sz + field_list_sz + method_list_sz;

    try metadata.type_defs.ensureTotalCapacity(metadata.allocator, row_count);

    var i: u32 = 0;
    while (i < row_count) : (i += 1) {
        if (row_offset + row_size > data.len) return MetadataError.InvalidTable;

        const flags = readIntLE(u32, data, row_offset);

        var name_off: u32 = 0;
        var namespace_off: u32 = 0;

        var curr: u32 = 4;
        if (header.isLargeStrings()) {
            name_off = readIntLE(u32, data, row_offset + curr);
            curr += 4;
        } else {
            name_off = readIntLE(u16, data, row_offset + curr);
            curr += 2;
        }

        if (header.isLargeStrings()) {
            namespace_off = readIntLE(u32, data, row_offset + curr);
            curr += 4;
        } else {
            namespace_off = readIntLE(u16, data, row_offset + curr);
            curr += 2;
        }

        const extends = if (extends_sz == 4) readIntLE(u32, data, row_offset + curr) else @as(u32, readIntLE(u16, data, row_offset + curr));
        curr += extends_sz;
        const field_list = if (field_list_sz == 4) readIntLE(u32, data, row_offset + curr) else @as(u32, readIntLE(u16, data, row_offset + curr));
        curr += field_list_sz;
        const method_list = if (method_list_sz == 4) readIntLE(u32, data, row_offset + curr) else @as(u32, readIntLE(u16, data, row_offset + curr));
        curr += method_list_sz;

        metadata.type_defs.appendAssumeCapacity(TypeDef{
            .flags = flags,
            .name = name_off,
            .namespace = namespace_off,
            .extends = extends,
            .field_list = field_list,
            .method_list = method_list,
        });

        row_offset += row_size;
    }
}

fn parseMemberRefTable(metadata: *Metadata, data: []const u8, base_offset: u32, header: TablesHeader, row_counts: *const [64]u32) !void {
    const table_id = clr_format.TABLE_MEMBERREF;
    if ((header.valid & (@as(u64, 1) << table_id)) == 0) return;

    const row_count = row_counts[table_id];
    var row_offset = base_offset + calculateTableOffset(header, table_id, row_counts);
    const class_sz = codedIndexSize(&[_]u32{ 2, 1, 26, 6, 27 }, 3, row_counts);
    const row_size: u32 = class_sz + (if (header.isLargeStrings()) @as(u32, 4) else @as(u32, 2)) + (if (header.isLargeBlob()) @as(u32, 4) else @as(u32, 2));

    try metadata.member_refs.ensureTotalCapacity(metadata.allocator, row_count);

    var i: u32 = 0;
    while (i < row_count) : (i += 1) {
        if (row_offset + row_size > data.len) return MetadataError.InvalidTable;

        const class = if (class_sz == 4) readIntLE(u32, data, row_offset) else @as(u32, readIntLE(u16, data, row_offset));

        var name_off: u32 = 0;
        var sig_off: u32 = 0;

        var curr: u32 = class_sz;
        if (header.isLargeStrings()) {
            name_off = readIntLE(u32, data, row_offset + curr);
            curr += 4;
        } else {
            name_off = readIntLE(u16, data, row_offset + curr);
            curr += 2;
        }

        if (header.isLargeBlob()) {
            sig_off = readIntLE(u32, data, row_offset + curr);
            curr += 4;
        } else {
            sig_off = readIntLE(u16, data, row_offset + curr);
            curr += 2;
        }

        metadata.member_refs.appendAssumeCapacity(MemberRef{
            .class = class,
            .name = name_off,
            .signature = sig_off,
        });

        row_offset += row_size;
    }
}

fn parseTypeRefTable(metadata: *Metadata, data: []const u8, base_offset: u32, header: TablesHeader, row_counts: *const [64]u32) !void {
    const table_id = clr_format.TABLE_TYPEREF;
    if ((header.valid & (@as(u64, 1) << table_id)) == 0) return;

    const row_count = row_counts[table_id];
    var row_offset = base_offset + calculateTableOffset(header, table_id, row_counts);
    const rs_sz = codedIndexSize(&[_]u32{ 0, 26, 35, 1 }, 2, row_counts);
    const row_size: u32 = rs_sz + (if (header.isLargeStrings()) @as(u32, 4) else @as(u32, 2)) + (if (header.isLargeStrings()) @as(u32, 4) else @as(u32, 2));

    try metadata.type_refs.ensureTotalCapacity(metadata.allocator, row_count);

    var i: u32 = 0;
    while (i < row_count) : (i += 1) {
        if (row_offset + row_size > data.len) return MetadataError.InvalidTable;

        const resolution_scope = if (rs_sz == 4) readIntLE(u32, data, row_offset) else @as(u32, readIntLE(u16, data, row_offset));

        var name_off: u32 = 0;
        var namespace_off: u32 = 0;

        var curr: u32 = rs_sz;
        if (header.isLargeStrings()) {
            name_off = readIntLE(u32, data, row_offset + curr);
            curr += 4;
        } else {
            name_off = readIntLE(u16, data, row_offset + curr);
            curr += 2;
        }

        if (header.isLargeStrings()) {
            namespace_off = readIntLE(u32, data, row_offset + curr);
            curr += 4;
        } else {
            namespace_off = readIntLE(u16, data, row_offset + curr);
            curr += 2;
        }

        metadata.type_refs.appendAssumeCapacity(TypeRef{
            .resolution_scope = resolution_scope,
            .name = name_off,
            .namespace = namespace_off,
        });

        row_offset += row_size;
    }
}

fn parseAssemblyRefTable(metadata: *Metadata, data: []const u8, base_offset: u32, header: TablesHeader, row_counts: *const [64]u32) !void {
    const table_id = clr_format.TABLE_ASSEMBLYREF;
    if ((header.valid & (@as(u64, 1) << table_id)) == 0) return;

    const row_count = row_counts[table_id];
    var row_offset = base_offset + calculateTableOffset(header, table_id, row_counts);
    const row_size: u32 = 4 + 2 + 2 + 2 + 2 + (if (header.isLargeBlob()) @as(u32, 4) else @as(u32, 2)) + (if (header.isLargeStrings()) @as(u32, 4) else @as(u32, 2)) + (if (header.isLargeStrings()) @as(u32, 4) else @as(u32, 2)) + (if (header.isLargeBlob()) @as(u32, 4) else @as(u32, 2));

    try metadata.assembly_refs.ensureTotalCapacity(metadata.allocator, row_count);

    var i: u32 = 0;
    while (i < row_count) : (i += 1) {
        if (row_offset + row_size > data.len) return MetadataError.InvalidTable;

        const flags = readIntLE(u32, data, row_offset);
        const major_version = readIntLE(u16, data, row_offset + 4);
        const minor_version = readIntLE(u16, data, row_offset + 6);
        const build_number = readIntLE(u16, data, row_offset + 8);
        const revision_number = readIntLE(u16, data, row_offset + 10);

        var public_key_off: u32 = 0;
        var name_off: u32 = 0;
        var culture_off: u32 = 0;
        var hash_off: u32 = 0;

        var curr: u32 = 12;
        if (header.isLargeBlob()) {
            public_key_off = readIntLE(u32, data, row_offset + curr);
            curr += 4;
        } else {
            public_key_off = readIntLE(u16, data, row_offset + curr);
            curr += 2;
        }

        if (header.isLargeStrings()) {
            name_off = readIntLE(u32, data, row_offset + curr);
            curr += 4;
        } else {
            name_off = readIntLE(u16, data, row_offset + curr);
            curr += 2;
        }

        if (header.isLargeStrings()) {
            culture_off = readIntLE(u32, data, row_offset + curr);
            curr += 4;
        } else {
            culture_off = readIntLE(u16, data, row_offset + curr);
            curr += 2;
        }

        if (header.isLargeBlob()) {
            hash_off = readIntLE(u32, data, row_offset + curr);
            curr += 4;
        } else {
            hash_off = readIntLE(u16, data, row_offset + curr);
            curr += 2;
        }

        metadata.assembly_refs.appendAssumeCapacity(AssemblyRef{
            .flags = flags,
            .major_version = major_version,
            .minor_version = minor_version,
            .build_number = build_number,
            .revision_number = revision_number,
            .public_key = public_key_off,
            .name = name_off,
            .culture = culture_off,
            .hash_value = hash_off,
        });

        row_offset += row_size;
    }
}

fn parseFieldDefTable(metadata: *Metadata, data: []const u8, base_offset: u32, header: TablesHeader, row_counts: *const [64]u32) !void {
    const table_id = clr_format.TABLE_FIELD;
    if ((header.valid & (@as(u64, 1) << table_id)) == 0) return;

    const row_count = row_counts[table_id];
    var row_offset = base_offset + calculateTableOffset(header, table_id, row_counts);
    const row_size: u32 = 2 + (if (header.isLargeStrings()) @as(u32, 4) else @as(u32, 2)) + (if (header.isLargeBlob()) @as(u32, 4) else @as(u32, 2));

    try metadata.field_defs.ensureTotalCapacity(metadata.allocator, row_count);

    var i: u32 = 0;
    while (i < row_count) : (i += 1) {
        if (row_offset + row_size > data.len) return MetadataError.InvalidTable;

        const flags = readIntLE(u16, data, row_offset);

        var name_off: u32 = 0;
        var sig_off: u32 = 0;

        var curr: u32 = 2;
        if (header.isLargeStrings()) {
            name_off = readIntLE(u32, data, row_offset + curr);
            curr += 4;
        } else {
            name_off = readIntLE(u16, data, row_offset + curr);
            curr += 2;
        }

        if (header.isLargeBlob()) {
            sig_off = readIntLE(u32, data, row_offset + curr);
            curr += 4;
        } else {
            sig_off = readIntLE(u16, data, row_offset + curr);
            curr += 2;
        }

        metadata.field_defs.appendAssumeCapacity(FieldDef{
            .flags = flags,
            .name = name_off,
            .signature = sig_off,
        });

        row_offset += row_size;
    }
}

fn parseParamDefTable(metadata: *Metadata, data: []const u8, base_offset: u32, header: TablesHeader, row_counts: *const [64]u32) !void {
    const table_id = clr_format.TABLE_PARAM;
    if ((header.valid & (@as(u64, 1) << table_id)) == 0) return;

    const row_count = row_counts[table_id];
    var row_offset = base_offset + calculateTableOffset(header, table_id, row_counts);
    const row_size: u32 = 2 + 2 + (if (header.isLargeStrings()) @as(u32, 4) else @as(u32, 2));

    try metadata.param_defs.ensureTotalCapacity(metadata.allocator, row_count);

    var i: u32 = 0;
    while (i < row_count) : (i += 1) {
        if (row_offset + row_size > data.len) return MetadataError.InvalidTable;

        const flags = readIntLE(u16, data, row_offset);
        const sequence = readIntLE(u16, data, row_offset + 2);

        var name_off: u32 = 0;
        var curr: u32 = 4;

        if (header.isLargeStrings()) {
            name_off = readIntLE(u32, data, row_offset + curr);
            curr += 4;
        } else {
            name_off = readIntLE(u16, data, row_offset + curr);
            curr += 2;
        }

        metadata.param_defs.appendAssumeCapacity(ParamDef{
            .flags = flags,
            .sequence = sequence,
            .name = name_off,
        });

        row_offset += row_size;
    }
}

// Helper to calculate table offset in the data stream
fn calculateTableOffset(header: TablesHeader, target_table: u8, row_counts: *const [64]u32) u32 {
    var offset: u32 = 24; // Tables header size

    // Count rows in all tables before the target
    var table_id: u8 = 0;
    while (table_id < target_table) : (table_id += 1) {
        const shift: u6 = @intCast(table_id);
        if ((header.valid & (@as(u64, 1) << shift)) != 0) {
            const row_sz = calculateTableRowSize(header, table_id, row_counts);
            const rc = row_counts[table_id];
            std.debug.print("CLR calcTableOff: table=0x{x}, rc={d}, sz={d}\n", .{ table_id, rc, row_sz });
            offset += rc * row_sz;
        }
    }

    return offset;
}

// Table/coded index size helpers
fn isSmallTable(row_count: u32) bool {
    return row_count <= 65535;
}

fn tableIndexSize(row_count: u32) u32 {
    return if (isSmallTable(row_count)) 2 else 4;
}

fn codedIndexSize(comptime tables: []const u32, comptime tag_bits: u32, row_counts: *const [64]u32) u32 {
    var max_rows: u32 = 0;
    inline for (tables) |t| {
        if (row_counts[t] > max_rows) max_rows = row_counts[t];
    }
    const max_indexable = (@as(u64, 1) << (@as(u6, 16) - tag_bits));
    return if (max_rows < max_indexable) 2 else 4;
}

// Calculate row size for a specific table using pre-computed row counts
fn calculateTableRowSize(header: TablesHeader, table_id: u8, row_counts: *const [64]u32) u32 {
    const ls = if (header.isLargeStrings()) @as(u32, 4) else @as(u32, 2);
    const lb = if (header.isLargeBlob()) @as(u32, 4) else @as(u32, 2);
    const lg = if (header.isLargeGuids()) @as(u32, 4) else @as(u32, 2);
    const ti = tableIndexSize(row_counts[table_id]);
    _ = ti; // for future use in dynamic sizing
    return switch (table_id) {
        clr_format.TABLE_MODULE => 2 + ls + lg + lg + lg,
        clr_format.TABLE_TYPEREF => codedIndexSize(&[_]u32{ 0, 26, 35, 1 }, 2, row_counts) + ls + ls,
        clr_format.TABLE_TYPEDEF => 4 + ls + ls + codedIndexSize(&[_]u32{ 2, 1, 27 }, 2, row_counts) + tableIndexSize(row_counts[4]) + tableIndexSize(row_counts[6]),
        clr_format.TABLE_FIELD => 2 + ls + lb,
        clr_format.TABLE_METHODDEF => 4 + 2 + 2 + ls + lb + tableIndexSize(row_counts[8]),
        clr_format.TABLE_PARAM => 2 + 2 + ls,
        clr_format.TABLE_INTERFACEIMPL => codedIndexSize(&[_]u32{ 2, 1, 27 }, 2, row_counts) + codedIndexSize(&[_]u32{ 2, 1, 27 }, 2, row_counts),
        clr_format.TABLE_MEMBERREF => codedIndexSize(&[_]u32{ 2, 1, 26, 6, 27 }, 3, row_counts) + ls + lb,
        clr_format.TABLE_CONSTANT => 2 + 2 + lb,
        clr_format.TABLE_CUSTOMATTRIBUTE => codedIndexSize(&[_]u32{ 4, 8, 23 }, 2, row_counts) + codedIndexSize(&[_]u32{ 0, 1, 2, 4, 6, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 27 }, 5, row_counts) + 4 + lb,
        clr_format.TABLE_FIELDMARSHAL => tableIndexSize(row_counts[4]) + lb,
        clr_format.TABLE_DECLSECURITY => 2 + codedIndexSize(&[_]u32{ 2, 6, 32 }, 2, row_counts) + lb,
        clr_format.TABLE_CLASSLAYOUT => 2 + tableIndexSize(row_counts[2]) + tableIndexSize(row_counts[4]),
        clr_format.TABLE_FIELDLAYOUT => tableIndexSize(row_counts[4]) + 4,
        clr_format.TABLE_STANDBALONE_SIG => 4 + lb,
        clr_format.TABLE_EVENTMAP => tableIndexSize(row_counts[2]) + tableIndexSize(row_counts[20]),
        clr_format.TABLE_EVENT => 2 + ls + tableIndexSize(row_counts[2]),
        clr_format.TABLE_PROPERTYMAP => tableIndexSize(row_counts[2]) + tableIndexSize(row_counts[23]),
        clr_format.TABLE_PROPERTY => 2 + ls + lb,
        clr_format.TABLE_METHODSEMANTICS => 2 + tableIndexSize(row_counts[6]) + tableIndexSize(row_counts[20]),
        clr_format.TABLE_METHODIMPL => tableIndexSize(row_counts[2]) + 4 + 4,
        clr_format.TABLE_MODULEREF => ls,
        clr_format.TABLE_TYPESPEC => lb,
        clr_format.TABLE_IMPLMAP => 2 + codedIndexSize(&[_]u32{ 6, 10 }, 1, row_counts) + ls + tableIndexSize(row_counts[32]),
        clr_format.TABLE_FIELDRVA => tableIndexSize(row_counts[6]) + 4,
        clr_format.TABLE_ENCLOG => 4 + 4,
        clr_format.TABLE_ENCMAP => 4,
        clr_format.TABLE_ASSEMBLY => 4 + 2 + 2 + 2 + 2 + lb + ls + ls + lb,
        clr_format.TABLE_ASSEMBLYPROCESSOR => 4 + 4,
        clr_format.TABLE_ASSEMBLYOS => 4 + 4 + 4,
        clr_format.TABLE_ASSEMBLYREF => 4 + 2 + 2 + 2 + 2 + lb + ls + ls + lb,
        clr_format.TABLE_ASSEMBLYREFPROCESSOR => 4 + 4 + 4,
        clr_format.TABLE_ASSEMBLYREFOS => 4 + 4 + 4 + 4,
        clr_format.TABLE_FILE => 4 + ls + lb + ls,
        clr_format.TABLE_EXPORTEDTYPE => 4 + tableIndexSize(row_counts[2]) + ls + ls + tableIndexSize(row_counts[35]),
        clr_format.TABLE_MANIFESTRESOURCE => 4 + tableIndexSize(row_counts[35]) + ls + tableIndexSize(row_counts[2]) + ls,
        clr_format.TABLE_NESTEDCLASS => tableIndexSize(row_counts[2]) + tableIndexSize(row_counts[2]),
        clr_format.TABLE_GENERICPARAM => 2 + 2 + codedIndexSize(&[_]u32{ 2, 6, 8, 23, 24 }, 3, row_counts) + ls + tableIndexSize(row_counts[42]),
        clr_format.TABLE_METHODSPEC => 4 + lb,
        clr_format.TABLE_GENERICPARAMCONSTRAINT => tableIndexSize(row_counts[42]) + codedIndexSize(&[_]u32{ 2, 1, 27 }, 2, row_counts) + tableIndexSize(row_counts[42]),
        else => 0,
    };
}
