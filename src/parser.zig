const std = @import("std");
const Zir = @import("zir.zig");
const lexer = @import("lexer.zig");
const assert = std.debug.assert;
const Token = lexer.Token;
const TokenList = lexer.TokenList;
const Index = lexer.Index;
const ByteList = Zir.ByteList;
const TypeList = Zir.TypeList;
const Type = Zir.Inst.Type;

const Parse = @This();

const Allocator = std.mem.Allocator;

const ParseError = error{
    ExpectedIdentifier,
    ExpectedNumber,
    ExpectedType,
    ExpectedToken,
    IntParseError,
};

const Error = struct {
    tag: Token.Tag,
    loc: Token.Loc,
    err: ParseError,
};

gpa: std.mem.Allocator,
source: [:0]const u8,
token_tags: []const Token.Tag,
token_locs: []const Token.Loc,
string_bytes: ByteList,
tok_i: Index,
instructions: std.MultiArrayList(Zir.Inst),
types: TypeList,
errors: std.MultiArrayList(Error),

//fn addExtraData(p: *Parse, extra: anytype) std.Allocator.Error!Index {
//    const fields = std.meta.fields(@TypeOf(extra));
//    try p.extra_data.ensureUnusedCapacity(p.gpa, fields.len);
//    const result = @as(u32, @intCast(p.extra_data.items.len));
//    inline for (fields) |field| {
//        comptime assert(field.type == Node.Index);
//        p.extra_data.appendAssumeCapacity(@field(extra, field.name));
//    }
//    return result;
//}

fn eatToken(p: *Parse, tag: Token.Tag) ?Index {
    return if (p.token_tag[p.tok_i] == tag) p.nextToken() else null;
}

fn expectToken(p: *Parse, tag: Token.Tag) ParseError!Index {
    if (p.token_tags[p.tok_i] != tag) {
        return ParseError.ExpectedToken;
    }
    return p.nextToken();
}

fn nextToken(p: *Parse) Index {
    const result = p.tok_i;
    p.tok_i += 1;
    return result;
}

pub fn parse(gpa: std.mem.Allocator, source: [:0]const u8, tokens: TokenList) !Zir {
    var parser: Parse = .{
        .gpa = gpa,
        .source = source,
        .token_tags = tokens.items(.tag),
        .token_locs = tokens.items(.loc),
        .string_bytes = ByteList.init(gpa),
        .types = TypeList.init(gpa),
        .tok_i = 0,
        .instructions = .{},
        .errors = .{},
    };

    try parser.parseFile();

    try parser.instructions.append(parser.gpa, .{ .tag = .eof, .data = undefined });

    return Zir{
        .instructions = parser.instructions.toOwnedSlice(),
        .string_bytes = try parser.string_bytes.toOwnedSlice(),
        .types = try parser.types.toOwnedSlice(),
    };
}

fn parseFile(p: *Parse) anyerror!void {
    while (p.token_tags[p.tok_i] != .eof) {
        switch (p.token_tags[p.tok_i]) {
            .number_literal => {
                try p.parseNumberLiteral(); // catch |err| {
                //switch (err) {
                //std.fmt.ParseIntError => try p.errors.append(p.gpa, .{ .tag = .number_literal, .loc = p.token_locs[p.tok_i], .err = .IntParseError }),
                //else => return err,
                //}
                //};
            },
            .plus => try p.parsePlus(),
            .keyword_fn => try p.parseFn(),
            .r_brace => try p.parseRbrace(),
            .identifier => try p.parseIdentifier(),
            else => {
                std.log.err("Unimplemented token: '{s}'", .{@tagName(p.token_tags[p.tok_i])});
                assert(false);
            },
        }
    }
}

fn parseNumberLiteral(p: *Parse) anyerror!void {
    const i = p.nextToken();
    const start = p.token_locs[i].start;
    const end = p.token_locs[i].stop;

    const type_index: Index = @intCast(p.types.items.len);

    try p.types.append(.comptime_int);
    try p.instructions.append(p.gpa, .{
        .tag = .int,
        .data = .{
            .int = .{
                .int = std.fmt.parseInt(usize, p.source[start..end], 10) catch |err| {
                    return err;
                },
                .type = type_index,
            },
        },
    });
}

fn parsePlus(p: *Parse) !void {
    //std.log.info("\tparsing '+'", .{});
    _ = p.nextToken();
    const in_types_start = p.types.items.len;
    try p.types.appendSlice(&.{ .anyint, .anyint });
    const ret_type_index: Index = @intCast(p.types.items.len);
    try p.types.append(.anyint);

    try p.instructions.append(p.gpa, .{
        .tag = .bin_op,
        .data = .{
            .bin_op = .{
                .bin_op_tag = .add,
                .in_types = .{ .start = @intCast(in_types_start), .len = 2 },
                .ret_type = @intCast(ret_type_index),
            },
        },
    });
}

