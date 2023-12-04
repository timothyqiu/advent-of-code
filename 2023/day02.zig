const std = @import("std");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    try stdout.print("Part One: {}\n", .{try partOne("inputs/day02.txt")});
    try stdout.print("Part Two: {}\n", .{try partTwo("inputs/day02.txt")});
}

const CubeType = enum {
    red,
    green,
    blue,
};

fn toCubeType(token: []const u8) CubeType {
    inline for (@typeInfo(CubeType).Enum.fields) |field| {
        if (std.mem.eql(u8, token, field.name)) {
            return @enumFromInt(field.value);
        }
    }
    unreachable;
}

fn partOne(path: []const u8) !usize {
    const input = try std.fs.cwd().openFile(path, .{});
    defer input.close();

    var sum: usize = 0;

    var buffer: [256]u8 = undefined;
    while (try input.reader().readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        std.debug.assert(std.mem.startsWith(u8, line, "Game "));
        const skipped = line[5..];

        const colon = std.mem.indexOfScalar(u8, skipped, ':').?;
        const id = try std.fmt.parseInt(u32, skipped[0..colon], 10);

        const valid = blk: {
            var set_iter = std.mem.tokenizeAny(u8, skipped[colon + 1 ..], ";");
            while (set_iter.next()) |set| {
                var cube_iter = std.mem.tokenizeAny(u8, set, " ,");
                while (cube_iter.next()) |raw_count| {
                    const count = try std.fmt.parseInt(u32, raw_count, 10);
                    switch (toCubeType(cube_iter.next().?)) {
                        .red => if (count > 12) break :blk false,
                        .green => if (count > 13) break :blk false,
                        .blue => if (count > 14) break :blk false,
                    }
                }
            }
            break :blk true;
        };
        if (valid) {
            sum += id;
        }
    }

    return sum;
}

fn partTwo(path: []const u8) !usize {
    const input = try std.fs.cwd().openFile(path, .{});
    defer input.close();

    var sum: usize = 0;

    var buffer: [256]u8 = undefined;
    while (try input.reader().readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        std.debug.assert(std.mem.startsWith(u8, line, "Game "));
        const skipped = line[5..];

        const colon = std.mem.indexOfScalar(u8, skipped, ':').?;

        var max = struct { red: usize = 0, green: usize = 0, blue: usize = 0 }{};

        var set_iter = std.mem.tokenizeAny(u8, skipped[colon + 1 ..], ";");
        while (set_iter.next()) |set| {
            var cube_iter = std.mem.tokenizeAny(u8, set, " ,");
            while (cube_iter.next()) |raw_count| {
                const count = try std.fmt.parseInt(u32, raw_count, 10);
                switch (toCubeType(cube_iter.next().?)) {
                    .red => if (count > max.red) {
                        max.red = count;
                    },
                    .green => if (count > max.green) {
                        max.green = count;
                    },
                    .blue => if (count > max.blue) {
                        max.blue = count;
                    },
                }
            }
        }

        sum += max.red * max.green * max.blue;
    }

    return sum;
}

test "part one" {
    try std.testing.expectEqual(@as(usize, 8), try partOne("tests/day02.txt"));
}

test "part two" {
    try std.testing.expectEqual(@as(usize, 2286), try partTwo("tests/day02.txt"));
}
