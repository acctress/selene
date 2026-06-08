const std = @import("std");
const zjit = @import("zjit");
const wasmparser = @import("wasm/parser.zig");

fn stringsMatch(a: []const u8, b: []const u8) bool {
    return std.mem.eql(u8, a, b);
}

pub fn main(init: std.process.Init) !void {
    const io = init.io;

    var stdout = std.Io.File.stdout().writer(io, &.{ });

    var args_iter = try init.minimal.args.iterateAllocator(init.gpa);
    defer args_iter.deinit();

    _ = args_iter.skip();

    const arg: ?[]const u8 = args_iter.next();
    if (arg) |sub_cmd| {

        if (stringsMatch(sub_cmd, "run")) {
            const filename: ?[]const u8 = args_iter.next();

            if (filename) |fname| {
                try stdout.interface.print("Running file '{s}'\n", .{ fname });

                var parser: wasmparser.Parser = try .init(
                    fname,
                    init.arena.allocator(),
                    io
                );

                const module = try parser.parse();

                try stdout.interface.print("Module func types: {}\n", .{ module.typesec.len });

                for (module.typesec) |ft| {
                    try stdout.interface.print("  params: {}, results: {}\n", .{ ft.params.len, ft.results.len });
                }

                try stdout.interface.print("Module func count: {}\n", .{ module.funcsec.len });

            } else {
                try stdout.interface.print("Expected filename for 'run' command\n", .{ });
            }
        } else {
            try stdout.interface.print("Subcommand '{s}' is not implemented yet.\n", .{ sub_cmd });
        }

    } else {
        try stdout.interface.print("Expected arguments: run, inspect\n", .{ });
    }
}