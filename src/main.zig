const std = @import("std");
const lexer = @import("lexer.zig");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    
    const args = try std.process.argsAlloc(allocator);
    
    if (args.len != 2) {
        std.log.err("Incorrect number of arguments.", .{});
        return error.IncorrectAmountOfArguments;
    }
    
    const file = try std.fs.cwd().openFile(args[1], .{});
    defer file.close();
    
    const buf_array = try file.readToEndAllocOptions(allocator, std.math.maxInt(usize), null, @alignOf(u8), 0);
    const buf = buf_array[0.. :0];
    
    const tokens = try lexer.tokenize(buf, allocator);
    _ = tokens;
    
}

