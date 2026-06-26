const std = @import("std");
const wasmmod = @import("../wasm/module.zig");
const reader = @import("../wasm/reader.zig");
const zjit = @import("zjit");

const Export = wasmmod.Export;

pub const Opcodes = enum(u8) {
    local_get = 0x20,
    local_set = 0x21,
    i32_const = 0x41,
    i32_add   = 0x6A,
    i32_sub   = 0x6B,
    i32_mul   = 0x6C,
    end       = 0x0B,
};

pub const Translator = struct {
    alloc: std.mem.Allocator,
    emitter: zjit.Emitter,
    wasm: wasmmod.WasmModule,
    module: zjit.IR.Module,
    export_map: std.StringHashMap(usize),

    pub fn init(wasm: wasmmod.WasmModule, alloc: std.mem.Allocator) !Translator {
        const emitter = try zjit.Emitter.init(alloc, 1024);
        const module = zjit.IR.Module.init(alloc);

        return .{
            .alloc = alloc,
            .emitter = emitter,
            .wasm = wasm,
            .module = module,
            .export_map = std.StringHashMap(usize).init(alloc),
        };
    }

    pub fn deinit(self: *Translator) void {
        self.emitter.deinit();
        self.module.deinit();
    }

    pub fn translate(self: *Translator) !void {
        for (self.wasm.exportsec) |ex| {
            if (ex.kind != .func) continue;
            try self.translateFunction(ex);
        }
    }

    pub fn compile(self: *Translator) !zjit.GenModule {
        var code_gen = zjit.CodeGen.init(self.alloc, &self.emitter);
        return try code_gen.compileModule(self.module);
    }

    fn translateFunction(self: *Translator, ex: Export) !void {
        const func_idx = ex.index;
        const type_idx = self.wasm.funcsec[func_idx];
        const func_type = self.wasm.typesec[type_idx];
        const code = self.wasm.codesec[func_idx];

        const ir_params = try self.alloc.alloc(zjit.IR.Type, func_type.params.len);
        for (0..func_type.params.len) |idx| {
            ir_params[idx] = self.valTypeToIR(func_type.params[idx]);
        }

        const ir_return = self.valTypeToIR(func_type.results[0]);
        var function = try self.module.createFunction(ex.name, ir_params, ir_return);

        const fn_idx = self.module.functions.items.len - 1;
        try self.export_map.put(ex.name, fn_idx);

        try self.translateBody(&function, code.body);
    }

    fn translateBody(self: *Translator, function: *zjit.IR.Function, body: []const u8) !void {
        var locals: std.AutoHashMap(u32, zjit.IR.Value) = .init(self.alloc);
        var stack: std.ArrayList(u32) = .empty;
        var cursor = reader.Reader.init(body);

        while (!cursor.atEOF()) {
            const opcode = std.enums.fromInt(Opcodes, try cursor.readByte());

            if (opcode) |op| {
                switch (op) {
                    .local_get => {
                        const idx = try cursor.readULEB128();
                        const val = locals.get(idx) orelse function.getArg(idx).?;
                        try stack.append(self.alloc, val);
                    },

                    .local_set => {
                        const idx = try cursor.readULEB128();
                        const val = stack.pop().?;
                        try locals.put(idx, val);
                    },

                    .i32_const => {
                        const val = try cursor.readSLEB128();
                        const result = try function.iconst(@as(i64, val));
                        try stack.append(self.alloc, result);
                    },

                    .i32_add => {
                        const rhs = stack.pop().?;
                        const lhs = stack.pop().?;
                        const result = try function.iadd(lhs, rhs);
                        try stack.append(self.alloc, result);
                    },

                    .i32_sub => {
                        const rhs = stack.pop().?;
                        const lhs = stack.pop().?;
                        const result = try function.isub(lhs, rhs);
                        try stack.append(self.alloc, result);
                    },

                    .i32_mul => {
                        const rhs = stack.pop().?;
                        const lhs = stack.pop().?;
                        const result = try function.imul(lhs, rhs);
                        try stack.append(self.alloc, result);
                    },

                    .end => {
                        const ret_val = stack.pop().?;
                        try function.ret(ret_val);
                        break;
                    },

                    else => @panic("unsupported opcode"),
                }
            }
        }
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