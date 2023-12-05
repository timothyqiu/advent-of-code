const std = @import("std");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const stdout = std.io.getStdOut().writer();

    const input = try std.fs.cwd().readFileAlloc(allocator, "inputs/day02.txt", 40960);
    defer allocator.free(input);

    try stdout.print("Part One: {}\n", .{try partOne(input)});
    try stdout.print("Part Two: {}\n", .{try partTwo(input)});
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

fn partOne(input: []const u8) !usize {
    var sum: usize = 0;

    var line_iter = std.mem.tokenizeScalar(u8, input, '\n');
    while (line_iter.next()) |line| {
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

fn partTwo(input: []const u8) !usize {
    var sum: usize = 0;

    var line_iter = std.mem.tokenizeScalar(u8, input, '\n');
    while (line_iter.next()) |line| {
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

test {
    const input =
        \\Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
        \\Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue
        \\Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red
        \\Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red
        \\Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green
    ;
    try std.testing.expectEqual(@as(usize, 8), try partOne(input));
    try std.testing.expectEqual(@as(usize, 2286), try partTwo(input));
}
