const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    try stdout.print("Part One: {}\n", .{try partOne(std.heap.page_allocator, "inputs/day05.txt")});
    try stdout.print("Part Two: {}\n", .{try partTwo(std.heap.page_allocator, "inputs/day05.txt")});
}

fn partOne(allocator: Allocator, path: []const u8) !usize {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const arena_allocator = arena.allocator();

    const input = try std.fs.cwd().openFile(path, .{});
    defer input.close();

    var workspace = std.ArrayList(usize).init(arena_allocator);
    defer workspace.deinit();

    var mapped = std.ArrayList(bool).init(arena_allocator);
    defer mapped.deinit();

    var buffer: [256]u8 = undefined;

    if (try input.reader().readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        std.debug.assert(std.mem.startsWith(u8, line, "seeds: "));
        var seed_iter = std.mem.tokenizeScalar(u8, line[7..], ' ');
        while (seed_iter.next()) |token| {
            try workspace.append(try std.fmt.parseInt(usize, token, 10));
        }
    } else unreachable;

    try mapped.resize(workspace.items.len);

    var skip_next = false;
    while (try input.reader().readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        if (skip_next) {
            std.debug.assert(std.mem.endsWith(u8, line, " map:"));
            skip_next = false;
            continue;
        }
        if (line.len == 0) {
            for (mapped.items) |*item| {
                item.* = false;
            }
            skip_next = true;
            continue;
        }

        var iter = std.mem.tokenizeScalar(u8, line, ' ');
        const dst_start = try std.fmt.parseInt(usize, iter.next().?, 10);
        const src_start = try std.fmt.parseInt(usize, iter.next().?, 10);
        const length = try std.fmt.parseInt(usize, iter.next().?, 10);

        for (workspace.items, 0..) |value, i| {
            if (mapped.items[i]) {
                continue;
            }
            if (src_start <= value and value <= src_start + length) {
                const diff = (value - src_start);
                workspace.items[i] = dst_start + diff;
                mapped.items[i] = true;
            }
        }
    }

    var lowest: usize = std.math.maxInt(usize);
    for (workspace.items) |value| {
        if (value < lowest) {
            lowest = value;
        }
    }

    return lowest;
}

fn partTwo(allocator: Allocator, path: []const u8) !usize {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const arena_allocator = arena.allocator();

    const input = try std.fs.cwd().openFile(path, .{});
    defer input.close();

    const SeedRange = struct {
        src: usize,
        len: usize,
    };

    var workspace = std.ArrayList(SeedRange).init(arena_allocator);
    defer workspace.deinit();

    var mapped = std.ArrayList(bool).init(arena_allocator);
    defer mapped.deinit();

    var buffer: [256]u8 = undefined;

    if (try input.reader().readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        std.debug.assert(std.mem.startsWith(u8, line, "seeds: "));
        var seed_iter = std.mem.tokenizeScalar(u8, line[7..], ' ');

        while (seed_iter.next()) |token| {
            const src = try std.fmt.parseInt(usize, token, 10);
            const len = try std.fmt.parseInt(usize, seed_iter.next().?, 10);
            try workspace.append(.{ .src = src, .len = len });
        }
    } else unreachable;

    try mapped.resize(workspace.items.len);

    var skip_next = false;
    while (try input.reader().readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        if (skip_next) {
            std.debug.assert(std.mem.endsWith(u8, line, " map:"));
            skip_next = false;
            continue;
        }
        if (line.len == 0) {
            for (mapped.items) |*item| {
                item.* = false;
            }
            skip_next = true;
            continue;
        }

        var iter = std.mem.tokenizeScalar(u8, line, ' ');
        const dst_start = try std.fmt.parseInt(usize, iter.next().?, 10);
        const src_start = try std.fmt.parseInt(usize, iter.next().?, 10);
        const length = try std.fmt.parseInt(usize, iter.next().?, 10);
        const src_end = src_start + length;

        var new_ranges = std.ArrayList(SeedRange).init(allocator);
        defer new_ranges.deinit();

        for (workspace.items, 0..) |*value, i| {
            if (mapped.items[i]) {
                continue;
            }
            if (src_end < value.src or value.src + value.len < src_start) {
                continue;
            }
            if (value.src < src_start) {
                const len = src_start - value.src;
                try new_ranges.append(.{
                    .src = value.src,
                    .len = len,
                });
                value.src = src_start;
                value.len -= len;
            }
            if (src_end < value.src + value.len) {
                const len = value.src + value.len - src_end;
                try new_ranges.append(.{
                    .src = src_end + 1,
                    .len = len,
                });
                value.len -= len;
            }
            value.src = dst_start + (value.src - src_start);
            mapped.items[i] = true;
        }

        if (new_ranges.items.len > 0) {
            try workspace.appendSlice(new_ranges.items);
            try mapped.resize(workspace.items.len);
            for (mapped.items[mapped.items.len - new_ranges.items.len ..]) |*value| {
                value.* = false;
            }
        }
    }

    var lowest: usize = std.math.maxInt(usize);
    for (workspace.items) |range| {
        if (range.len == 0) {
            continue;
        }
        if (range.src < lowest) {
            lowest = range.src;
        }
    }

    return lowest;
}

test "part one" {
    try std.testing.expectEqual(@as(usize, 35), try partOne(std.testing.allocator, "tests/day05.txt"));
}

test "part two" {
    try std.testing.expectEqual(@as(usize, 46), try partTwo(std.testing.allocator, "tests/day05.txt"));
}
