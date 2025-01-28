const std = @import("std");

const Zir = @import("zir.zig");
const checkTypeCompatibility = @import("typecheck.zig").checkTypeCompatibilityType;
const Index = u32;
const Type = Zir.Inst.Type;
const TypeSlice = Zir.TypeList.Slice;
const SubRange = Zir.Inst.SubRange;

pub const StackNode = struct {
    prev: ?Index,
    type: Index,
};
pub const NodeList = std.MultiArrayList(StackNode);

const TypeStack = @This();

gpa: std.mem.Allocator,
types: TypeSlice,
stack: NodeList,
top: ?Index,

pub fn init(gpa: std.mem.Allocator, types: TypeSlice) TypeStack {
    return TypeStack{
        .gpa = gpa,
        .types = types,
        .stack = .{},
        .top = null,
    };
}

pub fn append(t: *TypeStack, index: ?Index, elem: Index) !?Index {
    // std.log.info("\t\tappend, i: {?}", .{index});

    if (t.types[elem] == .void) {
        return index;
    }

    try t.stack.append(t.gpa, .{
        .prev = index,
        .type = elem,
    });

    var top = t.top;
    if (t.top == null) {
        t.top = 1;
        top = 0;
    } else {
        t.top.? += 1;
    }
    return top;
}

pub fn appendSubRange(t: *TypeStack, index: ?Index, elem: SubRange) !?Index {
    var index_ = index;
    for (elem.start..elem.start + elem.len) |type_index| {
        index_ = try t.append(index_, @intCast(type_index));
    }

    return index_;
}

pub fn pop(t: *TypeStack, index: ?Index) !StackNode {
    if (index == null) {
        return error.EmptyList;
    }
    // std.log.info("\t\tpop", .{});
    const top = t.stack.get(index.?);

    return top;
}

pub fn popN(t: *TypeStack, index: ?Index, len: u32) !NodeList.Slice {
    if (index == null) {
        return error.EmptyList;
    }
    // std.log.info("\t\tpopN: {}", .{len});
    var node_list: std.MultiArrayList(StackNode) = .{};
    var i = index;

    for (0..len) |_| {
        if (i == null) {
            std.log.err("popN: reached end of stack elements", .{});
            std.process.exit(1);
        }

        const node = t.stack.get(i.?);
        try node_list.append(t.gpa, node);
        i = node.prev;
    }

    return node_list.toOwnedSlice();
}

pub fn getLen(t: *TypeStack, index: ?Index) u32 {
    var i = index;
    var len: u32 = 0;

    while (i != null) : (len += 1) {
        i = t.stack.get(i.?).prev;
    }

    return len;
}

pub fn eql(t: *TypeStack, a: ?Index, b: ?Index) !?Index {
    // std.log.info("\t\teql", .{});
    if (t.getLen(a) != t.getLen(b)) {
        return error.NotEqual;
    }

    var i_a = a;
    var i_b = b;

    for (0..t.getLen(a)) |_| {
        if (i_a == i_b) {
            // Will follow th same path, so equal
            return a;
        }

        if (i_a == null or i_b == null) {
            return error.NotEqual;
        }

        const type_a_index = t.stack.get(i_a.?).type;
        const type_b_index = t.stack.get(i_b.?).type;
        const type_a = t.types[type_a_index];
        const type_b = t.types[type_b_index];

        try checkTypeCompatibility(type_a, type_b);

        i_a = t.stack.get(i_a.?).prev;
        i_b = t.stack.get(i_b.?).prev;
    }

    return a;
}

pub fn print(t: *TypeStack, i: ?Index) void {
    var i_ = i;

    const len = t.getLen(i);

    for (0..len) |_| {
        if (i_ == null) {
            break;
        }
        std.debug.print("{s} ", .{@tagName(t.types[t.stack.get(i_.?).type])});
        i_ = t.stack.get(i_.?).prev;
    }

    std.debug.print("({})\n", .{len});
}
