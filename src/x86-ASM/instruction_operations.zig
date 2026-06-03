const std = @import("std");
const testing = std.testing;
const reg_map = @import("register_mapping.zig");
const Register = reg_map.Register;
const RegisterFile = reg_map.RegisterFile;
const Memory = reg_map.Memory;
const runtime_abi = @import("runtime_abi_handshake");
const reg_trace = @import("register-tracing/runtime.zig");

/// Operand types used by x86 instructions in this emulator.
pub const Operand = union(enum) {
    reg: Register,
    imm: u32,
    mem_direct: u32,    // [address]
    mem_reg: Register,  // [register]
    mem_index: struct { base: Register, index: u32 }, // [reg + offset]
    mem_reg2: struct { base: Register, index: Register }, // [base + index*4]
};

/// Operations executor — holds the machine state and runs instructions.
pub const Executor = struct {
    regs: RegisterFile = .{},
    mem: Memory,
    // Label positions for control-flow resolution (name → address)
    labels: std.StringHashMap(u32),
    // Import handler table — maps external symbol name to handler
    import_table: std.StringHashMap(*const fn (ctx: *Executor) void),
    // Interrupt vector table (256 vectors, for future x86 interrupt dispatch)
    interrupt_vector: [256]?*const fn (*Executor) void = [_]?*const fn (*Executor) void{null} ** 256,

    pub fn init(allocator: std.mem.Allocator, mem_size: u32) Executor {
        return .{
            .mem = Memory.init(allocator, mem_size),
            .labels = std.StringHashMap(u32).init(allocator),
            .import_table = std.StringHashMap(*const fn (ctx: *Executor) void).init(allocator),
        };
    }

    pub fn deinit(self: *Executor) void {
        self.mem.deinit();
        self.labels.deinit();
        self.import_table.deinit();
    }

    // ---- Data movement ----

    pub fn mov_reg_imm(self: *Executor, dst: Register, imm: u32) void {
        self.regs.set(dst, imm);
    }

    pub fn mov_reg_reg(self: *Executor, dst: Register, src: Register) void {
        self.regs.set(dst, self.regs.get(src));
    }

    pub fn mov_reg_mem(self: *Executor, dst: Register, addr: u32) void {
        self.regs.set(dst, self.mem.read32(addr));
    }

    pub fn mov_mem_reg(self: *Executor, addr: u32, src: Register) void {
        self.mem.write32(addr, self.regs.get(src));
    }

    pub fn mov_mem_imm(self: *Executor, addr: u32, imm: u32) void {
        self.mem.write32(addr, imm);
    }

    pub fn movzx_reg_mem(self: *Executor, dst: Register, addr: u32) void {
        self.regs.set(dst, self.mem.read8(addr));
    }

    /// movzx reg, reg (zero-extend from low 16 bits)
    pub fn movzx_reg_reg16(self: *Executor, dst: Register, src: Register) void {
        self.regs.set(dst, self.regs.get16(src));
    }

    pub fn lea_reg_mem(self: *Executor, dst: Register, addr: u32) void {
        self.regs.set(dst, addr);
    }

    // ---- Stack operations ----

    pub fn push(self: *Executor, value: u32) void {
        self.regs.push(&self.mem, value);
    }

    pub fn pop(self: *Executor, dst: Register) void {
        self.regs.set(dst, self.regs.pop(&self.mem));
    }

    // ---- Arithmetic ----

    pub fn add_reg_reg(self: *Executor, dst: Register, src: Register) void {
        const a = self.regs.get(dst);
        const b = self.regs.get(src);
        const flags_before = self.regs.flags.raw();
        const result = a +% b;
        self.regs.update_zsco(a, b, result, false);
        self.regs.set(dst, result);
        runtime_abi.x86.validateArithmetic32(.add, a, b, result, self.regs.flags.zf, self.regs.flags.sf, self.regs.flags.cf, self.regs.flags.of);
        reg_trace.logOperation("add_reg_reg", "add", a, b, result, 32, flags_before, self.regs.flags.raw());
    }

    pub fn add_reg_imm(self: *Executor, dst: Register, imm: u32) void {
        const a = self.regs.get(dst);
        const flags_before = self.regs.flags.raw();
        const result = a +% imm;
        self.regs.update_zsco(a, imm, result, false);
        self.regs.set(dst, result);
        runtime_abi.x86.validateArithmetic32(.add, a, imm, result, self.regs.flags.zf, self.regs.flags.sf, self.regs.flags.cf, self.regs.flags.of);
        reg_trace.logOperation("add_reg_imm", "add", a, imm, result, 32, flags_before, self.regs.flags.raw());
    }

    pub fn sub_reg_reg(self: *Executor, dst: Register, src: Register) void {
        const a = self.regs.get(dst);
        const b = self.regs.get(src);
        const flags_before = self.regs.flags.raw();
        const result = a -% b;
        self.regs.update_zsco(a, b, result, true);
        self.regs.set(dst, result);
        runtime_abi.x86.validateArithmetic32(.sub, a, b, result, self.regs.flags.zf, self.regs.flags.sf, self.regs.flags.cf, self.regs.flags.of);
        reg_trace.logOperation("sub_reg_reg", "sub", a, b, result, 32, flags_before, self.regs.flags.raw());
    }

    pub fn sub_reg_imm(self: *Executor, dst: Register, imm: u32) void {
        const a = self.regs.get(dst);
        const flags_before = self.regs.flags.raw();
        const result = a -% imm;
        self.regs.update_zsco(a, imm, result, true);
        self.regs.set(dst, result);
        runtime_abi.x86.validateArithmetic32(.sub, a, imm, result, self.regs.flags.zf, self.regs.flags.sf, self.regs.flags.cf, self.regs.flags.of);
        reg_trace.logOperation("sub_reg_imm", "sub", a, imm, result, 32, flags_before, self.regs.flags.raw());
    }

    pub fn inc(self: *Executor, dst: Register) void {
        const val = self.regs.get(dst);
        const flags_before = self.regs.flags.raw();
        const result = val +% 1;
        self.regs.update_zs(result);
        self.regs.flags.of = if (val == 0x7FFFFFFF) 1 else 0;
        self.regs.set(dst, result);
        runtime_abi.x86.validateArithmetic32(.inc, val, 1, result, self.regs.flags.zf, self.regs.flags.sf, self.regs.flags.cf, self.regs.flags.of);
        reg_trace.logOperation("inc", "inc", val, 1, result, 32, flags_before, self.regs.flags.raw());
    }

    pub fn dec(self: *Executor, dst: Register) void {
        const val = self.regs.get(dst);
        const flags_before = self.regs.flags.raw();
        const result = val -% 1;
        self.regs.update_zs(result);
        self.regs.flags.of = if (val == 0x80000000) 1 else 0;
        self.regs.set(dst, result);
        runtime_abi.x86.validateArithmetic32(.dec, val, 1, result, self.regs.flags.zf, self.regs.flags.sf, self.regs.flags.cf, self.regs.flags.of);
        reg_trace.logOperation("dec", "dec", val, 1, result, 32, flags_before, self.regs.flags.raw());
    }

    pub fn mul_reg(self: *Executor, src: Register) void {
        // unsigned mul: EDX:EAX = EAX * src
        const a = self.regs.eax;
        const b = self.regs.get(src);
        const flags_before = self.regs.flags.raw();
        const result = @as(u64, a) * @as(u64, b);
        self.regs.eax = @truncate(result);
        self.regs.edx = @truncate(result >> 32);
        self.regs.flags.cf = if (self.regs.edx != 0) 1 else 0;
        self.regs.flags.of = self.regs.flags.cf;
        runtime_abi.x86.validateMul32(false, a, b, self.regs.eax, self.regs.edx, self.regs.flags.cf, self.regs.flags.of);
        reg_trace.logOperation("mul_reg", "mul", a, b, result, 64, flags_before, self.regs.flags.raw());
    }

    pub fn imul_reg(self: *Executor, src: Register) void {
        // signed mul: EDX:EAX = EAX * src
        const a = @as(i32, @bitCast(self.regs.eax));
        const b = @as(i32, @bitCast(self.regs.get(src)));
        const flags_before = self.regs.flags.raw();
        const result = @as(i64, a) * @as(i64, b);
        self.regs.eax = @truncate(@as(u64, @bitCast(result)));
        self.regs.edx = @truncate(@as(u64, @bitCast(result >> 32)));
        self.regs.flags.cf = if (self.regs.edx != (self.regs.eax >> 31)) 1 else 0;
        self.regs.flags.of = self.regs.flags.cf;
        runtime_abi.x86.validateMul32(true, @bitCast(a), @bitCast(b), self.regs.eax, self.regs.edx, self.regs.flags.cf, self.regs.flags.of);
        reg_trace.logOperation(
            "imul_reg",
            "imul",
            @as(u64, @as(u32, @bitCast(a))),
            @as(u64, @as(u32, @bitCast(b))),
            @as(u64, @bitCast(result)),
            64,
            flags_before,
            self.regs.flags.raw(),
        );
    }

    pub fn div_reg(self: *Executor, src: Register) void {
        // unsigned div: EAX = EDX:EAX / src, EDX = remainder
        const divisor = self.regs.get(src);
        const edx_before = self.regs.edx;
        const eax_before = self.regs.eax;
        const flags_before = self.regs.flags.raw();
        if (divisor == 0) {
            runtime_abi.x86.validateDiv32(edx_before, eax_before, divisor, self.regs.eax, self.regs.edx);
            reg_trace.logOperation("div_reg", "div", (@as(u64, edx_before) << 32) | eax_before, divisor, 0, 64, flags_before, self.regs.flags.raw());
            return;
        }
        const dividend = (@as(u64, self.regs.edx) << 32) | self.regs.eax;
        self.regs.eax = @truncate(dividend / divisor);
        self.regs.edx = @truncate(dividend % divisor);
        runtime_abi.x86.validateDiv32(edx_before, eax_before, divisor, self.regs.eax, self.regs.edx);
        reg_trace.logOperation("div_reg", "div", dividend, divisor, self.regs.eax, 32, flags_before, self.regs.flags.raw());
    }

    pub fn xor_reg_reg(self: *Executor, dst: Register, src: Register) void {
        const lhs = self.regs.get(dst);
        const rhs = self.regs.get(src);
        const flags_before = self.regs.flags.raw();
        const result = lhs ^ rhs;
        self.regs.update_test(result);
        self.regs.set(dst, result);
        runtime_abi.x86.validateArithmetic32(.logical, lhs, rhs, result, self.regs.flags.zf, self.regs.flags.sf, self.regs.flags.cf, self.regs.flags.of);
        reg_trace.logOperation("xor_reg_reg", "xor", lhs, rhs, result, 32, flags_before, self.regs.flags.raw());
    }

    pub fn and_reg_reg(self: *Executor, dst: Register, src: Register) void {
        const lhs = self.regs.get(dst);
        const rhs = self.regs.get(src);
        const flags_before = self.regs.flags.raw();
        const result = lhs & rhs;
        self.regs.update_test(result);
        self.regs.set(dst, result);
        runtime_abi.x86.validateArithmetic32(.test_and, lhs, rhs, result, self.regs.flags.zf, self.regs.flags.sf, self.regs.flags.cf, self.regs.flags.of);
        reg_trace.logOperation("and_reg_reg", "and", lhs, rhs, result, 32, flags_before, self.regs.flags.raw());
    }

    pub fn or_reg_reg(self: *Executor, dst: Register, src: Register) void {
        const lhs = self.regs.get(dst);
        const rhs = self.regs.get(src);
        const flags_before = self.regs.flags.raw();
        const result = lhs | rhs;
        self.regs.update_test(result);
        self.regs.set(dst, result);
        runtime_abi.x86.validateArithmetic32(.logical, lhs, rhs, result, self.regs.flags.zf, self.regs.flags.sf, self.regs.flags.cf, self.regs.flags.of);
        reg_trace.logOperation("or_reg_reg", "or", lhs, rhs, result, 32, flags_before, self.regs.flags.raw());
    }

    pub fn not_reg(self: *Executor, dst: Register) void {
        const lhs = self.regs.get(dst);
        const result = ~lhs;
        self.regs.set(dst, result);
        reg_trace.logOperation("not_reg", "not", lhs, 0, result, 32, self.regs.flags.raw(), self.regs.flags.raw());
    }

    pub fn neg_reg(self: *Executor, dst: Register) void {
        const val = self.regs.get(dst);
        const flags_before = self.regs.flags.raw();
        const result = (~val) +% 1;
        self.regs.update_zsco(val, 1, result, true);
        self.regs.set(dst, result);
        reg_trace.logOperation("neg_reg", "neg", val, 0, result, 32, flags_before, self.regs.flags.raw());
    }

    pub fn shl_reg_cl(self: *Executor, dst: Register) void {
        const cnt: u5 = @truncate(self.regs.ecx & 0x1F);
        if (cnt == 0) return;
        const val = self.regs.get(dst);
        const flags_before = self.regs.flags.raw();
        self.regs.set(dst, val << cnt);
        const shift_back: u5 = @truncate(@as(u6, 32) - cnt);
        self.regs.flags.cf = @intCast((val >> shift_back) & 1);
        self.regs.update_zs(self.regs.get(dst));
        reg_trace.logOperation("shl_reg_cl", "shl", val, cnt, self.regs.get(dst), 32, flags_before, self.regs.flags.raw());
    }

    pub fn shr_reg_cl(self: *Executor, dst: Register) void {
        const cnt: u5 = @truncate(self.regs.ecx & 0x1F);
        if (cnt == 0) return;
        const val = self.regs.get(dst);
        const flags_before = self.regs.flags.raw();
        self.regs.flags.cf = @intCast((val >> (cnt - 1)) & 1);
        self.regs.set(dst, val >> cnt);
        self.regs.update_zs(self.regs.get(dst));
        reg_trace.logOperation("shr_reg_cl", "shr", val, cnt, self.regs.get(dst), 32, flags_before, self.regs.flags.raw());
    }

    pub fn ror_reg_cl(self: *Executor, dst: Register) void {
        const count = self.regs.ecx & 0x1F;
        if (count == 0) return;
        const val = self.regs.get(dst);
        self.regs.set(dst, std.math.rotr(u32, val, count));
        self.regs.flags.cf = @intCast((self.regs.get(dst) >> 31) & 1);
    }

    pub fn shl_reg_imm(self: *Executor, dst: Register, count: u5) void {
        if (count == 0) return;
        const val = self.regs.get(dst);
        self.regs.set(dst, val << count);
        const shift_back: u5 = @truncate(@as(u6, 32) - count);
        self.regs.flags.cf = @intCast((val >> shift_back) & 1);
        self.regs.update_zs(self.regs.get(dst));
    }

    // ---- Comparison and test ----

    pub fn cmp_reg_reg(self: *Executor, a: Register, b: Register) void {
        const lhs = self.regs.get(a);
        const rhs = self.regs.get(b);
        const flags_before = self.regs.flags.raw();
        self.regs.update_cmp(lhs, rhs);
        runtime_abi.x86.validateArithmetic32(.cmp, lhs, rhs, lhs -% rhs, self.regs.flags.zf, self.regs.flags.sf, self.regs.flags.cf, self.regs.flags.of);
        reg_trace.logOperation("cmp_reg_reg", "cmp", lhs, rhs, lhs -% rhs, 32, flags_before, self.regs.flags.raw());
    }

    pub fn cmp_reg_imm(self: *Executor, a: Register, imm: u32) void {
        const lhs = self.regs.get(a);
        const flags_before = self.regs.flags.raw();
        self.regs.update_cmp(lhs, imm);
        runtime_abi.x86.validateArithmetic32(.cmp, lhs, imm, lhs -% imm, self.regs.flags.zf, self.regs.flags.sf, self.regs.flags.cf, self.regs.flags.of);
        reg_trace.logOperation("cmp_reg_imm", "cmp", lhs, imm, lhs -% imm, 32, flags_before, self.regs.flags.raw());
    }

    pub fn cmp_mem_imm(self: *Executor, addr: u32, imm: u32) void {
        const lhs = self.mem.read32(addr);
        self.regs.update_cmp(lhs, imm);
        runtime_abi.x86.validateArithmetic32(.cmp, lhs, imm, lhs -% imm, self.regs.flags.zf, self.regs.flags.sf, self.regs.flags.cf, self.regs.flags.of);
    }

    pub fn test_reg_reg(self: *Executor, a: Register, b: Register) void {
        const lhs = self.regs.get(a);
        const rhs = self.regs.get(b);
        const flags_before = self.regs.flags.raw();
        const result = lhs & rhs;
        self.regs.update_test(result);
        runtime_abi.x86.validateArithmetic32(.test_and, lhs, rhs, result, self.regs.flags.zf, self.regs.flags.sf, self.regs.flags.cf, self.regs.flags.of);
        reg_trace.logOperation("test_reg_reg", "test", lhs, rhs, result, 32, flags_before, self.regs.flags.raw());
    }

    // ---- Control flow ----

    pub fn jmp(self: *Executor, target: u32) void {
        self.regs.eip = target;
    }

    pub fn jz(self: *Executor, target: u32) void {
        if (self.regs.flags.zf == 1) self.regs.eip = target;
    }

    pub fn jnz(self: *Executor, target: u32) void {
        if (self.regs.flags.zf == 0) self.regs.eip = target;
    }

    pub fn jne(self: *Executor, target: u32) void {
        self.jnz(target);
    }

    pub fn je(self: *Executor, target: u32) void {
        self.jz(target);
    }

    pub fn jl(self: *Executor, target: u32) void {
        // signed less-than: SF != OF
        if (self.regs.flags.sf != self.regs.flags.of) self.regs.eip = target;
    }

    pub fn jge(self: *Executor, target: u32) void {
        // signed greater-or-equal: SF == OF
        if (self.regs.flags.sf == self.regs.flags.of) self.regs.eip = target;
    }

    pub fn jle(self: *Executor, target: u32) void {
        // signed less-or-equal: ZF=1 or SF != OF
        if (self.regs.flags.zf == 1 or self.regs.flags.sf != self.regs.flags.of)
            self.regs.eip = target;
    }

    pub fn jg(self: *Executor, target: u32) void {
        // signed greater: ZF=0 and SF == OF
        if (self.regs.flags.zf == 0 and self.regs.flags.sf == self.regs.flags.of)
            self.regs.eip = target;
    }

    /// Call a procedure by address (push return address, jump to target).
    pub fn call(self: *Executor, target: u32) void {
        self.push(self.regs.eip);
        self.regs.eip = target;
    }

    /// Return from procedure (pop return address and jump).
    pub fn ret(self: *Executor) void {
        self.regs.eip = self.regs.pop(&self.mem);
    }

    /// Return with immediate pop (pop return address, then pop N additional bytes).
    pub fn ret_imm(self: *Executor, bytes: u16) void {
        self.regs.eip = self.regs.pop(&self.mem);
        self.regs.esp +|= bytes;
    }

    // ---- REPNE SCASB ----
    // repne scasb: compare AL with byte at [EDI], set flags, inc/dec EDI, dec ECX, loop if ECX>0
    pub fn repne_scasb(self: *Executor) void {
        while (self.regs.ecx != 0) {
            self.regs.update_cmp(self.regs.eax & 0xFF, self.mem.read8(self.regs.edi));
            if (self.regs.flags.df == 0)
                self.regs.edi +|= 1
            else
                self.regs.edi -|= 1;
            self.regs.ecx -|= 1;
            if (self.regs.flags.zf == 1) break;
        }
    }

    // ---- Import dispatch ----
    // Look up an external symbol in the import table and call its handler.

    pub fn dispatch_import(self: *Executor, name: []const u8) void {
        if (self.import_table.get(name)) |handler| {
            handler(self);
        }
    }

    // ---- Interrupt dispatch ----
    // Reserved for future x86 interrupt handling (int 0x80, etc.)

    pub fn raise_interrupt(self: *Executor, vector: u8) void {
        if (self.interrupt_vector[vector]) |handler| {
            handler(self);
        }
    }
};

