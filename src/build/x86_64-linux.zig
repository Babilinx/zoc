const std = @import("std");
const CodeGen = @import("../codegen.zig");

const StringBytes = std.ArrayList(u8);

const Size = union(enum) {
    void,
    byte,
    word,
    dword,
    qword,
    custom: u8,

    fn toString(size: Size) []const u8 {
        return switch (size) {
            .void => "",
            .byte => "byte",
            .word => "word",
            .dword => "dword",
            .qword => "qword",
            .custom => "custom",
        };
    }
    fn intToSize(size: u8) Size {
        return switch (size) {
            0 => .void,
            1 => .byte,
            2 => .word,
            4 => .dword,
            8 => .qword,
            else => |val| .{ .custom = val },
        };
    }
};

const Reg = enum {
    rax,
    rbx,
    rcx,
    rdx,
    rsp,
    rbp,
    rdi,
    rsi,
    r8,
    r9,
    r10,
    r11,
    r12,
    r13,
    r14,
    r15,

    fn toString(reg: Reg) []const u8 {
        return switch (reg) {
            .rax => "rax",
            .rbx => "rbx",
            .rcx => "rcx",
            .rdx => "rdx",
            .rsp => "rsp",
            .rbp => "rbp",
            .rdi => "rdi",
            .rsi => "rsi",
            .r8 => "r8",
            .r9 => "r9",
            .r10 => "r10",
            .r11 => "r11",
            .r12 => "r12",
            .r13 => "r13",
            .r14 => "r14",
            .r15 => "r15",
            //else => "_",
        };
    }
};

const FnArgs = union { reg: Reg, str: []const u8, field: AsmField };

const SplitFn = struct { func: fn (anytype) []u8, args: FnArgs };

pub fn init(c: *CodeGen) !void {
    const head =
        \\format ELF64 executable 3
        \\wstack_len = 1024*4
        \\
        \\
    ;

    const start_body =
        \\segment executable
        \\entry _start
        \\
        \\_start:
        \\    push rbp
        \\    push rbx
        \\    push r12
        \\    push r13
        \\    push r14
        \\    push r15
        \\
        \\    mov rbp, rsp
        \\    mov rbx, rsp
        \\
        \\    sub rsp, wstack_len
        \\
        \\    zoc_call 0, 8
        \\
        \\    zoc_pop_qword rdi
        \\
        \\    mov rsp, rbp
        \\    pop r15
        \\    pop r14
        \\    pop r13
        \\    pop r12
        \\    pop rbx
        \\    pop rbp
        \\
        \\    mov rax, 60
        \\    syscall
        \\
        \\
    ;

    const base_macros =
        \\macro zoc_push_qword reg* {
        \\    push reg
        \\    sub rbx, 8
        \\    mov qword [rbx], rsp
        \\}
        \\
        \\macro zoc_pop_qword reg* {
        \\    mov rdx, qword [rbx]
        \\    mov reg, qword [rdx]
        \\    add rbx, 8
        \\}
        \\
        \\macro zoc_call id*, ret_bytes {
        \\    ; reserve bytes if necessary
        \\    sub rsp, ret_bytes
        \\    call fn_#id
        \\}
        \\
        \\macro zoc_fn id* {
        \\fn_#id:
        \\    push rbp
        \\    mov rbp, rsp
        \\}
        \\
        \\macro zoc_ret {
        \\    mov rsp, rbp
        \\    pop rbp
        \\    ret
        \\}
        \\
        \\macro zoc_ret_qword {
        \\    ; Get the current TOS value into rax
        \\    mov rdx, qword [rbx]
        \\    mov rax, qword [rdx]
        \\    ; Store rax in the reserved space
        \\    ; (add 16 to skip the return address and old rbp)
        \\    mov qword [rbp + 16], rax
        \\    ; Update the TOS pointer to the new location of the value
        \\    mov rax, rbp
        \\    add rax, 16
        \\    mov qword [rbx], rax
        \\
        \\    zoc_ret
        \\}
        \\
    ;

    // const _start_body: []const []const u8 = .{
    //     "segment executable\n",
    //     "entry _start\n",
    //     label(buf, "_start"),
    //     comment(buf, "; Setup wstack frame", .{}),
    //     push(buf, .{ .reg = .rbp }),
    //     comment(buf, " Save all calle-saved registers", .{}),
    //     push(buf, .{ .reg = .rbx }),
    //     push(buf, .{ .reg = .r12 }),
    //     push(buf, .{ .reg = .r13 }),
    //     push(buf, .{ .reg = .r14 }),
    //     push(buf, .{ .reg = .r15 }),
    //     mov(buf, .{ .reg = .rbp }, .{ .reg = .rsp }),
    //     comment(buf, " rbx is used as the pointer to the top of wstack", .{}),
    //     mov(&buf, .{ .reg = .rbx }, .{ .reg = .rsp }),
    //     comment(&buf, " Reserve bytes for wstack", .{}),
    //     sub(&buf, .{ .reg = .rsp }, .{ .identifier = "wstack_len" }),
    //     comment(&buf, "; Call the main function", .{}),
    //     zoc_call_fn(&buf, 0, 8),
    //     comment(&buf, " Get the return code", .{}),
    //     zoc_pop(&buf, .{ .reg = .rdi }, .qword),
    //     comment(&buf, "; Restore the state", .{}),
    //     mov(&buf, .{ .reg = .rsp }, .{ .reg = .rbp }),
    //     pop(&buf, .{ .reg = .r15 }),
    //     pop(&buf, .{ .reg = .r14 }),
    //     pop(&buf, .{ .reg = .r13 }),
    //     pop(&buf, .{ .reg = .rbx }),
    //     pop(&buf, .{ .reg = .rbp }),
    //     comment(&buf, "; Exit syscall", .{}),
    //     mov(&buf, .{ .reg = .rax }, .{ .value = 60 }),
    //     "syscall\n",
    // };

    try c.string_bytes.appendSlice(head);

    try c.string_bytes.appendSlice(base_macros);

    try c.string_bytes.appendSlice(start_body);
}

