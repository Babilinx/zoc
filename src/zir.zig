const std = @import("std");

const Zir = @This();

instructions: InstList.Slice,
string_bytes: []u8,
//extra: []u32,
types: TypeList.Slice,

pub const Index = u32;

pub const InstList = std.MultiArrayList(Inst);

pub const ByteList = std.ArrayList(u8);

pub const TypeList = std.ArrayList(Inst.Type);

pub const Inst = struct {
    tag: Tag,
    data: Data,

    pub const Tag = enum {
        bin_op,
        int,
        builtin_print,
        fn_proto,
        fn_def,
        fn_ret,
        fn_call,
        eof,
    };

    pub const BinOpTag = enum {
        add,
        sub,
    };

    pub const Type = enum {
        void,
        u8,
        usize,
        isize,
        comptime_int,
        anyint,
    };

    pub const Data = union {
        // Literal integer
        int: Int,

        // Literal string
        str: Str,

        type: Index,

        //
        call: Index,

        bin_op: BinOp,

        fn_def: FnDef,

        fn_proto: FnProto,
    };

    pub const Int = struct {
        int: u64,
        type: Index,
    };

    pub const Str = struct {
        start: Index,
        len: u32,
    };

    pub const BinOp = struct {
        bin_op_tag: BinOpTag,
        in_types: SubRange,
        ret_type: Index,
    };

    pub const FnDef = struct {
        name: SubRange,
        ret_type: Index,
    };

    pub const FnProto = struct {
        arg_types: SubRange,
        end: Index,
    };

    pub const SubRange = struct {
        start: Index,
        len: u32,
    };
};
