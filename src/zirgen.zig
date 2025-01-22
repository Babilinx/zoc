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

pub fn genZir(gpa: std.mem.Allocator, zir: *Zir) !Llir {
    var zirgen: ZirGen = .{
        .gpa = gpa,
        .zir = zir,
        .instructions = .{},
        .extra = ExtraList.init(gpa),
        .extra_index = 0,
        .inst_i = 0,
        .fn_id = 1,
    };

    try zirgen.gen();

    return .{
        .instructions = zirgen.instructions.toOwnedSlice(),
        .extra = try zirgen.extra.toOwnedSlice(),
    };
}

fn gen(z: *ZirGen) anyerror!void {
    while (z.zir.instructions.get(z.inst_i).tag != .eof) : (z.inst_i += 1) {
        switch (z.zir.instructions.get(z.inst_i).tag) {
            .add => try z.genBinOp(.add),
            .int => try z.genInt(),
            .sub => try z.genBinOp(.sub),
            .builtin_print => {}, // try z.genBuiltinPrint(),
            .fn_def => try z.genFnDef(),
            .fn_proto => unreachable,
            .fn_ret => try z.genFnRet(),
            .eof => unreachable,
            .fn_call => unreachable,
        }
    }
}

fn genBinOp(z: *ZirGen, tag: Zir.Inst.Tag) !void {
    const ret_size = getTypeSize(z.zir.instructions.get(z.inst_i).data.bin_op.ret_type);
    const in_size = try z.getTypesSize(z.zir.instructions.get(z.inst_i).data.bin_op.in_types);

    try z.instructions.append(z.gpa, .{
        .tag = zirTagToLlir(tag),
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
    const int_size = getTypeSize(z.zir.instructions.get(z.inst_i).data.int.type);
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
    const ret_type_len = getTypeSize(ret_type);

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
    const ret_size = getTypeSize(ret_type);

    try z.instructions.append(z.gpa, .{
        .tag = .ret,
        .data = .{
            .ret = .{ .size = ret_size },
        },
    });
}

fn getTypeSize(zir_type: Zir.Inst.Type) u8 {
    return switch (zir_type) {
        .void => 0,
        .u8 => 1,
        .usize, .isize => 8,
        .comptime_int => 8,
        .anyint => 8,
        //else => unreachable,
    };
}

fn getTypesSize(z: *ZirGen, range: Zir.Inst.SubRange) ![]u8 {
    var size_list = std.ArrayList(u8).init(z.gpa);

    for (0..range.len) |i| {
        try size_list.append(getTypeSize(z.zir.types[i]));
    }
    return size_list.toOwnedSlice();
}

fn zirTagToLlir(tag: Zir.Inst.Tag) Llir.Inst.Tag {
    return switch (tag) {
        .add => .add,
        .sub => .sub,
        else => unreachable,
    };
}

fn getFnId(z: *ZirGen) u32 {
    const id = z.fn_id;
    z.fn_id += 1;
    return id;
}
