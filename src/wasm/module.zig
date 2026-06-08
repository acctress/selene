const std = @import("std");
const types = @import("../types.zig");

pub const WasmModule = struct {
    typesec: []FuncType,
    funcsec: []types.TypeIdx,
    codesec: []Code,
    exportsec: []Export,
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

pub const Export = struct {
    name: []const u8,
    kind: ExportKind,
    index: u32,
};

pub const ExportKind = enum(u8) {
    func   = 0x00,
    table  = 0x01,
    memory = 0x02,
    global = 0x03
};