const std = @import("std");
const zjit = @import("zjit");

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

                const cwd = std.Io.Dir.cwd();
                const data = try cwd.readFileAlloc(io, fname, init.gpa, .unlimited);
                defer init.gpa.free(data);

                try stdout.interface.print("{s}\n", .{ data });
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