fn parseFn(p: *Parse) !void {
    //std.log.info("\tparsing a function", .{});
    _ = p.nextToken();

    const ret_type = p.getType() catch {
        std.log.err("Not a type", .{});
        std.process.exit(1);
    };
    const ret_type_index = p.types.items.len;
    try p.types.append(ret_type);

    _ = p.expectToken(.identifier) catch {
        std.log.err("Expected an identifier found '{s}'", .{@tagName(p.token_tags[p.tok_i])});
        std.process.exit(1);
    };

    _ = p.expectToken(.identifier) catch {
        std.log.err("Expected an identifier found '{s}'", .{@tagName(p.token_tags[p.tok_i])});
        std.process.exit(1);
    };

    const fn_id_start = p.token_locs[p.tok_i - 1].start;
    const fn_id_stop = p.token_locs[p.tok_i - 1].stop;
    const fn_id_bytes_start = p.string_bytes.items.len;

    // Save the name
    try p.string_bytes.appendSlice(p.source[fn_id_start..fn_id_stop]);
    //std.log.info("\tname: {s} ret: {s}", .{ p.source[fn_id_start..fn_id_stop], @tagName(ret_type) });

    // Function definition (name and ret type)
    try p.instructions.append(p.gpa, .{ .tag = .fn_def, .data = .{
        .fn_def = .{
            .name = .{
                .start = @intCast(fn_id_bytes_start),
                .len = @intCast(fn_id_stop - fn_id_start),
            },
            .ret_type = @intCast(ret_type_index),
        },
    } });

    _ = p.expectToken(.l_paren) catch {
        std.log.err("Expected 'l_paren' found '{s}'", .{@tagName(p.token_tags[p.tok_i])});
        std.process.exit(1);
    };
    const in_types_start = p.types.items.len;

    while (p.token_tags[p.tok_i] != .r_paren) : (_ = p.nextToken()) {
        const arg_type = p.getType() catch {
            std.log.err("Not a type", .{});
            std.process.exit(1);
        };
        //std.log.info("\t\targ: {s}", .{@tagName(arg_type)});
        try p.types.append(arg_type);
    }

    _ = p.nextToken();

    const in_types_stop = p.types.items.len;

    var fn_proto: Zir.Inst = .{
        .tag = .fn_proto,
        .data = .{
            .fn_proto = .{
                .arg_types = .{
                    .start = @intCast(in_types_start),
                    .len = @intCast(in_types_stop - in_types_start),
                },
                .end = undefined,
            },
        },
    };

    _ = p.expectToken(.l_brace) catch {
        std.log.err("Expected 'l_brace' found '{s}'", .{@tagName(p.token_tags[p.tok_i])});
        std.process.exit(1);
    };

    var i = p.tok_i;
    var nest: Index = 1;
    while (p.token_tags[i] != .eof) : (i += 1) {
        switch (p.token_tags[i]) {
            .l_brace => nest += 1,
            .r_brace => nest -= 1,
            else => {},
        }

        if (nest == 0) {
            fn_proto.data.fn_proto.end = i;
            try p.instructions.append(p.gpa, fn_proto);
            return;
        }
    } else {
        std.log.err("reached EOF", .{});
        std.process.exit(1);
    }
}

fn parseRbrace(p: *Parse) !void {
    //std.log.info("\tparsing '}}'", .{});
    // '}' works like an 'end' statement. This function uses the index of the brace to find what declaration it terminates.

    for (p.instructions.items(.tag), 0..) |tag, i| {
        switch (tag) {
            .fn_proto => {
                const end = p.instructions.get(i).data.fn_proto.end;
                if (end == p.tok_i) {
                    // ending a function
                    const ret_type = p.instructions.get(i - 1).data.fn_def.ret_type;
                    try p.instructions.append(p.gpa, .{
                        .tag = .fn_ret,
                        .data = .{ .type = ret_type },
                    });
                }
            },
            else => {}, // nothing else to terminate
        }
    }

    _ = p.nextToken();
}

fn parseIdentifier(p: *Parse) !void {
    const type_id = p.getType() catch {
        try p.parseIdentifierNotType();
        return;
    };

    _ = type_id;

    // later for struct fields or more
    assert(false);
}

fn parseIdentifierNotType(p: *Parse) !void {
    const locs = p.token_locs[p.tok_i];
    const name = p.source[locs.start..locs.stop];

    _ = p.nextToken();

    const fn_start = p.findFnDef(name) catch {
        std.log.err("Function {s} does not exist", .{name});
        std.process.exit(1);
    };

    try p.instructions.append(p.gpa, .{
        .tag = .fn_call,
        .data = .{ .call = fn_start },
    });
}

fn getType(p: *Parse) !Type {
    //std.log.info("\t\tgetting a type", .{});
    switch (p.token_tags[p.tok_i]) {
        .identifier => {
            const start = p.token_locs[p.tok_i].start;
            const stop = p.token_locs[p.tok_i].stop;
            if (std.mem.eql(u8, "void", p.source[start..stop])) {
                return .void;
            } else if (std.mem.eql(u8, "usize", p.source[start..stop])) {
                return .usize;
            } else {
                return error.NotAType;
            }
        },
        else => {
            return error.NotAType;
        },
    }
}

fn findFnDef(p: *Parse, name: []const u8) !Index {
    for (p.instructions.items(.tag), 0..) |tag, i| {
        switch (tag) {
            .fn_def => {
                const name_range = p.instructions.get(i).data.fn_def.name;
                if (name.len != name_range.len) {
                    continue;
                }

                const fn_name = p.string_bytes.items[name_range.start .. name_range.start + name_range.len];

                if (!std.mem.eql(u8, name, fn_name)) {
                    continue;
                }

                return @truncate(i);
            },
            else => {},
        }
    }

    return error.FunctionNotFound;
}
