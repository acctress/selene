const std = @import("std");

pub fn readFile(io: std.Io, alloc: std.mem.Allocator, path: []const u8) ![]u8 {
    var file = try std.Io.Dir.cwd().openFile(io, path, .{ .mode = .read_only });
    defer file.close(io);

    const stat = try file.stat(io);
    if (stat.size == 0) return error.FileEmpty;

    const data = try alloc.alloc(u8, @intCast(stat.size));
    _ = try file.readPositionalAll(io, data, 0);

    return data;
}