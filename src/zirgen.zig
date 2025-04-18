const std = @import("std");
const Zir = @import("zir.zig");
const Llir = @import("llir.zig");

const ZirInstList = Zir.InstList;
const ExtraList = Llir.ExtraList;
const LlirInstList = Llir.InstList;
const TypeList = Zir.TypeList;

const ZirGen = @This();
const Index = u32;

gpa: std.mem.Allocator,
zir: *Zir,
instructions: LlirInstList,
extra: ExtraList,
extra_index: Index,
inst_i: u32,

fn_id: u32,

fn_tr: std.ArrayList(u32),

pub fn genZir(gpa: std.mem.Allocator, zir: *Zir) !Llir {
    var zirgen: ZirGen = .{
        .gpa = gpa,
        .zir = zir,
        .instructions = .{},
        .extra = ExtraList.init(gpa),
        .extra_index = 0,
        .inst_i = 0,
        .fn_id = 1,
        .fn_tr = std.ArrayList(u32).init(gpa),
    };

    // for main function => index 0
    _ = try zirgen.fn_tr.addOne();

    try zirgen.gen();

    return .{
        .instructions = zirgen.instructions.toOwnedSlice(),
        .extra = try zirgen.extra.toOwnedSlice(),
    };
}

fn gen(z: *ZirGen) anyerror!void {
    while (z.zir.instructions.get(z.inst_i).tag != .eof) : (z.inst_i += 1) {
        switch (z.zir.instructions.get(z.inst_i).tag) {
            .bin_op => try z.genBinOp(),
            .int => try z.genInt(),
            .builtin_print => {}, // try z.genBuiltinPrint(),
            .fn_def => try z.genFnDef(),
            .fn_proto => unreachable,
            .fn_ret => try z.genFnRet(),
            .eof => unreachable,
            .fn_call => try z.genFnCall(),
        }
    }
}

fn genBinOp(z: *ZirGen) !void {
    const data = z.zir.instructions.get(z.inst_i).data;
    const ret_size = z.getTypeSize(data.bin_op.ret_type);
    const in_size = try z.getTypesSize(data.bin_op.in_types);
    const tag = data.bin_op.bin_op_tag;

    try z.instructions.append(z.gpa, .{
        .tag = zirBinOpTagToLlir(tag),
        .data = .{
            .bin_op = .{
                .lhs_size = in_size[0],
                .rhs_zise = in_size[1],
                .ret_size = ret_size,
            },
        },
    });
}

fn genInt(z: *ZirGen) !void {
    const int_size = z.getTypeSize(z.zir.instructions.get(z.inst_i).data.int.type);
    const int = z.zir.instructions.get(z.inst_i).data.int.int;

    const index = z.extra_index;
    try z.extra.append(int);
    z.extra_index += 1;

    try z.instructions.append(z.gpa, .{
        .tag = .push,
        .data = .{
            .push = .{
                .value = index,
                .size = int_size,
            },
        },
    });
}

fn genFnDef(z: *ZirGen) !void {
    const fn_name = z.zir.instructions.get(z.inst_i).data.fn_def.name;
    const fn_name_str = z.zir.string_bytes[fn_name.start .. fn_name.start + fn_name.len];
    const fn_id = if (std.mem.eql(u8, "main", fn_name_str)) 0 else z.getFnId();

    const ret_type = z.zir.instructions.get(z.inst_i).data.fn_def.ret_type;
    const ret_type_len = z.getTypeSize(ret_type);

    const index = &[_]u32{z.inst_i};

    _ = try z.fn_tr.addOne();
    try z.fn_tr.replaceRange(fn_id, 1, index);

    try z.instructions.append(z.gpa, .{
        .tag = .func,
        .data = .{
            .func = .{
                .id = fn_id,
                .ret_size = ret_type_len,
            },
        },
    });

    z.inst_i += 1;
}

fn genFnRet(z: *ZirGen) !void {
    const ret_type = z.zir.instructions.get(z.inst_i).data.type;
    const ret_size = z.getTypeSize(ret_type);

    try z.instructions.append(z.gpa, .{
        .tag = .ret,
        .data = .{
            .ret = .{ .size = ret_size },
        },
    });
}
fn genFnCall(z: *ZirGen) !void {
    const fn_def = z.zir.instructions.get(z.inst_i).data.call;
    const ret_type = z.zir.instructions.get(fn_def).data.fn_def.ret_type;
    var fn_id: ?usize = null;

    for (0.., z.fn_tr.items) |id, i| {
        if (i == fn_def) {
            fn_id = id;
            break;
        }
    }

    if (fn_id) |id| {
        try z.instructions.append(z.gpa, .{
            .tag = .call,
            .data = .{
                .call = .{
                    .id = @truncate(id),
                    .ret_size = z.getTypeSize(ret_type),
                },
            },
        });
    } else {
        std.log.err("Unknown function def or id", .{});
        std.process.exit(1);
    }
}

fn getTypeSize(z: *ZirGen, zir_type_index: Index) u8 {
    const zir_type = z.zir.types[zir_type_index];

    return switch (zir_type) {
        .void => 0,
        .u8 => 1,
        .usize, .isize => 8,
        .comptime_int => unreachable,
        .anyint => unreachable,
        else => unreachable,
    };
}

fn getTypesSize(z: *ZirGen, range: Zir.Inst.SubRange) ![]u8 {
    var size_list = std.ArrayList(u8).init(z.gpa);

    for (0..range.len) |i| {
        try size_list.append(z.getTypeSize(@intCast(i)));
    }
    return size_list.toOwnedSlice();
}

fn zirBinOpTagToLlir(tag: Zir.Inst.BinOpTag) Llir.Inst.Tag {
    return switch (tag) {
        .add => .add,
        .sub => .sub,
        // else => unreachable,
    };
}

fn getFnId(z: *ZirGen) u32 {
    const id = z.fn_id;
    z.fn_id += 1;
    return id;
}
