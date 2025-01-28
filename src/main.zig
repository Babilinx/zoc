const std = @import("std");
const lexer = @import("lexer.zig");
const Parser = @import("parser.zig");
const Zir = @import("zir.zig");
const TypeCheck = @import("typecheck.zig");
const ZirGen = @import("zirgen.zig");
const Llir = @import("llir.zig");
const codegen = @import("codegen.zig");

const debug = false;

const use_info = "info: Usage: zoc [input file] [output file]\n";

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const args = try std.process.argsAlloc(allocator);

    if (args.len != 3) {
        std.log.err("Incorrect number of arguments.", .{});
        return error.IncorrectAmountOfArguments;
    }

    const cwd = std.fs.cwd();

    const file = try cwd.openFile(args[1], .{});
    defer file.close();

    const buf_array = try file.readToEndAllocOptions(allocator, std.math.maxInt(usize), null, @alignOf(u8), 0);
    const buf = buf_array[0.. :0];

    std.log.info("Tokenizing", .{});
    const tokens = try lexer.tokenize(buf, allocator);

    if (debug) {
        std.debug.print("{any}\n", .{tokens.items(.tag)});
    }

    std.log.info("Parsing", .{});
    var zir = try Parser.parse(allocator, buf, tokens);

    if (debug) {
        std.debug.print("\n{any}\n", .{zir.instructions.items(.tag)});
        std.debug.print("{any}\n", .{zir.types});
    }

    std.log.info("Checking the types", .{});
    zir = try TypeCheck.Check(allocator, &zir);

    std.log.info("Generating IR", .{});
    var llir = try ZirGen.genZir(allocator, &zir);
    if (debug) {
        std.debug.print("\n{any}\n", .{llir.instructions.items(.tag)});
    }
    std.log.info("Generating assembly", .{});
    const output = try codegen.genCode(allocator, &llir, .@"x86_64-linux");

    std.fs.cwd().makeDir("zoc-out") catch |err| {
        switch (err) {
            std.fs.Dir.MakeError.PathAlreadyExists => {},
            else => return err,
        }
    };

    var asm_file_buf: [128]u8 = undefined;
    const asm_file = try std.fmt.bufPrint(&asm_file_buf, "{s}.asm", .{args[2]});

    const zoc_out = try cwd.openDir("zoc-out", .{});

    std.log.info("Writing assembly to 'zoc-out/{s}'", .{asm_file});
    const out_file = try zoc_out.createFile(asm_file, .{});
    defer out_file.close();

    try out_file.writeAll(output);

    var asm_path_buf: [128]u8 = undefined;
    const asm_file_path = try std.fmt.bufPrint(&asm_path_buf, "zoc-out/{s}", .{asm_file});

    std.log.info("Generating executable", .{});
    var argv = [_][]const u8{ "fasm", asm_file_path };
    var fasm = std.process.Child.init(&argv, allocator);
    const term = try fasm.spawnAndWait();

    _ = term;
}