pub fn genPush(c: *CodeGen) !void {
    const index = c.index;
    const gpa = c.gpa;
    const data = c.llir.instructions.get(index).data.push;
    const value = c.llir.extra[data.value];
    const size = Size.intToSize(data.size);

    var buffer = StringBytes.init(gpa);
    var buf: [128]u8 = undefined;
    defer buffer.deinit();

    var line: []const u8 = undefined;

    try c.string_bytes.appendSlice(comment(&buf, " {}: {s}", .{ value, @tagName(size) }));
    line = mov(&buf, .{ .reg = .rax }, .{ .value = value });
    try c.string_bytes.appendSlice(line);
    line = zoc_push(&buf, .{ .reg = .rax }, size);
    try c.string_bytes.appendSlice(line);
}

pub fn genFn(c: *CodeGen) !void {
    const index = c.index;
    const data = c.llir.instructions.get(index).data.func;
    const id = data.id;
    const ret_size = Size.intToSize(data.ret_size);

    var buf: [128]u8 = undefined;
    var line: []const u8 = undefined;

    line = comment(&buf, " fn {} -> {s}", .{ id, @tagName(ret_size) });
    try c.string_bytes.appendSlice(line);
    line = zoc_fn(&buf, id);
    try c.string_bytes.appendSlice(line);
}

pub fn genRet(c: *CodeGen) !void {
    const index = c.index;
    const data = c.llir.instructions.get(index).data.ret;
    const size = Size.intToSize(data.size);

    var buf: [128]u8 = undefined;
    var line: []const u8 = undefined;

    line = zoc_ret(&buf, size);
    try c.string_bytes.appendSlice(line);
}

pub fn genCall(c: *CodeGen) !void {
    const data = c.llir.instructions.get(c.index).data.call;
    const ret_size = Size.intToSize(data.ret_size);
    const id = data.id;

    var buf: [128]u8 = undefined;
    var line: []const u8 = undefined;

    line = zoc_call(&buf, id, ret_size);
    try c.string_bytes.appendSlice(line);
}

