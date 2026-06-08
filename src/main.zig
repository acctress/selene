const std = @import("std");
const zjit = @import("zjit");
const cli = @import("cli/mod.zig");
const wasmparser = @import("wasm/parser.zig");
const translator = @import("jit/translator.zig");

fn stringsMatch(a: []const u8, b: []const u8) bool {
    return std.mem.eql(u8, a, b);
}

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    var stdout = std.Io.File.stdout().writer(io, &.{});

    const parsed = try cli.parse(init) orelse return;

    switch (parsed.subcommand) {
        .run => |args| {
            var parser: wasmparser.Parser = try .init(
                args.file,
                init.arena.allocator(),
                io
            );

            const module = try parser.parse();

            if (args.verbose) {
                try stdout.interface.print("parsed {} type(s), {} function(s), {} code entrie(s)\n", .{
                    module.typesec.len,
                    module.funcsec.len,
                    module.codesec.len
                });
            }

            var trans = try translator.Translator.init(module, init.arena.allocator());
            defer trans.deinit();

            try trans.translate();

            if (args.dump_ir) {
                try stdout.interface.print("[dump-ir flag not implemented]\n", .{});
            }

            var compiled = try trans.compile();

            if (args.dump_asm) {
                try stdout.interface.print("[dump-asm flag not implemented]\n", .{});
            }

            const fn_name = args.fn_name orelse "fn_0";

            const func_idx = b: {
                for (module.funcsec, 0..) |_, i| {
                    var buf: [32]u8 = undefined;
                    const name = try std.fmt.bufPrint(&buf, "fn_{d}", .{ i });
                    if (std.mem.eql(u8, name, fn_name)) break :b i;
                }

                try stdout.interface.print("error: function '{s}' not found\n", .{ fn_name });
                return;
            };

            const type_idx = module.funcsec[func_idx];
            const func_type = module.typesec[type_idx];

            const n_params = func_type.params.len;
            if (args.call_args.len != n_params) {
                try stdout.interface.print("error: function expects {} arg(s), got {}\n", .{
                    n_params,
                    args.call_args.len,
                });

                return;
            }

            var iargs: [8]i64 = undefined;
            for (args.call_args, 0..) |a, i| {
                iargs[i] = try std.fmt.parseInt(i64, a, 10);
            }

            const fun = compiled.getFunction(fn_name, *const anyopaque).?;
            const result: i64 = switch (n_params) {
                0 => @as(*const fn () callconv(.c) i64, @ptrCast(fun))(),
                1 => @as(*const fn (i64) callconv(.c) i64, @ptrCast(fun))(iargs[0]),
                2 => @as(*const fn (i64, i64) callconv(.c) i64, @ptrCast(fun))(iargs[0], iargs[1]),
                3 => @as(*const fn (i64, i64, i64) callconv(.c) i64, @ptrCast(fun))(iargs[0], iargs[1], iargs[2]),
                4 => @as(*const fn (i64, i64, i64, i64) callconv(.c) i64, @ptrCast(fun))(iargs[0], iargs[1], iargs[2], iargs[3]),
                else => {
                    @panic("TODO: implement a way to call a function with a variable amount of arguments");
                },
            };
            
            try stdout.interface.print("{}\n", .{ result });
        },
        .inspect => |inspect_args| {
            var parser: wasmparser.Parser = try .init(
                inspect_args.file,
                init.arena.allocator(),
                io,
            );

            const module = try parser.parse();

            if (inspect_args.functions or (!inspect_args.functions and !inspect_args.exports)) {
                try stdout.interface.print("functions ({}):\n", .{module.funcsec.len});
                for (module.funcsec, 0..) |type_idx, i| {
                    const ft = module.typesec[type_idx];
                    try stdout.interface.print("  fn_{} : (", .{i});
                    for (ft.params, 0..) |p, j| {
                        if (j > 0) try stdout.interface.print(", ", .{});
                        try stdout.interface.print("{s}", .{@tagName(p)});
                    }
                    try stdout.interface.print(") -> ", .{});
                    if (ft.results.len > 0) {
                        try stdout.interface.print("{s}", .{@tagName(ft.results[0])});
                    } else {
                        try stdout.interface.print("void", .{});
                    }
                    try stdout.interface.print("\n", .{});
                }
            }

            if (inspect_args.exports) {
                try stdout.interface.print("exports: [export section not yet parsed]\n", .{});
            }
        },
    }
}