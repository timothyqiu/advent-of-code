const std = @import("std");
const Allocator = std.mem.Allocator;
const expectEqual = std.testing.expectEqual;

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const stdout = std.io.getStdOut().writer();

    const input = try std.fs.cwd().readFileAlloc(allocator, "inputs/day05.txt", 40960);
    defer allocator.free(input);

    try stdout.print("Part One: {}\n", .{try partOne(allocator, input)});
    try stdout.print("Part Two: {}\n", .{try partTwo(allocator, input)});
}

fn partOne(allocator: Allocator, input: []const u8) !usize {
    var workspace = std.ArrayList(usize).init(allocator);
    defer workspace.deinit();

    var line_iter = std.mem.tokenizeScalar(u8, input, '\n');
    if (line_iter.next()) |line| {
        std.debug.assert(std.mem.startsWith(u8, line, "seeds: "));
        var seed_iter = std.mem.tokenizeScalar(u8, line[7..], ' ');
        while (seed_iter.next()) |token| {
            try workspace.append(try std.fmt.parseInt(usize, token, 10));
        }
    } else unreachable;

    var mapped = std.ArrayList(bool).init(allocator);
    defer mapped.deinit();
    try mapped.resize(workspace.items.len);

    while (line_iter.next()) |line| {
        if (std.mem.endsWith(u8, line, " map:")) {
            @memset(mapped.items, false);
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

fn partTwo(allocator: Allocator, input: []const u8) !usize {
    const SeedRange = struct {
        src: usize,
        len: usize,
    };

    var workspace = std.ArrayList(SeedRange).init(allocator);
    defer workspace.deinit();

    var line_iter = std.mem.tokenizeScalar(u8, input, '\n');
    if (line_iter.next()) |line| {
        std.debug.assert(std.mem.startsWith(u8, line, "seeds: "));
        var seed_iter = std.mem.tokenizeScalar(u8, line[7..], ' ');

        while (seed_iter.next()) |token| {
            const src = try std.fmt.parseInt(usize, token, 10);
            const len = try std.fmt.parseInt(usize, seed_iter.next().?, 10);
            try workspace.append(.{ .src = src, .len = len });
        }
    } else unreachable;

    var mapped = std.ArrayList(bool).init(allocator);
    defer mapped.deinit();
    try mapped.resize(workspace.items.len);

    while (line_iter.next()) |line| {
        if (std.mem.endsWith(u8, line, " map:")) {
            @memset(mapped.items, false);
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
            @memset(mapped.items[mapped.items.len - new_ranges.items.len ..], false);
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

test {
    const allocator = std.testing.allocator;
    const input =
        \\seeds: 79 14 55 13
        \\
        \\seed-to-soil map:
        \\50 98 2
        \\52 50 48
        \\
        \\soil-to-fertilizer map:
        \\0 15 37
        \\37 52 2
        \\39 0 15
        \\
        \\fertilizer-to-water map:
        \\49 53 8
        \\0 11 42
        \\42 0 7
        \\57 7 4
        \\
        \\water-to-light map:
        \\88 18 7
        \\18 25 70
        \\
        \\light-to-temperature map:
        \\45 77 23
        \\81 45 19
        \\68 64 13
        \\
        \\temperature-to-humidity map:
        \\0 69 1
        \\1 0 69
        \\
        \\humidity-to-location map:
        \\60 56 37
        \\56 93 4
    ;
    try expectEqual(@as(usize, 35), try partOne(allocator, input));
    try expectEqual(@as(usize, 46), try partTwo(allocator, input));
}