pub fn genAdd(c: *CodeGen) !void {
    // const index = c.index;
    // const data = c.llir.instructions.get(index).data.bin_op;
    // const lhs_size = Size.intToSize(data.lhs_size);
    // const rhs_size = Size.IntToSize(data.rhs_zise);
    // const ret_size = Size.intToSize(data.ret_size);

    var buf: [128]u8 = undefined;
    var line: []const u8 = undefined;

    line = comment(&buf, " +", .{});
    try c.string_bytes.appendSlice(line);
    line = zoc_pop(&buf, .{ .reg = .rax }, .qword);
    try c.string_bytes.appendSlice(line);
    line = mov(&buf, .{ .reg = .rdx }, .{ .mem_reg = .{ .size = .qword, .reg = .rbx } });
    try c.string_bytes.appendSlice(line);
    line = add(&buf, .{ .mem_reg = .{ .reg = .rdx, .size = .qword } }, .{ .reg = .rax });
    try c.string_bytes.appendSlice(line);
}

const AsmField = union(enum) {
    reg: Reg,
    mem_reg: MemReg,
    mem_reg_op: MemRegOp,
    value: u64,
    identifier: []const u8,

    const MemReg = struct {
        reg: Reg,
        size: Size,
    };

    const MemRegOp = struct {
        reg: Reg,
        size: Size,
        value: u16,
        op: enum { add, sub },
    };

    fn toString(buffer: []u8, field: AsmField) []const u8 {
        switch (field) {
            .reg => |reg| {
                const reg_str = Reg.toString(reg);
                return std.fmt.bufPrint(buffer, "{s}", .{reg_str}) catch {
                    std.log.err("AsmField.toString(Reg): No space left", .{});
                    std.process.exit(1);
                };
            },
            .mem_reg => |mem_reg| {
                const size_str = Size.toString(mem_reg.size);
                const reg_str = Reg.toString(mem_reg.reg);
                return std.fmt.bufPrint(buffer, "{s} [{s}]", .{ size_str, reg_str }) catch {
                    std.log.err("AsmField.toString(MemReg): No space left", .{});
                    std.process.exit(1);
                };
            },
            .mem_reg_op => |mem_reg_op| {
                const size_str = Size.toString(mem_reg_op.size);
                const reg_str = Reg.toString(mem_reg_op.reg);
                const op_str = switch (mem_reg_op.op) {
                    .add => "+",
                    .sub => "-",
                };

                return std.fmt.bufPrint(buffer, "{s} [{s} {s} {}]", .{ size_str, reg_str, op_str, mem_reg_op.value }) catch {
                    std.log.err("AsmField.toString(MemRegOp): No space left", .{});
                    std.process.exit(1);
                };
            },
            .value => |val| {
                return std.fmt.bufPrint(buffer, "{}", .{val}) catch {
                    std.log.err("AsmField.toString(Value): No space left", .{});
                    std.process.exit(1);
                };
            },
            .identifier => |id| {
                return id;
            },
        }
    }
};

const MacroArg = struct {
    name: []const u8,
    required: bool,

    fn toString(arg: MacroArg) []const u8 {
        var buffer: [32]u8 = undefined;

        if (arg.required) {
            return std.fmt.bufPrint(&buffer, "{s}*", .{arg.name}) catch {
                std.log.err("MacroArg.toString: No space left", .{});
                std.process.exit(1);
            };
        }
        return arg.name;
    }
};

fn macro(gpa: std.mem.Allocator, name: []const u8, args: []MacroArg, body: [][]u8) ![]const u8 {
    var buffer = StringBytes.init(gpa);

    try buffer.appendSlice("macro ");
    try buffer.appendSlice(name);
    try buffer.append(' ');

    if (args.len == 0) {
        buffer.appendSlice(MacroArg.toString(args));
    } else {
        for (args) |arg| {
            try buffer.appendSlice(MacroArg.toString(arg));
            try buffer.appendSlice(", ");
        } else {
            _ = try buffer.orderedRemove(buffer.items.len - 2); // remove the ','
        }
    }

    try buffer.appendSlice("{ \n");

    for (body) |element| {
        try buffer.appendSlice(element);
    }

    try buffer.appendSlice("}\n");

    return buffer.toOwnedSlice();
}

fn label(buffer: []u8, name: []const u8) []const u8 {
    return std.fmt.bufPrint(buffer, "{s}:\n", .{name}) catch {
        std.log.err("label: No space left", .{});
        std.process.exit(1);
    };
}

fn comment(buffer: []u8, comptime text: []const u8, args: anytype) []const u8 {
    return std.fmt.bufPrint(buffer, "\t;" ++ text ++ "\n", args) catch {
        std.log.err("comment: No space left", .{});
        std.process.exit(1);
    };
}

