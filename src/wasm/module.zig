const std = @import("std");
const types = @import("../types.zig");

pub const WasmModule = struct {
    typesec: []FuncType,
    funcsec: []types.TypeIdx,
    codesec: []Code,
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

pub const Code = struct {
    locals: []Local,
    body:   []u8
};

pub const Local = struct {
    count: u32,
    type:  ValType
};