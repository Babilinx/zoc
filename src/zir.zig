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
        add,
        sub,
        int,
        builtin_print,
        fn_proto,
        fn_def,
        fn_ret,
        fn_call,
        eof,
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

        type: Type,

        //
        call: Call,

        fn_def: FnDef,

        fn_proto: FnProto,
    };

    pub const Int = struct {
        int: u64,
        type: Type,
    };

    pub const Str = struct {
        start: Index,
        len: u32,
    };

    pub const Call = struct {
        in_type: SubRange,
        ret_type: Type,
    };

    pub const FnDef = struct {
        name: SubRange,
        ret_type: Type,
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
