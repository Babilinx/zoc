const std = @import("std");
const lexer = @import("lexer.zig");

const Token = lexer.Token;
const TokenArray = std.MultiArrayList(lexer.Token);

fn tokenize(filename: []const u8, arena: std.mem.Allocator) !TokenArray {
    const file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();
    
    const buf_array = try file.readToEndAllocOptions(arena, std.math.maxInt(usize), null, @alignOf(u8), 0);
    const buf = buf_array[0.. :0];
    
    var token_array: TokenArray = TokenArray{};
    var Tokenizer = lexer.Tokenizer{ .buffer = buf, .index = 0 };    

    while (true) {        
        const tok: Token = Tokenizer.next();
        try token_array.append(arena, tok);
        
        std.debug.print("{}\n", .{ tok });
        
        if (tok.tag == .eof) {
            break;
        }
    }
    
    return token_array;
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    
    const args = try std.process.argsAlloc(allocator);
    
    if (args.len != 2) {
        std.log.err("Incorrect number of arguments.", .{});
        return error.IncorrectAmountOfArguments;
    }
    
    var tokens: TokenArray = try tokenize(args[1], allocator);
    _ = &tokens;
}

