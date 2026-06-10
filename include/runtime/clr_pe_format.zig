const std = @import("std");

// CLR PE format constants and structures
// Based on ECMA-335 Common Language Infrastructure

pub const COMIMAGE_FLAGS_ILONLY = 0x00000001;
pub const COMIMAGE_FLAGS_32BITREQUIRED = 0x00000002;
pub const COMIMAGE_FLAGS_IL_LIBRARY = 0x00000020;
pub const COMIMAGE_FLAGS_STRONGNAMESIGNED = 0x00000008;
pub const COMIMAGE_FLAGS_NATIVE_ENTRYPOINT = 0x00000010;
pub const COMIMAGE_FLAGS_TRACKDEBUGDATA = 0x00010000;

pub const CLR_DATA_DIRECTORY = struct {
    virtual_address: u32,
    size: u32,
};

pub const CLR_HEADER = struct {
    cb: u32, // Size of CLR header
    major_runtime_version: u16,
    minor_runtime_version: u16,
    metadata: CLR_DATA_DIRECTORY,
    flags: u32,
    entry_point_token: u32, // MethodDef or File token
    resources: CLR_DATA_DIRECTORY,
    strong_name_signature: CLR_DATA_DIRECTORY,
    code_manager: CLR_DATA_DIRECTORY, // deprecated
    vtable_fixups: CLR_DATA_DIRECTORY, // deprecated
    export_address_table_jumps: CLR_DATA_DIRECTORY, // deprecated
    native_header: CLR_DATA_DIRECTORY, // precompiled header
};

pub const METADATA_HEADER = struct {
    signature: u32, // Must be 0x424A5342 (BSJB)
    major_version: u16,
    minor_version: u16,
    reserved: u32,
    version_length: u32,
    flags: u16,
    streams: u16,
};

pub const METADATA_STREAM_HEADER = struct {
    offset: u32,
    size: u32,
    name: [32]u8, // Null-terminated, padded to 4-byte boundary
};

// Stream names
pub const STREAM_TABLES = "#~";
pub const STREAM_STRING = "#Strings";
pub const STREAM_BLOB = "#Blob";
pub const STREAM_GUID = "#GUID";
pub const STREAM_US = "#US"; // User strings

// Metadata tables
pub const TABLE_MODULE = 0x00;
pub const TABLE_TYPEREF = 0x01;
pub const TABLE_TYPEDEF = 0x02;
pub const TABLE_FIELDPTR = 0x03;
pub const TABLE_FIELD = 0x04;
pub const TABLE_METHODDEFPTR = 0x05;
pub const TABLE_METHODDEF = 0x06;
pub const TABLE_PARAMPTR = 0x07;
pub const TABLE_PARAM = 0x08;
pub const TABLE_INTERFACEIMPL = 0x09;
pub const TABLE_MEMBERREF = 0x0A;
pub const TABLE_CONSTANT = 0x0B;
pub const TABLE_CUSTOMATTRIBUTE = 0x0C;
pub const TABLE_FIELDMARSHAL = 0x0D;
pub const TABLE_DECLSECURITY = 0x0E;
pub const TABLE_CLASSLAYOUT = 0x0F;
pub const TABLE_FIELDLAYOUT = 0x10;
pub const TABLE_STANDBALONE_SIG = 0x11;
pub const TABLE_EVENTMAP = 0x12;
pub const TABLE_EVENTPTR = 0x13;
pub const TABLE_EVENT = 0x14;
pub const TABLE_PROPERTYMAP = 0x15;
pub const TABLE_PROPERTYPTR = 0x16;
pub const TABLE_PROPERTY = 0x17;
pub const TABLE_METHODSEMANTICS = 0x18;
pub const TABLE_METHODIMPL = 0x19;
pub const TABLE_MODULEREF = 0x1A;
pub const TABLE_TYPESPEC = 0x1B;
pub const TABLE_IMPLMAP = 0x1C;
pub const TABLE_FIELDRVA = 0x1D;
pub const TABLE_ENCLOG = 0x1E;
pub const TABLE_ENCMAP = 0x1F;
pub const TABLE_ASSEMBLY = 0x20;
pub const TABLE_ASSEMBLYPROCESSOR = 0x21;
pub const TABLE_ASSEMBLYOS = 0x22;
pub const TABLE_ASSEMBLYREF = 0x23;
pub const TABLE_ASSEMBLYREFPROCESSOR = 0x24;
pub const TABLE_ASSEMBLYREFOS = 0x25;
pub const TABLE_FILE = 0x26;
pub const TABLE_EXPORTEDTYPE = 0x27;
pub const TABLE_MANIFESTRESOURCE = 0x28;
pub const TABLE_NESTEDCLASS = 0x29;
pub const TABLE_GENERICPARAM = 0x2A;
pub const TABLE_METHODSPEC = 0x2B;
pub const TABLE_GENERICPARAMCONSTRAINT = 0x2C;