fn zoc_push(buffer: []u8, source: AsmField, size: Size) []const u8 {
    var in_buf: [32]u8 = undefined;

    const size_str = Size.toString(size);
    const field_str = AsmField.toString(&in_buf, source);

    return std.fmt.bufPrint(buffer, "\tzoc_push_{s} {s}\n", .{ size_str, field_str }) catch {
        std.log.err("zocPush: No space left", .{});
        std.process.exit(1);
    };
}

fn zoc_pop(buffer: []u8, dest: AsmField, size: Size) []const u8 {
    var in_buf: [32]u8 = undefined;

    const size_str = Size.toString(size);
    const field_str = AsmField.toString(&in_buf, dest);

    return std.fmt.bufPrint(buffer, "\tzoc_pop_{s} {s}\n", .{ size_str, field_str }) catch {
        std.log.err("zocPush: No space left", .{});
        std.process.exit(1);
    };
}

fn zoc_fn(buffer: []u8, fn_id: u32) []const u8 {
    return std.fmt.bufPrint(buffer, "zoc_fn {}\n", .{fn_id}) catch {
        std.log.err("zoc_fn: No space left", .{});
        std.process.exit(1);
    };
}

fn zoc_ret(buffer: []u8, size: Size) []const u8 {
    //var in_buf: [32]u8 = undefined;
    const ret_size = Size.toString(size);

    if (size == .void) {
        return std.fmt.bufPrint(buffer, "zoc_ret", .{}) catch {
            std.log.err("zoc_ret: No space left", .{});
            std.process.exit(1);
        };
    } else {
        return std.fmt.bufPrint(buffer, "zoc_ret_{s}", .{ret_size}) catch {
            std.log.err("zoc_ret: No space left", .{});
            std.process.exit(1);
        };
    }
}

fn zoc_call(buffer: []u8, fn_id: u32, ret_size: Size) []const u8 {
    return std.fmt.bufPrint(buffer, "\tzoc_call {}, {s}\n", .{ fn_id, Size.toString(ret_size) }) catch {
        std.log.err("zoc_call_fn: No space left", .{});
        std.process.exit(1);
    };
}

fn mov(buffer: []u8, dest: AsmField, source: AsmField) []const u8 {
    var in_buf_a: [32]u8 = undefined;
    var in_buf_b: [32]u8 = undefined;

    return std.fmt.bufPrint(buffer, "\tmov {s}, {s}\n", .{ AsmField.toString(&in_buf_a, dest), AsmField.toString(&in_buf_b, source) }) catch {
        std.log.err("mov: No space left", .{});
        std.process.exit(1);
    };
}

fn push(buffer: []u8, source: AsmField) []const u8 {
    var in_buf: [32]u8 = undefined;

    return std.fmt.bufPrint(buffer, "\tpush {s}\n", .{AsmField.toString(&in_buf, source)}) catch {
        std.log.err("push: No space left", .{});
        std.process.exit(1);
    };
}

fn pop(buffer: []u8, dest: AsmField) []const u8 {
    var in_buf: [32]u8 = undefined;

    return std.fmt.bufPrint(buffer, "\tpop {s}\n", .{AsmField.toString(&in_buf, dest)}) catch {
        std.log.err("pop: No space left", .{});
        std.process.exit(1);
    };
}

fn add(buffer: []u8, dest: AsmField, source: AsmField) []const u8 {
    var in_buf_a: [32]u8 = undefined;
    var in_buf_b: [32]u8 = undefined;

    const dest_str = AsmField.toString(&in_buf_a, dest);
    const source_str = AsmField.toString(&in_buf_b, source);

    return std.fmt.bufPrint(buffer, "\tadd {s}, {s}\n", .{ dest_str, source_str }) catch {
        std.log.err("add: No space left", .{});
        std.process.exit(1);
    };
}

fn sub(buffer: []u8, dest: AsmField, source: AsmField) []const u8 {
    var in_buf_a: [32]u8 = undefined;
    var in_buf_b: [32]u8 = undefined;

    const dest_str = AsmField.toString(&in_buf_a, dest);
    const source_str = AsmField.toString(&in_buf_b, source);

    return std.fmt.bufPrint(buffer, "\tsub {s}, {s}\n", .{ dest_str, source_str }) catch {
        std.log.err("sub: No space left", .{});
        std.process.exit(1);
    };
}
