const std = @import("std");
const Llir = @import("llir.zig");

const InstList = Llir.InstList;
const ExtraList = Llir.ExtraList;
const StringBytes = std.ArrayList(u8);
const Index = u32;

const CodeGen = @This();

pub const Target = enum {
    @"x86_64-linux",
};

gpa: std.mem.Allocator,
llir: *Llir,
string_bytes: StringBytes,
index: Index,
target: Target,

pub fn genCode(gpa: std.mem.Allocator, llir: *Llir, target: CodeGen.Target) ![]u8 {
    var codegen: CodeGen = .{
        .gpa = gpa,
        .llir = llir,
        .string_bytes = StringBytes.init(gpa),
        .index = 0,
        .target = target,
    };

    codegen.checkForMain() catch {
        std.log.err("No main function declared", .{});
        std.process.exit(1);
    };

    try codegen.gen();

    return codegen.string_bytes.toOwnedSlice();
}

fn gen(c: *CodeGen) !void {
    const target = switch (c.target) {
        .@"x86_64-linux" => @import("build/x86_64-linux.zig"),
    };

    try target.init(c);

    while (c.index < c.llir.instructions.len) : (c.index += 1) {
        try c.eval(target);
    }
}

pub fn eval(c: *CodeGen, target: anytype) !void {
    const tag = c.llir.instructions.get(c.index).tag;
    switch (tag) {
        .push => try target.genPush(c),
        .add => try target.genAdd(c),
        .func => try target.genFn(c),
        .ret => try target.genRet(c),
        .call => try target.genCall(c),
        else => {
            std.log.err("Unimplemented instruction '{s}'", .{@tagName(tag)});
            std.process.exit(1);
        },
    }
}

fn checkForMain(c: *CodeGen) !void {
    for (c.llir.instructions.items(.tag), 0..) |tag, i| {
        switch (tag) {
            .func => {
                const fn_id = c.llir.instructions.get(i).data.func.id;
                if (fn_id == 0) {
                    return;
                }
            },
            else => {},
        }
    } else {
        return error.NoMainFunction;
    }
}
