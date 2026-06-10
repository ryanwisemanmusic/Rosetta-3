const std = @import("std");
const clr_format = @import("clr_pe_format.zig");
const clr_metadata = @import("clr_metadata.zig");

const Allocator = std.mem.Allocator;

// Assembly parsing errors
const AssemblyError = error{
    InvalidPE,
    InvalidCLRHeader,
    InvalidMetadata,
    OutOfMemory,
};

// CLR assembly representation
pub const Assembly = struct {
    metadata: clr_metadata.Metadata,
    clr_header: clr_format.CLR_HEADER,
    entry_point_token: u32,

    allocator: Allocator,

    fn init(allocator: Allocator) Assembly {
        return Assembly{
            .metadata = clr_metadata.Metadata.init(allocator),
            .clr_header = undefined,
            .entry_point_token = 0,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Assembly) void {
        self.metadata.deinit();
    }
};

// Standard PE COFF file header (20 bytes, per Microsoft PE spec)
const PEHeader = struct {
    machine: u16,
    number_of_sections: u16,
    time_date_stamp: u32,
    pointer_to_symbol_table: u32,
    number_of_symbols: u32,
    size_of_optional_header: u16,
    characteristics: u16,
};

const OptionalHeader32 = struct {
    magic: u16,
    major_linker_version: u8,
    minor_linker_version: u8,
    size_of_code: u32,
    size_of_initialized_data: u32,
    size_of_uninitialized_data: u32,
    address_of_entry_point: u32,
    base_of_code: u32,
    base_of_data: u32,
    image_base: u32,
    section_alignment: u32,
    file_alignment: u32,
    major_operating_system_version: u16,
    minor_operating_system_version: u16,
    major_image_version: u16,
    minor_image_version: u16,
    major_subsystem_version: u16,
    minor_subsystem_version: u16,
    win32_version_value: u32,
    size_of_image: u32,
    size_of_headers: u32,
    check_sum: u32,
    subsystem: u16,
    dll_characteristics: u16,
    size_of_stack_reserve: u32,
    size_of_stack_commit: u32,
    size_of_heap_reserve: u32,
    size_of_heap_commit: u32,
    loader_flags: u32,
    number_of_rva_and_sizes: u32,
};

const OptionalHeader64 = struct {
    magic: u16,
    major_linker_version: u8,
    minor_linker_version: u8,
    size_of_code: u32,
    size_of_initialized_data: u32,
    size_of_uninitialized_data: u32,
    address_of_entry_point: u32,
    base_of_code: u32,
    image_base: u64,
    section_alignment: u32,
    file_alignment: u32,
    major_operating_system_version: u16,
    minor_operating_system_version: u16,
    major_image_version: u16,
    minor_image_version: u16,
    major_subsystem_version: u16,
    minor_subsystem_version: u16,
    win32_version_value: u32,
    size_of_image: u32,
    size_of_headers: u32,
    check_sum: u32,
    subsystem: u16,
    dll_characteristics: u16,
    size_of_stack_reserve: u64,
    size_of_stack_commit: u64,
    size_of_heap_reserve: u64,
    size_of_heap_commit: u64,
    loader_flags: u32,
    number_of_rva_and_sizes: u32,
};

const DataDirectory = struct {
    virtual_address: u32,
    size: u32,
};

const SectionHeader = struct {
    name: [8]u8,
    virtual_size: u32,
    virtual_address: u32,
    size_of_raw_data: u32,
    pointer_to_raw_data: u32,
    pointer_to_relocations: u32,
    pointer_to_line_numbers: u32,
    number_of_relocations: u16,
    number_of_line_numbers: u16,
    characteristics: u32,
};

// COM descriptor directory index
const IMAGE_DIRECTORY_ENTRY_COM_DESCRIPTOR = 14;

// Parse a .NET assembly from PE file data
pub fn parseAssembly(allocator: Allocator, data: []const u8) !Assembly {
    var assembly = Assembly.init(allocator);
    errdefer assembly.deinit();

    // Check PE signature
    if (data.len < 64) return AssemblyError.InvalidPE;
    if (!std.mem.eql(u8, data[0..2], "MZ")) return AssemblyError.InvalidPE;

    // Get PE header offset from DOS stub
    var pe_offset: u32 = 0;
    @memcpy(@as([*]u8, @ptrCast(&pe_offset))[0..4], data[60..64]);
    if (pe_offset + 4 >= data.len) return AssemblyError.InvalidPE;

    // Check PE signature
    if (!std.mem.eql(u8, data[pe_offset .. pe_offset + 4], "PE\x00\x00")) return AssemblyError.InvalidPE;

    // Read PE header
    const pe_header_offset = pe_offset + 4;
    const pe_header = readPEHeader(data, pe_header_offset) catch return AssemblyError.InvalidPE;

    // Determine architecture and read optional header
    const is_64bit = pe_header.machine == 0x8664; // IMAGE_FILE_MACHINE_AMD64
    const optional_header_offset = pe_header_offset + @sizeOf(PEHeader);

    var clr_rva: u32 = 0;
    var image_base: u64 = 0;

    if (is_64bit) {
        const opt_header = readOptionalHeader64(data, optional_header_offset) catch return AssemblyError.InvalidPE;
        image_base = opt_header.image_base;

        // Read data directories
        const data_dirs_offset = optional_header_offset + @sizeOf(OptionalHeader64);
        if (data_dirs_offset + IMAGE_DIRECTORY_ENTRY_COM_DESCRIPTOR * @sizeOf(DataDirectory) + @sizeOf(DataDirectory) > data.len) {
            return AssemblyError.InvalidPE;
        }

        const com_descriptor = readDataDirectory(data, data_dirs_offset + IMAGE_DIRECTORY_ENTRY_COM_DESCRIPTOR * @sizeOf(DataDirectory));
        clr_rva = com_descriptor.virtual_address;
    } else {
        const opt_header = readOptionalHeader32(data, optional_header_offset) catch return AssemblyError.InvalidPE;
        image_base = @as(u64, @intCast(opt_header.image_base));

        // Read data directories
        const data_dirs_offset = optional_header_offset + @sizeOf(OptionalHeader32);
        if (data_dirs_offset + IMAGE_DIRECTORY_ENTRY_COM_DESCRIPTOR * @sizeOf(DataDirectory) + @sizeOf(DataDirectory) > data.len) {
            return AssemblyError.InvalidPE;
        }

        const com_descriptor = readDataDirectory(data, data_dirs_offset + IMAGE_DIRECTORY_ENTRY_COM_DESCRIPTOR * @sizeOf(DataDirectory));
        clr_rva = com_descriptor.virtual_address;
    }

    if (clr_rva == 0) return AssemblyError.InvalidCLRHeader;

    // Convert RVA to file offset
    const clr_offset = rvaToOffset(data, pe_header_offset, pe_header.number_of_sections, clr_rva) catch return AssemblyError.InvalidCLRHeader;

    // Read CLR header
    if (clr_offset + @sizeOf(clr_format.CLR_HEADER) > data.len) return AssemblyError.InvalidCLRHeader;
    assembly.clr_header = readCLRHeader(data, clr_offset);
    assembly.entry_point_token = assembly.clr_header.entry_point_token;
    std.debug.print("CLR assembly: clr_offset=0x{x}, metadata RVA=0x{x}, entry_token=0x{x}\n", .{ clr_offset, assembly.clr_header.metadata.virtual_address, assembly.entry_point_token });

    // Parse metadata
    const metadata_rva = assembly.clr_header.metadata.virtual_address;
    const metadata_offset = rvaToOffset(data, pe_header_offset, pe_header.number_of_sections, metadata_rva) catch return AssemblyError.InvalidMetadata;
    std.debug.print("CLR assembly: metadata_offset=0x{x}, data.len={d}\n", .{ metadata_offset, data.len });

    assembly.metadata = try clr_metadata.parseMetadata(allocator, data, metadata_offset);

    return assembly;
}

// Helper: read PE COFF file header (per Microsoft PE spec, 20 bytes)
fn readPEHeader(data: []const u8, offset: u32) !PEHeader {
    if (offset + @sizeOf(PEHeader) > data.len) return error.InvalidOffset;

    return PEHeader{
        .machine = readIntLE(u16, data, offset),
        .number_of_sections = readIntLE(u16, data, offset + 2),
        .time_date_stamp = readIntLE(u32, data, offset + 4),
        .pointer_to_symbol_table = readIntLE(u32, data, offset + 8),
        .number_of_symbols = readIntLE(u32, data, offset + 12),
        .size_of_optional_header = readIntLE(u16, data, offset + 16),
        .characteristics = readIntLE(u16, data, offset + 18),
    };
}

// Helper: read little-endian integer from data
fn readIntLE(comptime T: type, data: []const u8, offset: u32) T {
    const bytes = @sizeOf(T);
    var result: T = 0;
    inline for (0..bytes) |i| {
        result |= (@as(T, data[offset + i]) << (i * 8));
    }
    return result;
}

// Helper: read 32-bit optional header
fn readOptionalHeader32(data: []const u8, offset: u32) !OptionalHeader32 {
    if (offset + @sizeOf(OptionalHeader32) > data.len) return error.InvalidOffset;

    return OptionalHeader32{
        .magic = readIntLE(u16, data, offset),
        .major_linker_version = data[offset + 2],
        .minor_linker_version = data[offset + 3],
        .size_of_code = readIntLE(u32, data, offset + 4),
        .size_of_initialized_data = readIntLE(u32, data, offset + 8),
        .size_of_uninitialized_data = readIntLE(u32, data, offset + 12),
        .address_of_entry_point = readIntLE(u32, data, offset + 16),
        .base_of_code = readIntLE(u32, data, offset + 20),
        .base_of_data = readIntLE(u32, data, offset + 24),
        .image_base = readIntLE(u32, data, offset + 28),
        .section_alignment = readIntLE(u32, data, offset + 32),
        .file_alignment = readIntLE(u32, data, offset + 36),
        .major_operating_system_version = readIntLE(u16, data, offset + 40),
        .minor_operating_system_version = readIntLE(u16, data, offset + 42),
        .major_image_version = readIntLE(u16, data, offset + 44),
        .minor_image_version = readIntLE(u16, data, offset + 46),
        .major_subsystem_version = readIntLE(u16, data, offset + 48),
        .minor_subsystem_version = readIntLE(u16, data, offset + 50),
        .win32_version_value = readIntLE(u32, data, offset + 52),
        .size_of_image = readIntLE(u32, data, offset + 56),
        .size_of_headers = readIntLE(u32, data, offset + 60),
        .check_sum = readIntLE(u32, data, offset + 64),
        .subsystem = readIntLE(u16, data, offset + 68),
        .dll_characteristics = readIntLE(u16, data, offset + 70),
        .size_of_stack_reserve = readIntLE(u32, data, offset + 72),
        .size_of_stack_commit = readIntLE(u32, data, offset + 76),
        .size_of_heap_reserve = readIntLE(u32, data, offset + 80),
        .size_of_heap_commit = readIntLE(u32, data, offset + 84),
        .loader_flags = readIntLE(u32, data, offset + 88),
        .number_of_rva_and_sizes = readIntLE(u32, data, offset + 92),
    };
}

// Helper: read 64-bit optional header
fn readOptionalHeader64(data: []const u8, offset: u32) !OptionalHeader64 {
    if (offset + @sizeOf(OptionalHeader64) > data.len) return error.InvalidOffset;

    return OptionalHeader64{
        .magic = readIntLE(u16, data, offset),
        .major_linker_version = data[offset + 2],
        .minor_linker_version = data[offset + 3],
        .size_of_code = readIntLE(u32, data, offset + 4),
        .size_of_initialized_data = readIntLE(u32, data, offset + 8),
        .size_of_uninitialized_data = readIntLE(u32, data, offset + 12),
        .address_of_entry_point = readIntLE(u32, data, offset + 16),
        .base_of_code = readIntLE(u32, data, offset + 20),
        .image_base = readIntLE(u64, data, offset + 24),
        .section_alignment = readIntLE(u32, data, offset + 32),
        .file_alignment = readIntLE(u32, data, offset + 36),
        .major_operating_system_version = readIntLE(u16, data, offset + 40),
        .minor_operating_system_version = readIntLE(u16, data, offset + 42),
        .major_image_version = readIntLE(u16, data, offset + 44),
        .minor_image_version = readIntLE(u16, data, offset + 46),
        .major_subsystem_version = readIntLE(u16, data, offset + 48),
        .minor_subsystem_version = readIntLE(u16, data, offset + 50),
        .win32_version_value = readIntLE(u32, data, offset + 52),
        .size_of_image = readIntLE(u32, data, offset + 56),
        .size_of_headers = readIntLE(u32, data, offset + 60),
        .check_sum = readIntLE(u32, data, offset + 64),
        .subsystem = readIntLE(u16, data, offset + 68),
        .dll_characteristics = readIntLE(u16, data, offset + 70),
        .size_of_stack_reserve = readIntLE(u64, data, offset + 72),
        .size_of_stack_commit = readIntLE(u64, data, offset + 80),
        .size_of_heap_reserve = readIntLE(u64, data, offset + 88),
        .size_of_heap_commit = readIntLE(u64, data, offset + 96),
        .loader_flags = readIntLE(u32, data, offset + 104),
        .number_of_rva_and_sizes = readIntLE(u32, data, offset + 108),
    };
}

// Helper: read data directory
fn readDataDirectory(data: []const u8, offset: u32) DataDirectory {
    return DataDirectory{
        .virtual_address = readIntLE(u32, data, offset),
        .size = readIntLE(u32, data, offset + 4),
    };
}

// Helper: read CLR header
fn readCLRHeader(data: []const u8, offset: u32) clr_format.CLR_HEADER {
    return clr_format.CLR_HEADER{
        .cb = readIntLE(u32, data, offset),
        .major_runtime_version = readIntLE(u16, data, offset + 4),
        .minor_runtime_version = readIntLE(u16, data, offset + 6),
        .metadata = .{
            .virtual_address = readIntLE(u32, data, offset + 8),
            .size = readIntLE(u32, data, offset + 12),
        },
        .flags = readIntLE(u32, data, offset + 16),
        .entry_point_token = readIntLE(u32, data, offset + 20),
        .resources = .{
            .virtual_address = readIntLE(u32, data, offset + 24),
            .size = readIntLE(u32, data, offset + 28),
        },
        .strong_name_signature = .{
            .virtual_address = readIntLE(u32, data, offset + 32),
            .size = readIntLE(u32, data, offset + 36),
        },
        .code_manager = .{
            .virtual_address = readIntLE(u32, data, offset + 40),
            .size = readIntLE(u32, data, offset + 44),
        },
        .vtable_fixups = .{
            .virtual_address = readIntLE(u32, data, offset + 48),
            .size = readIntLE(u32, data, offset + 52),
        },
        .export_address_table_jumps = .{
            .virtual_address = readIntLE(u32, data, offset + 56),
            .size = readIntLE(u32, data, offset + 60),
        },
        .native_header = .{
            .virtual_address = readIntLE(u32, data, offset + 64),
            .size = readIntLE(u32, data, offset + 68),
        },
    };
}

// Helper: convert RVA to file offset
fn rvaToOffset(data: []const u8, pe_header_offset: u32, num_sections: u16, rva: u32) !u32 {
    // Read size_of_optional_header from COFF file header at offset + 16
    const size_of_optional_header = readIntLE(u16, data, pe_header_offset + 16);
    // Section headers start after COFF header (20 bytes) + optional header + data directories
    const section_headers_offset = pe_header_offset + @sizeOf(PEHeader) + size_of_optional_header;

    // Find the section containing this RVA
    var i: u16 = 0;
    while (i < num_sections) : (i += 1) {
        const section_offset = section_headers_offset + i * @sizeOf(SectionHeader);
        if (section_offset + @sizeOf(SectionHeader) > data.len) return error.InvalidOffset;

        const section = readSectionHeader(data, section_offset);

        if (rva >= section.virtual_address and rva < section.virtual_address + section.virtual_size) {
            const section_rva_offset = rva - section.virtual_address;
            return section.pointer_to_raw_data + section_rva_offset;
        }
    }

    return error.RVANotFound;
}

// Helper: read section header
fn readSectionHeader(data: []const u8, offset: u32) SectionHeader {
    var name: [8]u8 = undefined;
    @memcpy(&name, data[offset .. offset + 8]);

    return SectionHeader{
        .name = name,
        .virtual_size = readIntLE(u32, data, offset + 8),
        .virtual_address = readIntLE(u32, data, offset + 12),
        .size_of_raw_data = readIntLE(u32, data, offset + 16),
        .pointer_to_raw_data = readIntLE(u32, data, offset + 20),
        .pointer_to_relocations = readIntLE(u32, data, offset + 24),
        .pointer_to_line_numbers = readIntLE(u32, data, offset + 28),
        .number_of_relocations = readIntLE(u16, data, offset + 32),
        .number_of_line_numbers = readIntLE(u16, data, offset + 34),
        .characteristics = readIntLE(u32, data, offset + 36),
    };
}
