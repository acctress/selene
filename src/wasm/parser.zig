const std = @import("std");
const module = @import("module.zig");
const reader = @import("reader.zig");

const Reader = reader.Reader;
const FuncType = module.FuncType;
const ValType = module.ValType;
const WasmModule = module.WasmModule;

pub const ParserError = error {
    IncorrectSectionMarker,
    InvalidVersion,
    InvalidMagic,
};

pub const Parser = struct {
    alloc: std.mem.Allocator,
    data: []u8,
    pos: usize,

    pub fn init(path: []const u8, alloc: std.mem.Allocator, io: std.Io) !Parser {
        const cwd = std.Io.Dir.cwd();
        const data = try cwd.readFileAlloc(io, path, alloc, .unlimited);

        return .{
            .alloc = alloc,
            .data = data,
            .pos = 0,
        };
    }

    pub fn parse(self: *Parser) !WasmModule {
        const magic = self.data[0..4];
        if (!std.mem.eql(u8, magic, "\x00asm")) return ParserError.InvalidMagic;

        const version = self.data[4..8];
        if (!std.mem.eql(u8, version, &.{ 0x01, 0x00, 0x00, 0x00 })) return ParserError.InvalidVersion;

        var cursor: Reader = .init(self.data[8..]);

        var typesec: []FuncType = &.{ };

        while (!cursor.atEOF()) {
            const sect_id = try cursor.readByte();
            const sect_len = try cursor.readULEB128();
            const sect_data: []u8 = try cursor.readSlice(sect_len);
            var sect_reader: Reader = .init(sect_data);

            switch (sect_id) {
                // type section
                0x01 => typesec = try self.parseTypeSection(&sect_reader),
                else => continue,
            }
        }

        return WasmModule{ .typesec = typesec };
    }

    fn parseTypeSection(self: *Parser, section: *Reader) ![]FuncType {
        const func_type_count = try section.readULEB128();
        const types = try self.alloc.alloc(FuncType, func_type_count);

        for (0..func_type_count) |idx| {
            const marker = try section.readByte();

            if (marker != 0x60) return ParserError.IncorrectSectionMarker;

            const param_count = try section.readULEB128();
            const params = try self.alloc.alloc(ValType, param_count);

            for (0..param_count) |i| {
                params[i] = std.enums.fromInt(ValType, try section.readByte()) orelse .i32;
            }

            const result_count = try section.readULEB128();
            const results = try self.alloc.alloc(ValType, result_count);

            for (0..result_count) |i| {
                results[i] = std.enums.fromInt(ValType, try section.readByte()) orelse .i32;
            }

            types[idx] = FuncType{ .params = params, .results = results };
        }

        return types;
    }
};