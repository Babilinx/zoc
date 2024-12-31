const std = @import("std");

pub const Token = struct {
    tag: Tag,
    loc: Loc,

    pub const Loc = struct {
        start: usize,
        stop: usize,
    };

    pub const keywords = std.StaticStringMap(Tag).initComptime(.{
        .{ "if", .keyword_if },
        .{ "else", .keyword_else },
        .{ "fn", .keyword_fn },
        .{ "foreach", .keyword_foreach },
        .{ "for", .keyword_for },
        .{ "while", .keyword_while },
        .{ "do", .keyword_do },
        .{ "enum", .keyword_enum },
        .{ "switch", .keyword_switch },
        .{ "case", .keyword_case },
        .{ "struct", .keyword_struct },
        .{ "union", .keyword_union },
        .{ "const", .keyword_const },
        .{ "var", .keyword_var },
        .{ "defer", .keyword_defer },
        .{ "with", .keyword_with },
        .{ "test", .keyword_test },
        .{ "extern", .keyword_extern },
        .{ "inline", .keyword_inline },
        .{ "pub", .keyword_pub },
        .{ "continue", .keyword_continue },
        .{ "return", .keyword_return },
        .{ "asm", .keyword_asm },
    });

    pub const Tag = enum {
        invalid,
        identifier,
        string_literal,
        multiline_string_literal_line,
        char_literal,
        eof,
        builtin,
        bang,
        at_sign,
        pipe,
        equal,
        bang_equal,
        l_paren,
        r_paren,
        percent,
        l_brace,
        r_brace,
        l_bracket,
        r_bracket,
        period,
        period_asterisk,
        plus,
        minus,
        asterisk,
        colon,
        caret,
        slash,
        ampersand,
        question_mark,
        angle_bracket_left,
        angle_bracket_left_equal,
        angle_bracket_left_angle_bracket_left,
        angle_bracket_right,
        angle_bracket_right_equal,
        angle_bracket_right_angle_bracket_right,
        tilde,
        ellipsis2,
        ellipsis3,
        number_literal,
        keyword_if,
        keyword_else,
        keyword_fn,
        keyword_foreach,
        keyword_for,
        keyword_while,
        keyword_do,
        keyword_enum,
        keyword_switch,
        keyword_case,
        keyword_struct,
        keyword_union,
        keyword_const,
        keyword_var,
        keyword_defer,
        keyword_with,
        keyword_test,
        keyword_extern,
        keyword_inline,
        keyword_pub,
        keyword_continue,
        keyword_return,
        keyword_asm,
    };
};