// ---- Tests ----
test "mov and arithmetic" {
    var ex = Executor.init(std.testing.allocator, 4096);
    defer ex.deinit();

    ex.mov_reg_imm(.eax, 42);
    try testing.expectEqual(@as(u32, 42), ex.regs.eax);

    ex.mov_reg_reg(.ebx, .eax);
    try testing.expectEqual(@as(u32, 42), ex.regs.ebx);

    ex.add_reg_imm(.eax, 10);
    try testing.expectEqual(@as(u32, 52), ex.regs.eax);

    ex.sub_reg_imm(.eax, 2);
    try testing.expectEqual(@as(u32, 50), ex.regs.eax);
}

test "push/pop" {
    var ex = Executor.init(std.testing.allocator, 4096);
    defer ex.deinit();

    ex.regs.esp = 2048;
    ex.mov_reg_imm(.eax, 0xCAFEBABE);
    ex.push(ex.regs.eax);
    ex.mov_reg_imm(.eax, 0);
    ex.pop(.eax);
    try testing.expectEqual(@as(u32, 0xCAFEBABE), ex.regs.eax);
}

test "conditional jumps" {
    var ex = Executor.init(std.testing.allocator, 4096);
    defer ex.deinit();

    ex.mov_reg_imm(.eax, 10);
    ex.mov_reg_imm(.ebx, 10);
    ex.cmp_reg_reg(.eax, .ebx);
    try testing.expectEqual(@as(u1, 1), ex.regs.flags.zf);

    ex.mov_reg_imm(.eax, 5);
    ex.mov_reg_imm(.ebx, 10);
    ex.cmp_reg_reg(.eax, .ebx);
    try testing.expectEqual(@as(u1, 1), ex.regs.flags.cf); // borrow for 5-10
}

