const std = @import("std");
const types = @import("../types.zig");

pub const WasmModule = struct {
    typesec: []FuncType,
    funcsec: []types.TypeIdx,
};

pub const FuncType = struct {
    params: []ValType,
    results: []ValType,
};

pub const ValType = enum(u8) {
    i32 = 0x7F,
    i64 = 0x7E,
    f32 = 0x7D,
    f64 = 0x7C,
};