pub const Tokenizer = struct {
    buffer: [:0]const u8,
    index: usize,

    const State = enum {
        start,
        expect_newline,
        identifier,
        builtin,
        period,
        period2,
        string_literal,
        string_literal_backslash,
        multiline_string_literal_line,
        char_literal,
        char_literal_backslash,
        backslash,
        bang,
        at_sign,
        slash,
        line_comment_start,
        line_comment,
        int,
        angle_bracket_left,
        angle_bracket_right,
        invalid,
    };

    pub fn next(self: *Tokenizer) Token {
        var result: Token = .{
            .tag = undefined,
            .loc = .{
                .start = self.index,
                .stop = undefined,
            },
        };

        var state: State = .start;

        blk: while (true) {
            switch (state) {
                .start => {
                    switch (self.buffer[self.index]) {
                        0 => {
                            if (self.index == self.buffer.len) {
                                return .{
                                    .tag = .eof,
                                    .loc = .{
                                        .start = self.index,
                                        .stop = self.index,
                                    },
                                };
                            } else {
                                state = .invalid;
                                continue :blk;
                            }
                        },
                        ' ', '\n', '\t', '\r' => {
                            self.index += 1;
                            result.loc.start = self.index;
                            continue :blk;
                        },
                        '"' => {
                            result.tag = .string_literal;
                            state = .string_literal;
                            continue :blk;
                        },
                        '\'' => {
                            result.tag = .char_literal;
                            state = .char_literal;
                            continue :blk;
                        },
                        'a'...'z', 'A'...'Z', '_' => {
                            result.tag = .identifier;
                            state = .identifier;
                            continue :blk;
                        },
                        '@' => {
                            state = .at_sign;
                            continue :blk;
                        },
                        '!' => {
                            state = .bang;
                            continue :blk;
                        },
                        '=' => {
                            self.index += 1;
                            result.tag = .equal;
                            break :blk;
                        },
                        '|' => {
                            self.index += 1;
                            result.tag = .pipe;
                            break :blk;
                        },
                        '(' => {
                            self.index += 1;
                            result.tag = .l_paren;
                            break :blk;
                        },
                        ')' => {
                            self.index += 1;
                            result.tag = .r_paren;
                            break :blk;
                        },
                        '[' => {
                            self.index += 1;
                            result.tag = .l_bracket;
                            break :blk;
                        },
                        ']' => {
                            self.index += 1;
                            result.tag = .r_bracket;
                            break :blk;
                        },
                        '{' => {
                            self.index += 1;
                            result.tag = .l_brace;
                            break :blk;
                        },
                        '}' => {
                            self.index += 1;
                            result.tag = .r_brace;
                            break :blk;
                        },
                        ':' => {
                            self.index += 1;
                            result.tag = .colon;
                            break :blk;
                        },
                        '?' => {
                            self.index += 1;
                            result.tag = .question_mark;
                            break :blk;
                        },
                        '%' => {
                            self.index += 1;
                            result.tag = .percent;
                            break :blk;
                        },
                        '*' => {
                            self.index += 1;
                            result.tag = .asterisk;
                            break :blk;
                        },
                        '+' => {
                            self.index += 1;
                            result.tag = .plus;
                        },
                        '<' => {
                            state = .angle_bracket_left;
                            continue :blk;
                        },
                        '>' => {
                            state = .angle_bracket_right;
                            continue :blk;
                        },
                        '^' => {
                            self.index += 1;
                            result.tag = .caret;
                            break :blk;
                        },
                        '\\' => {
                            state = .backslash;
                            result.tag = .multiline_string_literal_line;
                            continue :blk;
                        },
                        '~' => {
                            self.index += 1;
                            result.tag = .tilde;
                            break :blk;
                        },
                        '.' => {
                            state = .period;
                            continue :blk;
                        },
                        '-' => {
                            self.index += 1;
                            result.tag = .minus;
                            break :blk;
                        },
                        '/' => {
                            self.index += 1;
                            result.tag = .slash;
                            break :blk;
                        },
                        '&' => {
                            self.index += 1;
                            result.tag = .ampersand;
                            break :blk;
                        },
                        '0'...'9' => {
                            self.index += 1;
                            result.tag = .number_literal;
                            state = .int;
                            continue :blk;
                        },

                        else => {
                            state = .invalid;
                            continue :blk;
                        },
                    }
                },
                .expect_newline => {
                    self.index += 1;
                    switch (self.buffer[self.index]) {
                        0 => {
                            if (self.index == self.buffer.len) {
                                result.tag = .invalid;
                            } else {
                                state = .invalid;
                                continue :blk;
                            }
                        },
                        '\n' => {
                            self.index += 1;
                            result.loc.start = self.index;
                            state = .start;
                            continue :blk;
                        },
                        else => {
                            state = .invalid;
                            continue :blk;
                        },
                    }
                },
                .invalid => {},
                .at_sign => {
                    self.index += 1;
                    switch (self.buffer[self.index]) {
                        0, '\n' => {
                            result.tag = .invalid;
                            break :blk;
                        },
                        '"' => {
                            result.tag = .identifier;
                            state = .identifier;
                            continue :blk;
                        },
                        'a'...'z', 'A'...'Z', '_' => {
                            result.tag = .builtin;
                            state = .builtin;
                            continue :blk;
                        },
                        else => {
                            state = .invalid;
                            continue :blk;
                        },
                    }
                },
                .identifier => {
                    self.index += 1;
                    switch(self.buffer[self.index]) {
                        'a'...'z', 'A'...'Z', '_', '0'...'9' => continue :blk,
                        else => {
                            const ident = self.buffer[result.loc.start..self.index];
                            if (Token.keywords.get(ident)) |tag| {
                                result.tag = tag;
                            }
                            break :blk;
                        },
                    }
                },
                .builtin => {
                    self.index += 1;
                    switch (self.buffer[self.index]) {
                        'a'...'z', 'A'...'Z', '_', '0'...'9' => continue :blk,
                        else => break :blk,
                    }
                },
                .backslash => {
                    self.index += 1;
                    switch (self.buffer[self.index]) {
                        0, '\n' => {
                            result.tag = .invalid;
                            break :blk;
                        },
                        '\\' => {
                            state = .multiline_string_literal_line;
                            continue :blk;
                        },
                        else => {
                            state = .invalid;
                            continue :blk;
                        },
                    }
                },
                .string_literal => {
                    self.index += 1;
                    switch (self.buffer[self.index]) {
                        0 => {
                            if (self.index != self.buffer.len) {
                                state = .invalid;
                                continue :blk;
                            } else {
                                result.tag = .invalid;
                                break :blk;
                            }
                        },
                        '\n' => {
                            result.tag = .invalid;
                            break :blk;
                        },
                        '\\' => {
                            state = .string_literal_backslash;
                            continue :blk;
                        },
                        '"' => {
                            self.index += 1;
                            break :blk;
                        },
                        0x01...0x09, 0x0b...0x1f, 0x7f => {
                            state = .invalid;
                            continue :blk;
                        },
                        else => continue :blk,
                    }
                },
                .string_literal_backslash => {
                    self.index += 1;
                    switch (self.buffer[self.index]) {
                        0, '\n' => {
                            result.tag = .invalid;
                            break :blk;
                        },
                        else => {
                            state = .string_literal;
                            continue :blk;
                        },
                    }
                },
                .char_literal => {
                    self.index += 1;
                    switch (self.buffer[self.index]) {
                        0 => {
                            if (self.index != self.buffer.len) {
                                state = .invalid;
                                continue :blk;
                            } else {
                                result.tag = .invalid;
                                break :blk;
                            }
                        },
                        '\n' => {
                            result.tag = .invalid;
                            break :blk;
                        },
                        '\\' => {
                            state = .char_literal_backslash;
                            continue :blk;
                        },
                        '\'' => {
                            self.index += 1;
                            break :blk;
                        },
                        0x01...0x09, 0x0b...0x1f, 0x7f => {
                            state = .invalid;
                            continue :blk;
                        },
                        else => continue :blk,
                    }
                },
                .char_literal_backslash => {
                    self.index += 1;
                    switch (self.buffer[self.index]) {
                        0 => {
                            if (self.index != self.buffer.len) {
                                state = .invalid;
                                continue :blk;
                            } else {
                                result.tag = .invalid;
                                break :blk;
                            }
                        },
                        '\n' => {
                            result.tag = .invalid;
                            break :blk;
                        },
                        0x01...0x09, 0x0b...0x1f, 0x7f => {
                            state = .invalid;
                            continue :blk;
                        },
                        else => {
                            state = .char_literal;
                            continue :blk;
                        },
                    }
                },
                .multiline_string_literal_line => {
                    self.index += 1;
                    switch (self.buffer[self.index]) {
                        0 => if (self.index != self.buffer.len) {
                            state = .invalid;
                            continue :blk;
                        } else {
                            break :blk;
                        },
                        '\n' => break :blk,
                        '\r' => if (self.buffer[self.index + 1] != '\n') {
                            state = .invalid;
                            continue :blk;
                        } else {
                            break :blk;
                        },
                        0x01...0x09, 0x0b...0x0c, 0x0e...0x1f, 0x7f => {
                            state = .invalid;
                            continue :blk;
                        },
                        else => continue :blk,
                    }
                },
                .bang => {
                    self.index += 1;
                    switch (self.buffer[self.index]) {
                        '=' => {
                            result.tag = .bang_equal;
                            self.index += 1;
                            break :blk;
                        },
                        else => {
                            result.tag = .bang;
                            break :blk;
                        },
                    }
                },
                .angle_bracket_left => {
                    self.index += 1;
                    switch (self.buffer[self.index]) {
                        '<' => {
                            result.tag = .angle_bracket_left_angle_bracket_left;
                            self.index += 1;
                            break :blk;
                        },
                        '=' => {
                            result.tag = .angle_bracket_left_equal;
                            self.index += 1;
                            break :blk;
                        },
                        else => {
                            result.tag = .angle_bracket_left;
                            self.index += 1;
                            break :blk;
                        },
                    }
                },
                .angle_bracket_right => {
                    self.index += 1;
                    switch (self.buffer[self.index]) {
                        '<' => {
                            result.tag = .angle_bracket_right_angle_bracket_right;
                            self.index += 1;
                            break :blk;
                        },
                        '=' => {
                            result.tag = .angle_bracket_right_equal;
                            self.index += 1;
                            break :blk;
                        },
                        else => {
                            result.tag = .angle_bracket_right;
                            self.index += 1;
                            break :blk;
                        },
                    }
                },
                .period => {
                    self.index += 1;
                    switch (self.buffer[self.index]) {
                        '.' => {
                            state = .period2;
                            continue :blk;
                        },
                        '*' => {
                            result.tag = .period_asterisk;
                            self.index += 1;
                            break :blk;
                        },
                        else => {
                            result.tag = .period;
                            break :blk;
                        },
                    }
                },
                .period2 => {
                    self.index += 1;
                    switch (self.buffer[self.index]) {
                        '.' => {
                            result.tag = .ellipsis3;
                            self.index += 1;
                            break :blk;
                        },
                        else => {
                            result.tag = .ellipsis2;
                            break :blk;
                        },
                    }
                },
                .slash => {
                    self.index += 1;
                    switch (self.buffer[self.index]) {
                        '/' => {
                            state = .line_comment_start;
                            continue :blk;
                        },
                        else => {
                            result.tag = .slash;
                            break :blk;
                        },
                    }
                },
                .line_comment_start => {
                    self.index += 1;
                    switch (self.buffer[self.index]) {
                        0 => {
                            if (self.index != self.buffer.len) {
                                state = .invalid;
                                continue :blk;
                            } else return .{
                                .tag = .eof,
                                .loc = .{
                                    .start = self.index,
                                    .stop = self.index,
                                },
                            };
                        },
                        '\n' => {
                            self.index += 1;
                            result.loc.start = self.index;
                            state = .start;
                            continue :blk;
                        },
                        else => {
                            state = .line_comment;
                            continue :blk;
                        },
                    }
                },
                .line_comment => {
                    self.index += 1;
                    switch (self.buffer[self.index]) {
                        0 => {
                            if (self.index != self.buffer.len) {
                                state = .invalid;
                                continue :blk;
                            } else return .{
                                .tag = .eof,
                                .loc = .{
                                    .start = self.index,
                                    .stop = self.index,
                                },
                            };
                        },
                        '\n' => {
                            self.index += 1;
                            result.loc.start = self.index;
                            state = .start;
                            continue :blk;
                        },
                        '\r' => {
                            state = .expect_newline;
                            continue :blk;
                        },
                        0x01...0x09, 0x0b...0x0c, 0x0e...0x1f, 0x7f => {
                            state = .invalid;
                            continue :blk;
                        },
                        else => continue :blk,
                    }
                },
                .int => switch (self.buffer[self.index]) {
                    '_', 'a'...'f', 'A'...'F', 'o', 'x', 'O', 'X', '0'...'9' => {
                        self.index += 1;
                        continue :blk;
                    },
                    else => break :blk,
                }
            }
        }
        
        result.loc.stop = self.index;
        return result;
    }
};
