const std = @import("std");
const wasmmod = @import("../wasm/module.zig");
const reader = @import("../wasm/reader.zig");
const zjit = @import("zjit");

pub const Opcodes = enum(u8) {
    local_get = 0x20,
    local_set = 0x21,
    i32_const = 0x41,
    i32_add   = 0x6A,
    i32_sub   = 0x6B,
    end       = 0x0B,
};

pub const Translator = struct {
    alloc: std.mem.Allocator,
    emitter: zjit.Emitter,
    wasm: wasmmod.WasmModule,
    module: zjit.IR.Module,

    pub fn init(wasm: wasmmod.WasmModule, alloc: std.mem.Allocator) !Translator {
        const emitter = try zjit.Emitter.init(alloc, 1024);
        const module = zjit.IR.Module.init(alloc);

        return .{
            .alloc = alloc,
            .emitter = emitter,
            .wasm = wasm,
            .module = module,
        };
    }

    pub fn deinit(self: *Translator) void {
        self.emitter.deinit();
        self.module.deinit();
    }

    pub fn translate(self: *Translator) !void {
        for (self.wasm.funcsec, 0..) |type_idx, i| {
            const func_type = self.wasm.typesec[type_idx];
            const code = self.wasm.codesec[i];

            const ir_params = try self.alloc.alloc(zjit.IR.Type, func_type.params.len);
            for (0..func_type.params.len) |idx| {
                ir_params[idx] = self.valTypeToIR(func_type.params[idx]);
            }

            const ir_return = self.valTypeToIR(func_type.results[0]);

            var buf: [32]u8 = undefined;
            const name = try std.fmt.bufPrint(&buf, "fn_{d}", .{i});

            var function = try self.module.createFunction(try self.alloc.dupe(u8, name), ir_params, ir_return);

            var stack: std.ArrayList(u32) = .empty;

            var cursor = reader.Reader.init(code.body);
            while (!cursor.atEOF()) {
                const opcode = std.enums.fromInt(Opcodes, try cursor.readByte());

                if (opcode) |op| {
                    switch (op) {
                        .local_get => {
                            const idx = try cursor.readULEB128();
                            const val = function.getArg(idx).?;
                            try stack.append(self.alloc, val);
                        },

                        .i32_add => {
                            const rhs = stack.pop().?;
                            const lhs = stack.pop().?;
                            const result = try function.iadd(lhs, rhs);
                            try stack.append(self.alloc, result);
                        },

                        .end => {
                            const ret_val = stack.pop().?;
                            try function.ret(ret_val);
                            break;
                        },

                        else => @panic("unsupported opcode")
                    }
                }
            }
        }

        std.debug.print("translated {} functions\n", .{self.wasm.funcsec.len});
    }

    pub fn compile(self: *Translator) !zjit.GenModule {
        var code_gen = zjit.CodeGen.init(self.alloc, &self.emitter);
        return try code_gen.compileModule(self.module);
    }

    fn valTypeToIR(self: *Translator, vt: wasmmod.ValType) zjit.IR.Type {
        _ = self;
        return switch(vt) {
            .i32 => .i32,
            .i64 => .i64,
            .f32 => @panic("f32 not supported"),
            .f64 => @panic("f64 not supported"),
        };
    }
};