const std = @import("std");

const Self = @This();

pub const InstList = std.MultiArrayList(Inst);
pub const ExtraList = std.ArrayList(u64);

pub const Index = u32;

instructions: InstList.Slice,
extra: ExtraList.Slice,

pub const Inst = struct {
    tag: Tag,
    data: Data,

    pub const Tag = enum {
        push,
        add,
        sub,
        call,
        func,
        ret,
    };

    pub const Data = union {
        push: Push,
        func: Func,
        ret: Ret,
        call: Func,
        bin_op: BinOp,
    };

    pub const Push = struct {
        size: u8,
        value: Index,
    };

    pub const Func = struct {
        id: Index,
        ret_size: u8,
    };

    pub const BinOp = struct {
        lhs_size: u8,
        rhs_zise: u8,
        ret_size: u8,
    };

    pub const Ret = struct {
        size: u8,
    };
};
