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
            var parser: wasmparser.Parser = try .init(args.file, init.arena.allocator(), io);

            const module = try parser.parse();

            if (args.verbose) {
                try stdout.interface.print("parsed {} type(s), {} function(s), {} code entrie(s)\n", .{ module.typesec.len, module.funcsec.len, module.codesec.len });
            }

            var trans = try translator.Translator.init(module, init.arena.allocator());
            // defer trans.deinit();

            try trans.translate();

            if (args.dump_ir) {
                var buf: std.ArrayListUnmanaged(u8) = .empty;
                {
                    var aw: std.Io.Writer.Allocating = .fromArrayList(init.arena.allocator(), &buf);
                    try zjit.IR.IRFmt.fmtModule(&trans.module, &aw.writer);
                    buf = aw.toArrayList();
                }
                try stdout.interface.writeAll(buf.items);
            }

            var compiled = try trans.compile();

            if (args.dump_asm) {
                try stdout.interface.print("[dump-asm flag not implemented]\n", .{});
            }

            const fn_name = args.fn_name orelse {
                try stdout.interface.print("error: --fn required\n", .{});
                return;
            };

            const func_idx = trans.export_map.get(fn_name) orelse {
                try stdout.interface.print("error: function '{s}' not found\n", .{fn_name});
                return;
            };

            const wasm_func_idx = module.exportsec[func_idx].index;
            const type_idx = module.funcsec[wasm_func_idx];
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
                else => @panic("too many params"),
            };

            try stdout.interface.print("{}\n", .{result});
        },
        .inspect => |args| {
            var parser: wasmparser.Parser = try .init(
                args.file,
                init.arena.allocator(),
                io,
            );

            defer parser.deinit();

            const module = try parser.parse();

            if (args.functions or (!args.functions and !args.exports)) {
                try stdout.interface.print("functions ({}):\n", .{module.exportsec.len});
                for (module.exportsec) |ex| {
                    if (ex.kind != .func) continue;
                    const type_idx = module.funcsec[ex.index];
                    const ft = module.typesec[type_idx];
                    try stdout.interface.print("  {s} : (", .{ex.name});
                    for (ft.params, 0..) |p, j| {
                        if (j > 0) try stdout.interface.print(", ", .{});
                        try stdout.interface.print("{s}", .{@tagName(p)});
                    }
                    try stdout.interface.print(") -> ", .{});
                    if (ft.results.len > 0) {
                        try stdout.interface.print("{s}\n", .{@tagName(ft.results[0])});
                    } else {
                        try stdout.interface.print("void\n", .{});
                    }
                }
            }

            if (args.exports) {
                try stdout.interface.print("exports ({}):\n", .{module.exportsec.len});
                for (module.exportsec) |ex| {
                    try stdout.interface.print("  {s} ({s}) index={}\n", .{
                        ex.name,
                        @tagName(ex.kind),
                        ex.index,
                    });
                }
            }
        },
    }
}
