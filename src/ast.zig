const std = @import("std");
const lexer = @import("lexer.zig");
const Parser = @import("parser.zig");

const Allocator = std.mem.Allocator;
const Token = lexer.Tokenizer.Token;
const TokenList = lexer.TokenList;
const TokenIndex = lexer.TokenIndex;
const Index = lexer.Index;

pub const NodeList = std.MultiArrayList(Node);

pub const Location = struct { line: u32, column: u32, line_start: u32, line_end: u32 };

const Ast = @This();

gpa: std.Allocator,
source: [:0]const u8,

tokens: TokenList.Slice,
nodes: NodeList.Slice,
extra_data: []Node.Index,

//errors: []const Error,

pub fn parse(gpa: std.mem.Allocator, source: [:0]const u8, tokens: TokenList) Allocator.Error!Ast {
    var token_list = Ast.TokenList{};
    defer token_list.deinit(gpa);

    for (tokens.items(.tag), tokens.items(.start)) |token_tag, start| {
        try token_list.append(gpa, .{
            .tag = token_tag,
            .start = @intCast(start),
        });
    }

    var parser = Parser{
        .source = source,
        .gpa = gpa,
        .token_tags = token_list.items(.tag),
        .token_starts = token_list.items(.start),
        .extra_data = .{},
        .tok_i = 0,
    };
}

pub fn tokenLocation(self: Ast, start_offset: u32, tok_i: TokenIndex) Location {
    var loc = Location{
        .line = 0,
        .column = 0,
        .line_start = start_offset,
        .line_end = self.source.len,
    };
    const tok_start = self.tokens.items(.start)[tok_i];

    while (std.mem.indexOfScalarPos(u8, self.source, loc.line_start, '\n')) |i| {
        if (i >= tok_start) {
            break; // Went past
        }
        loc.line += 1;
        loc.line_start = i + 1;
    }

    const offset = loc.line_start;
    for (self.source[offset..], 0..) |c, i| {
        if (i + offset == tok_start) {
            loc.line_end = i + offset;
            while (loc.line_end < self.source.len and self.source[loc.line_end] != '\n') {
                loc.line_end += 1;
            }
            return loc;
        }
        if (c == '\n') {
            loc.line += 1;
            loc.column = 0;
            loc.line_start = i + 1;
        } else {
            loc.column += 1;
        }
    }
    return loc;
}

pub const Node = struct {
    tag: Tag,
    main_token: TokenIndex,
    data: Data,

    pub const Data = struct {
        lhs: Index,
        rhs: Index,
    };

    pub const Tag = enum {
        root,
        /// lhs is the index into extra_data.
        /// rhs is the initialization expression if any.
        /// main_token is var or const.
        local_var_decl,
        /// lhs.a
        /// main_token is the dot.
        /// rhs is the identifier token index.
        field_access,
        /// `lhs rhs *`. main_token is `*`.
        mul,
        /// `lhs rhs /`. main_token is `/`.
        div,
        /// `lhs rhs %`. main_token is `%`.
        mod,
        /// `lhs rhs +`. main_token is `+`.
        add,
        /// `lhs rhs -`. main_token is `-`.
        sub,
        /// `a b c d lhs`. `Subrange[rhs]`.
        /// main_token is the identifier
        //call_many,
        /// `rhs lhs`. main_token is the identifier.
        call_one,
        /// `lhs`. main_token is the identifier.
        call,
        /// `fn rhs ID lhs`. lhs can be ommited.
        /// main_token is the `fn` keyword.
        fn_proto_simple,
        /// lhs is the fn_proto.
        /// rhs is the function body block.
        fn_decl,
        /// rhs and lhs are unused.
        /// rarely used
        identifier,
        /// rhs and lhs are unused.
        number_literal,
        /// main_token is the string literal token.
        string_literal,
        /// `lsh rsh @a`. lsh and rsh may be ommited.
        /// main_token is the builtin.
        builtin_call_two,
    };
};
