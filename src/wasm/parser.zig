const std = @import("std");
const module = @import("module.zig");
const reader = @import("reader.zig");
const t = @import("../types.zig");

const Reader = reader.Reader;

const TypeIdx = t.TypeIdx;
const Local = module.Local;
const FuncType = module.FuncType;
const ValType = module.ValType;
const Code = module.Code;
const WasmModule = module.WasmModule;

pub const SectionId = enum(u8) {
    customsec = 0x0,
    typesec = 0x1,
    importsec = 0x2,
    funcsec = 0x3,
    tablesec = 0x4,
    memsec = 0x5,
    globalsec = 0x6,
    exportsec = 0x7,
    startsec = 0x8,
    elemsec = 0x9,
    codesec = 0x0A,
    datasec = 0x0B,
    datacsec = 0x0C,
    tagsec = 0x0D,
};

pub const ParserError = error {
    IncorrectSectionMarker,
    InvalidVersion,
    InvalidMagic,
};

pub const Parser = struct {
    alloc: std.mem.Allocator,
    data: []u8,

    pub fn init(path: []const u8, alloc: std.mem.Allocator, io: std.Io) !Parser {
        const cwd = std.Io.Dir.cwd();
        const data = try cwd.readFileAlloc(io, path, alloc, .unlimited);

        return .{
            .alloc = alloc,
            .data = data,
        };
    }

    pub fn initFromBytes(bytes: []const u8, alloc: std.mem.Allocator) Parser {
        return .{
            .alloc = alloc,
            .data = bytes,
        };
    }

    pub fn parse(self: *Parser) !WasmModule {
        const magic = self.data[0..4];
        if (!std.mem.eql(u8, magic, "\x00asm")) return ParserError.InvalidMagic;

        const version = self.data[4..8];
        if (!std.mem.eql(u8, version, &.{ 0x01, 0x00, 0x00, 0x00 })) return ParserError.InvalidVersion;

        var cursor: Reader = .init(self.data[8..]);

        var typesec: []FuncType = &.{ };
        var funcsec: []TypeIdx  = &.{ };
        var codesec: []Code     = &.{ };

        while (!cursor.atEOF()) {
            const sect_id_byte = try cursor.readByte();
            const sect_len = try cursor.readULEB128();
            const sect_data: []u8 = try cursor.readSlice(sect_len);
            const sect_id = std.enums.fromInt(SectionId, sect_id_byte) orelse continue;

            var sect_reader: Reader = .init(sect_data);

            switch (sect_id) {
                .typesec => typesec = try self.parseTypeSection(&sect_reader),
                .funcsec => funcsec = try self.parseFunctionSection(&sect_reader),
                .codesec => codesec = try self.parseCodeSection(&sect_reader),
                else => continue,
            }
        }

        return WasmModule{ .typesec = typesec, .funcsec = funcsec, .codesec = codesec };
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

    fn parseFunctionSection(self: *Parser, section: *Reader) ![]TypeIdx {
        const count = try section.readULEB128();
        const entries = try self.alloc.alloc(TypeIdx, count);

        for (0..count) |i| {
            entries[i] = try section.readULEB128();
        }

        return entries;
    }

    fn parseCodeSection(self: *Parser, section: *Reader) ![]Code {
        const count = try section.readULEB128();
        const entries = try self.alloc.alloc(Code, count);

        for (0..count) |idx| {
            const entry_size = try section.readULEB128();
            const entry_data = try section.readSlice(entry_size);
            var entry_reader = Reader.init(entry_data);

            const locals_count = try entry_reader.readULEB128();
            const locals = try self.alloc.alloc(Local, locals_count);

            for (0..locals_count) |i| {
                locals[i] = Local{
                    .count = try entry_reader.readULEB128(),
                    .type = std.enums.fromInt(ValType, try entry_reader.readByte()) orelse .i32,
                };
            }

            const rem = entry_reader.remaining();
            const body = try entry_reader.readSlice(@intCast(rem));
            entries[idx] = Code{ .locals = locals, .body = body };
        }

        return entries;
    }
};

const testing = std.testing;
const add_wasm = @embedFile("../../wasms/add.wasm");

test "parse add.wasm type section" {
    var parser = Parser.initFromBytes(add_wasm, testing.allocator);
    const mod = try parser.parse();
    
    try testing.expectEqual(1, mod.typesec.len);
    try testing.expectEqual(1, mod.funcsec.len);
}