// Token structure: Table index in low 8 bits, row index in upper 24 bits
pub fn makeToken(table_id: u8, row_index: u32) u32 {
    return (@as(u32, row_index) << 1) | @as(u32, table_id);
}

pub fn getTokenTable(token: u32) u8 {
    return @intCast(token & 0xFF);
}

pub fn getTokenRow(token: u32) u32 {
    return token >> 1;
}

// Standard ECMA-335 token encoding: table in upper 8 bits, row in lower 24 bits
// Used for PE file tokens (CLR header entry_point, TypeDef.extends, etc.)
pub fn standardTokenTable(token: u32) u8 {
    return @intCast(token >> 24);
}

pub fn standardTokenRow(token: u32) u32 {
    return token & 0x00FFFFFF;
}

pub fn makeStandardToken(table_id: u8, row_index: u32) u32 {
    return (@as(u32, table_id) << 24) | (row_index & 0x00FFFFFF);
}

// Method body header flags
pub const METHOD_HEADER_TINY = 0x02;
pub const METHOD_HEADER_FAT = 0x03;
pub const METHOD_HEADER_MORE_SECTS = 0x08;
pub const METHOD_HEADER_INIT_LOCALS = 0x10;

pub const TINY_HEADER_SIZE: u32 = 1;
pub const FAT_HEADER_SIZE: u32 = 12;

pub fn isTinyMethod(flags: u8) bool {
    return (flags & 0x03) == METHOD_HEADER_TINY;
}

pub fn isFatMethod(flags: u8) bool {
    return (flags & 0x03) == METHOD_HEADER_FAT;
}

pub fn tinyMethodCodeSize(flags: u8) u32 {
    return @as(u32, flags >> 2);
}

pub fn fatMethodFlags(flags_low: u8, flags_high: u8) u16 {
    return (@as(u16, flags_high) << 8) | flags_low;
}

// Type signatures
pub const ELEMENT_TYPE_END = 0x00;
pub const ELEMENT_TYPE_VOID = 0x01;
pub const ELEMENT_TYPE_BOOLEAN = 0x02;
pub const ELEMENT_TYPE_CHAR = 0x03;
pub const ELEMENT_TYPE_I1 = 0x04;
pub const ELEMENT_TYPE_U1 = 0x05;
pub const ELEMENT_TYPE_I2 = 0x06;
pub const ELEMENT_TYPE_U2 = 0x07;
pub const ELEMENT_TYPE_I4 = 0x08;
pub const ELEMENT_TYPE_U4 = 0x09;
pub const ELEMENT_TYPE_I8 = 0x0A;
pub const ELEMENT_TYPE_U8 = 0x0B;
pub const ELEMENT_TYPE_R4 = 0x0C;
pub const ELEMENT_TYPE_R8 = 0x0D;
pub const ELEMENT_TYPE_STRING = 0x0E;
pub const ELEMENT_TYPE_PTR = 0x0F;
pub const ELEMENT_TYPE_BYREF = 0x10;
pub const ELEMENT_TYPE_VALUETYPE = 0x11;
pub const ELEMENT_TYPE_CLASS = 0x12;
pub const ELEMENT_TYPE_VAR = 0x13;
pub const ELEMENT_TYPE_ARRAY = 0x14;
pub const ELEMENT_TYPE_GENERICINST = 0x15;
pub const ELEMENT_TYPE_TYPEDBYREF = 0x16;
pub const ELEMENT_TYPE_I = 0x18;
pub const ELEMENT_TYPE_U = 0x19;
pub const ELEMENT_TYPE_FNPTR = 0x1B;
pub const ELEMENT_TYPE_OBJECT = 0x1C;
pub const ELEMENT_TYPE_SZARRAY = 0x1D;
pub const ELEMENT_TYPE_CMOD_REQD = 0x1F;
pub const ELEMENT_TYPE_CMOD_OPT = 0x20;
pub const ELEMENT_TYPE_INTERNAL = 0x21;
pub const ELEMENT_TYPE_MODIFIER = 0x40;
pub const ELEMENT_TYPE_SENTINEL = 0x41;
pub const ELEMENT_TYPE_PINNED = 0x45;

