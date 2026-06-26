const std = @import("std");

pub const Reader = struct {
    bytes: []u8,
    pos: usize,

    pub fn init(bytes: []u8) Reader {
        return .{ .bytes = bytes, .pos = 0 };
    }

    pub fn atEOF(self: *Reader) bool {
        return self.pos >= self.bytes.len;
    }

    pub fn skip(self: *Reader, n: u32) !void {
        if (self.pos + n > self.bytes.len) return error.OutOfBoundsSkip;
        self.pos += n;
    }

    pub fn readSlice(self: *Reader, n: u32) ![]u8 {
        if (self.pos + n > self.bytes.len) return error.UnexpectedEof;
        const slice = self.bytes[self.pos..self.pos+n];
        self.pos += n;
        return slice;
    }

    pub fn readULEB128(self: *Reader) !u32 {
        var result: u32 = 0;
        var shift: u3 = 0;

        // while the higher order bit is not 0
        while (true) {
            if (self.atEOF()) return error.UnexpectedEof;

            const byte: u8 = self.bytes[self.pos];
            self.pos += 1;

            result |= (byte & 0x7F) << shift;
            shift += 7;

            if ((byte & 0x80) == 0)
                return result;
        }
    }

    pub fn readSLEB128(self: *Reader) !i32 {
        var result: i32 = 0;
        var shift: u5 = 0;
        var byte: u8 = 0;

        // while the higher order bit is not 0
        while (true) {
            if (self.atEOF()) return error.UnexpectedEof;

            byte = self.bytes[self.pos];
            self.pos += 1;

            result |= @as(i32, @intCast(byte & 0x7F)) << shift;
            shift += 7;

            if ((byte & 0x80) == 0) break;
        }

        if (shift < 32 and (byte & 0x40) != 0)
            result |= @as(i32, -1) << shift;

        return result;
    }

    pub fn readByte(self: *Reader) !u8 {
        if (self.atEOF()) return error.UnexpectedEof;

        const b = self.bytes[self.pos];
        self.pos += 1;
        return b;
    }

    pub fn remaining(self: *Reader) usize {
        return self.bytes.len - self.pos;
    }
};