test "imul" {
    var ex = Executor.init(std.testing.allocator, 4096);
    defer ex.deinit();

    ex.mov_reg_imm(.eax, 7);
    ex.mov_reg_imm(.ecx, 6);
    ex.imul_reg(.ecx);
    try testing.expectEqual(@as(u32, 42), ex.regs.eax);
}

test "repne scasb" {
    var ex = Executor.init(std.testing.allocator, 4096);
    defer ex.deinit();

    const str = "Hello\x00world";
    for (str, 0..) |ch, i| {
        ex.mem.write8(@intCast(100 + i), ch);
    }
    ex.mov_reg_imm(.edi, 100);
    ex.mov_reg_imm(.eax, 'o');  // searching for 'o'
    ex.mov_reg_imm(.ecx, 20);
    ex.repne_scasb();
    try testing.expectEqual(@as(u1, 1), ex.regs.flags.zf); // found
}

test "call/ret" {
    var ex = Executor.init(std.testing.allocator, 4096);
    defer ex.deinit();

    ex.regs.esp = 2048;
    ex.regs.eip = 100;
    ex.call(200);
    try testing.expectEqual(@as(u32, 200), ex.regs.eip);
    // return address should be 100 on stack
    const ret_addr = ex.regs.pop(&ex.mem);
    try testing.expectEqual(@as(u32, 100), ret_addr);
}
