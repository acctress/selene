const std = @import("std");

pub const RunArgs = struct {
    file: []const u8,
    fn_name: ?[]const u8 = null,
    verbose: bool = false,
    dump_ir: bool = false,
    dump_asm: bool = false,
    interpret: bool = false,
    call_args: []const []const u8 = &.{},
};

pub const InspectArgs = struct {
    file: []const u8,
    functions: bool = false,
    exports: bool = false,
};

pub const Subcommand = union(enum) {
    run: RunArgs,
    inspect: InspectArgs,
};

pub const Args = struct {
    subcommand: Subcommand,
};

pub fn parse(init: std.process.Init) !?Args {
    const arena = init.arena.allocator();
    const all_args = try init.minimal.args.toSlice(arena);

    if (all_args.len < 2) {
        printUsage();
        return null;
    }

    const subcmd = all_args[1];
    const rest = all_args[2..];

    if (std.mem.eql(u8, subcmd, "run")) {
        var run = RunArgs{ .file = undefined };
        var file: ?[]const u8 = null;

        var sep: ?usize = null;
        for (rest, 0..) |arg, i|{
            if (std.mem.eql(u8, arg, "--")) {
                sep = i;
                break;
            }
        }

        if (sep) |s| {
            run.call_args = rest[s + 1..];
        }

        const flags = if (sep) |s| rest[0..s] else rest;

        var i: usize = 0;
        while (i < flags.len) : (i += 1) {
            const arg = flags[i];
            if (std.mem.eql(u8, arg, "--verbose") or std.mem.eql(u8, arg, "-v")) {
                run.verbose = true;
            } else if (std.mem.eql(u8, arg, "--dump-ir")) {
                run.dump_ir = true;
            } else if (std.mem.eql(u8, arg, "--dump-asm")) {
                run.dump_asm = true;
            } else if (std.mem.eql(u8, arg, "--interpret")) {
                run.interpret = true;
            } else if (std.mem.eql(u8, arg, "--fn") or std.mem.eql(u8, arg, "-f")) {
                i += 1;
                if (i >= flags.len) {
                    std.debug.print("error: --fn requires a value\n", .{});
                    return null;
                }
                run.fn_name = flags[i];
            } else if (!std.mem.startsWith(u8, arg, "--")) {
                file = arg;
            } else {
                std.debug.print("error: unknown flag '{s}'\n", .{arg});
                return null;
            }
        }

        if (file == null) {
            std.debug.print("error: expected a .wasm file\n", .{});
            return null;
        }

        run.file = file.?;
        return .{ .subcommand = .{ .run = run } };
    } else if (std.mem.eql(u8, subcmd, "inspect")) {
        var inspect = InspectArgs{ .file = undefined };
        var file: ?[]const u8 = null;

        var i: usize = 0;
        while (i < rest.len) : (i += 1) {
            const arg = rest[i];
            if (std.mem.eql(u8, arg, "--functions")) {
                inspect.functions = true;
            } else if (std.mem.eql(u8, arg, "--exports")) {
                inspect.exports = true;
            } else if (!std.mem.startsWith(u8, arg, "--")) {
                file = arg;
            } else {
                std.debug.print("error: unknown flag '{s}'\n", .{arg});
                return null;
            }
        }

        if (file == null) {
            std.debug.print("error: expected a .wasm file\n", .{});
            return null;
        }

        inspect.file = file.?;
        return .{ .subcommand = .{ .inspect = inspect } };
    } else if (std.mem.eql(u8, subcmd, "--help") or std.mem.eql(u8, subcmd, "-h")) {
        printUsage();
        return null;
    } else {
        std.debug.print("error: unknown subcommand '{s}'\n", .{subcmd});
        printUsage();
        return null;
    }
}

fn printUsage() void {
    std.debug.print(
        \\usage: selene <subcommand> [options] <file.wasm>
        \\
        \\subcommands:
        \\  run      run a wasm module
        \\  inspect  inspect a wasm module
        \\
        \\run options:
        \\  --fn, -f <name>   function to call
        \\  --verbose, -v     print compilation steps
        \\  --dump-ir         print zjit SSA IR
        \\  --dump-asm        print native asm
        \\  --interpret       skip JIT
        \\
        \\inspect options:
        \\  --functions       list functions and signatures
        \\  --exports         list exports only
        \\
    , .{});
}