// IL Instruction opcodes
pub const CEE_NOP = 0x00;
pub const CEE_BREAK = 0x01;
pub const CEE_LDARG_0 = 0x02;
pub const CEE_LDARG_1 = 0x03;
pub const CEE_LDARG_2 = 0x04;
pub const CEE_LDARG_3 = 0x05;
pub const CEE_LDLOC_0 = 0x06;
pub const CEE_LDLOC_1 = 0x07;
pub const CEE_LDLOC_2 = 0x08;
pub const CEE_LDLOC_3 = 0x09;
pub const CEE_STLOC_0 = 0x0A;
pub const CEE_STLOC_1 = 0x0B;
pub const CEE_STLOC_2 = 0x0C;
pub const CEE_STLOC_3 = 0x0D;
pub const CEE_LDNULL = 0x14;
pub const CEE_LDC_I4_M1 = 0x15;
pub const CEE_LDC_I4_0 = 0x16;
pub const CEE_LDC_I4_1 = 0x17;
pub const CEE_LDC_I4_2 = 0x18;
pub const CEE_LDC_I4_3 = 0x19;
pub const CEE_LDC_I4_4 = 0x1A;
pub const CEE_LDC_I4_5 = 0x1B;
pub const CEE_LDC_I4_6 = 0x1C;
pub const CEE_LDC_I4_7 = 0x1D;
pub const CEE_LDC_I4_8 = 0x1E;
pub const CEE_LDC_I4_S = 0x1F;
pub const CEE_LDC_I4 = 0x20;
pub const CEE_LDC_I8 = 0x21;
pub const CEE_LDC_R4 = 0x22;
pub const CEE_LDC_R8 = 0x23;
pub const CEE_LDSTR = 0x72;
pub const CEE_NEWOBJ = 0x73;
pub const CEE_CALL = 0x28;
pub const CEE_CALLVIRT = 0x6F;
pub const CEE_RET = 0x2A;
pub const CEE_BR = 0x38;
pub const CEE_BRFALSE = 0x39;
pub const CEE_BRTRUE = 0x3A;
pub const CEE_BEQ = 0x3B;
pub const CEE_BGE = 0x3C;
pub const CEE_BGT = 0x3D;
pub const CEE_BLE = 0x3E;
pub const CEE_BLT = 0x3F;
pub const CEE_BNE_UN = 0x3C;
pub const CEE_BGE_UN = 0x3D;
pub const CEE_BGT_UN = 0x3E;
pub const CEE_BLE_UN = 0x3F;
pub const CEE_BLT_UN = 0x40;
pub const CEE_SWITCH = 0x45;
pub const CEE_ADD = 0x58;
pub const CEE_SUB = 0x59;
pub const CEE_MUL = 0x5A;
pub const CEE_DIV = 0x5B;
pub const CEE_DIV_UN = 0x5C;
pub const CEE_REM = 0x5D;
pub const CEE_REM_UN = 0x5E;
pub const CEE_AND = 0x5F;
pub const CEE_OR = 0x60;
pub const CEE_XOR = 0x61;
pub const CEE_SHL = 0x62;
pub const CEE_SHR = 0x63;
pub const CEE_SHR_UN = 0x64;
pub const CEE_NEG = 0x65;
pub const CEE_NOT = 0x66;
pub const CEE_CONV_I1 = 0x67;
pub const CEE_CONV_I2 = 0x68;
pub const CEE_CONV_I4 = 0x69;
pub const CEE_CONV_I8 = 0x6A;
pub const CEE_CONV_R4 = 0x6B;
pub const CEE_CONV_R8 = 0x6C;
pub const CEE_CONV_U4 = 0x6D;
pub const CEE_CONV_U8 = 0x6E;
pub const CEE_CPOBJ = 0x70;
pub const CEE_LDOBJ = 0x71;
pub const CEE_CASTCLASS = 0x74;
pub const CEE_ISINST = 0x75;
pub const CEE_CONV_R_UN = 0x76;
pub const CEE_UNBOX = 0x79;
pub const CEE_THROW = 0x7A;
pub const CEE_LDFLD = 0x7B;
pub const CEE_LDFLDA = 0x7C;
pub const CEE_STFLD = 0x7D;
pub const CEE_LDSFLD = 0x7E;
pub const CEE_LDSFLDA = 0x7F;
pub const CEE_STSFLD = 0x80;
pub const CEE_STOBJ = 0x81;
pub const CEE_CONV_OVF_I1_UN = 0x82;
pub const CEE_CONV_OVF_I2_UN = 0x83;
pub const CEE_CONV_OVF_I4_UN = 0x84;
pub const CEE_CONV_OVF_I8_UN = 0x85;
pub const CEE_CONV_OVF_U1_UN = 0x86;
pub const CEE_CONV_OVF_U2_UN = 0x87;
pub const CEE_CONV_OVF_U4_UN = 0x88;
pub const CEE_CONV_OVF_U8_UN = 0x89;
pub const CEE_CONV_OVF_I_UN = 0x8A;
pub const CEE_CONV_OVF_U_UN = 0x8B;
pub const CEE_BOX = 0x8C;
pub const CEE_NEWARR = 0x8D;
pub const CEE_LDLEN = 0x8E;
pub const CEE_LDELEMA = 0x8F;
pub const CEE_LDELEM_I1 = 0x90;
pub const CEE_LDELEM_U1 = 0x91;
pub const CEE_LDELEM_I2 = 0x92;
pub const CEE_LDELEM_U2 = 0x93;
pub const CEE_LDELEM_I4 = 0x94;
pub const CEE_LDELEM_U4 = 0x95;
pub const CEE_LDELEM_I8 = 0x96;
pub const CEE_LDELEM_I = 0x97;
pub const CEE_LDELEM_R4 = 0x98;
pub const CEE_LDELEM_R8 = 0x99;
pub const CEE_LDELEM_REF = 0x9A;
pub const CEE_STELEM_I = 0x9B;
pub const CEE_STELEM_I1 = 0x9C;
pub const CEE_STELEM_I2 = 0x9D;
pub const CEE_STELEM_I4 = 0x9E;
pub const CEE_STELEM_I8 = 0x9F;
pub const CEE_STELEM_R4 = 0xA0;
pub const CEE_STELEM_R8 = 0xA1;
pub const CEE_STELEM_REF = 0xA2;
pub const CEE_LDELEM = 0xA3;
pub const CEE_STELEM = 0xA4;
pub const CEE_UNBOX_ANY = 0xA5;
pub const CEE_CONV_OVF_I1 = 0xB3;
pub const CEE_CONV_OVF_U1 = 0xB4;
pub const CEE_CONV_OVF_I2 = 0xB5;
pub const CEE_CONV_OVF_U2 = 0xB6;
pub const CEE_CONV_OVF_I4 = 0xB7;
pub const CEE_CONV_OVF_U4 = 0xB8;
pub const CEE_CONV_OVF_I8 = 0xB9;
pub const CEE_CONV_OVF_U8 = 0xBA;
pub const CEE_REFANYVAL = 0xC2;
pub const CEE_CKFINITE = 0xC3;
pub const CEE_MKREFANY = 0xC6;
pub const CEE_REFANYTYPE = 0xC7;
pub const CEE_INITOBJ = 0xCB;
pub const CEE_CONSTRAIN = 0xCE;
pub const CEE_READONLY = 0xCF;
