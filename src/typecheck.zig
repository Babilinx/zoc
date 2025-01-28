//! Typecheck Zir instructions and perform `any*` type resolution.
const std = @import("std");

const Zir = @import("zir.zig");
const TypeStack = @import("typestack.zig");
const Type = Zir.Inst.Type;
const Index = u32;
const IndexList = std.ArrayList(Index);
const TypeSlice = Zir.TypeList.Slice;
const InstSlice = Zir.InstList.Slice;
const SubRange = Zir.Inst.SubRange;
const StackNode = TypeStack.StackNode;

const TypeCheck = @This();

gpa: std.mem.Allocator,
insts: InstSlice,
inst_i: Index,
types: TypeSlice,
stack: TypeStack,

pub fn Check(gpa: std.mem.Allocator, zir: *Zir) !Zir {
    var check: TypeCheck = .{
        .gpa = gpa,
        .insts = zir.instructions,
        .inst_i = 0,
        .types = zir.types,
        .stack = TypeStack.init(gpa, zir.types),
    };

    try check.checkTopLevel();

    //try check.typeResolve();

    return Zir{
        .instructions = check.insts,
        .string_bytes = zir.string_bytes,
        .types = check.types,
    };
}

fn checkTopLevel(t: *TypeCheck) !void {
    var i = t.stack.top;

    while (t.insts.get(t.inst_i).tag != .eof) : (t.inst_i += 1) {
        // t.stack.print(i);
        switch (t.insts.get(t.inst_i).tag) {
            .int => i = try t.checkInt(i),
            .bin_op => i = try t.checkBinOp(i),
            .fn_def => i = try t.checkFnDef(i),
            .fn_ret => unreachable,
            else => unreachable,
        }
    }
}

fn checkInt(t: *TypeCheck, i: ?Index) !?Index {
    // std.log.info("\tcheckInt, i: {?}", .{i});
    const data = t.insts.get(t.inst_i).data.int;

    return try t.stack.append(i, data.type);
}

fn checkBinOp(t: *TypeCheck, i: ?Index) !?Index {
    // std.log.info("\tcheckBinOp, i: {?}", .{i});
    var i_ = i;
    var pop: StackNode = undefined;
    var pop_type: Index = undefined;
    const data = t.insts.get(t.inst_i).data.bin_op;
    const lhs_type = data.in_types.start;
    const rhs_type = data.in_types.start + 1;

    pop = try t.stack.pop(i_);
    i_ = pop.prev;
    pop_type = pop.type;
    t.checkTypeCompatibility(pop_type, rhs_type) catch {
        std.log.err("BinOp: Types does not match", .{});
        std.process.exit(1);
    };

    pop = try t.stack.pop(i_);
    i_ = pop.prev;
    pop_type = pop.type;
    t.checkTypeCompatibility(pop_type, lhs_type) catch {
        std.log.err("Binop: Types does not match", .{});
        std.process.exit(1);
    };

    return try t.stack.append(i_, data.ret_type);
}

fn checkFnDef(t: *TypeCheck, i: ?Index) !?Index {
    // std.log.info("\tcheckFnDef, i: {?}", .{i});
    var i_ = i;
    const ret_type = t.insts.get(t.inst_i).data.fn_def.ret_type;
    t.inst_i += 1;
    const fn_end = t.insts.get(t.inst_i).data.fn_proto.end;
    const arg_types = t.insts.get(t.inst_i).data.fn_proto.arg_types;

    i_ = try t.stack.appendSubRange(i_, arg_types);

    t.inst_i += 1;

    while (t.inst_i < fn_end) : (t.inst_i += 1) {
        // t.stack.print(i_);
        switch (t.insts.get(t.inst_i).tag) {
            .bin_op => i_ = try t.checkBinOp(i_),
            .int => i_ = try t.checkInt(i_),
            .fn_call => i_ = try t.checkFnCall(i_),
            .fn_def => i_ = try t.checkFnDef(i_),
            .eof => unreachable,
            else => {},
        }
    }

    const pop = try t.stack.pop(i_);
    i_ = pop.prev;
    const pop_type = pop.type;

    t.checkTypeCompatibility(pop_type, ret_type) catch {
        std.log.err("Function return type does not matches with the trailing type", .{});
        std.process.exit(1);
    };

    return t.stack.eql(i, i_) catch {
        std.log.err("Function definition got a trailing type", .{});
        std.log.err("Expected:", .{});
        t.stack.print(i);
        std.log.err("Got:", .{});
        t.stack.print(i_);
        std.process.exit(1);
    };
}

fn checkFnCall(t: *TypeCheck, i: ?Index) !?Index {
    // std.log.info("\tcheckFnCall, i: {?}", .{i});
    var i_ = i;
    const fn_def = t.insts.get(t.inst_i).data.call;
    const fn_args = t.insts.get(fn_def + 1).data.fn_proto.arg_types;
    const ret_type = t.insts.get(fn_def).data.fn_def.ret_type;

    // t.stack.print(i_);

    if (t.types[fn_args.start] == .void) {
        // std.log.info("\t\tvoid args", .{});
        return try t.stack.append(i_, ret_type);
    }

    const pop = try t.stack.popN(i_, fn_args.len);
    i_ = pop.get(pop.len - 1).prev;

    for (pop.items(.type), 0..) |type_a, index| {
        const type_b = fn_args.start + index;

        t.checkTypeCompatibility(type_a, @intCast(type_b)) catch {
            std.log.err("FnCall: Types does not match: {any}, {any}", .{ t.types[type_a], t.types[type_b] });
            std.process.exit(1);
        };
    }

    return try t.stack.append(i_, ret_type);
}

pub fn checkTypeCompatibilityType(a: Type, b: Type) !void {
    switch (a) {
        .comptime_int => {
            switch (b) {
                .anyint, .u8, .usize, .isize => return,
                else => return error.IncompatibleTypes,
            }
        },
        .anyint => {
            switch (b) {
                .anyint, .comptime_int, .u8, .usize, .isize => return,
                else => return error.IncompatibleTypes,
            }
        },
        .usize => {
            switch (b) {
                .anyint, .usize, .comptime_int => return,
                else => return error.IncompatibleTypes,
            }
        },
        else => {
            std.log.err("checkTypeCompatibility: unimplemented type", .{});
            std.process.exit(1);
        },
    }
}

fn checkTypeCompatibility(t: *TypeCheck, a: ?Index, b: ?Index) !void {
    const a_type = t.types[a.?];
    const b_type = t.types[b.?];

    try checkTypeCompatibilityType(a_type, b_type);
}

fn checkTypesCompatibility(t: *TypeCheck, a: SubRange, b: SubRange) !void {
    if (a.len != b.len) {
        return error.IncompatibleTypes;
    }

    for (0..a.len) |i| {
        try t.checkTypeCompatibility(t.types[a.start + i], t.types[b.start + i]);
    }
}
