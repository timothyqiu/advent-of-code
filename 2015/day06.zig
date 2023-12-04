const std = @import("std");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    try stdout.print("Part One: {}\n", .{try partOne()});
    try stdout.print("Part Two: {}\n", .{try partTwo()});
}

fn partOne() !usize {
    const input = try std.fs.cwd().openFile("inputs/day06.txt", .{});
    defer input.close();

    const SIZE = 1000;

    var grid = [_]bool{false} ** (SIZE * SIZE);

    var buffer: [256]u8 = undefined;
    while (try input.reader().readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        const action = try parseAction(line);
        const offset: usize = switch (action) {
            .turn_on => 8,
            .turn_off => 9,
            .toggle => 7,
        };

        var iter = std.mem.tokenizeAny(u8, line[offset..], " ,");
        const src_x = try std.fmt.parseInt(u16, iter.next().?, 10);
        const src_y = try std.fmt.parseInt(u16, iter.next().?, 10);
        _ = iter.next(); // through
        const dst_x = try std.fmt.parseInt(u16, iter.next().?, 10);
        const dst_y = try std.fmt.parseInt(u16, iter.next().?, 10);
        std.debug.assert(iter.next() == null);

        switch (action) {
            .turn_on => {
                for (src_y..dst_y + 1) |y| {
                    for (src_x..dst_x + 1) |x| {
                        grid[y * SIZE + x] = true;
                    }
                }
            },
            .turn_off => {
                for (src_y..dst_y + 1) |y| {
                    for (src_x..dst_x + 1) |x| {
                        grid[y * SIZE + x] = false;
                    }
                }
            },
            .toggle => {
                for (src_y..dst_y + 1) |y| {
                    for (src_x..dst_x + 1) |x| {
                        grid[y * SIZE + x] = !grid[y * SIZE + x];
                    }
                }
            },
        }
    }

    var count: usize = 0;
    for (grid) |value| {
        if (value) {
            count += 1;
        }
    }
    return count;
}

fn partTwo() !usize {
    const input = try std.fs.cwd().openFile("inputs/day06.txt", .{});
    defer input.close();

    const SIZE = 1000;

    var grid = [_]usize{0} ** (SIZE * SIZE);

    var buffer: [256]u8 = undefined;
    while (try input.reader().readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        const action = try parseAction(line);
        const offset: usize = switch (action) {
            .turn_on => 8,
            .turn_off => 9,
            .toggle => 7,
        };

        var iter = std.mem.tokenizeAny(u8, line[offset..], " ,");
        const src_x = try std.fmt.parseInt(u16, iter.next().?, 10);
        const src_y = try std.fmt.parseInt(u16, iter.next().?, 10);
        _ = iter.next(); // through
        const dst_x = try std.fmt.parseInt(u16, iter.next().?, 10);
        const dst_y = try std.fmt.parseInt(u16, iter.next().?, 10);
        std.debug.assert(iter.next() == null);

        switch (action) {
            .turn_on => {
                for (src_y..dst_y + 1) |y| {
                    for (src_x..dst_x + 1) |x| {
                        grid[y * SIZE + x] += 1;
                    }
                }
            },
            .turn_off => {
                for (src_y..dst_y + 1) |y| {
                    for (src_x..dst_x + 1) |x| {
                        if (grid[y * SIZE + x] > 0) {
                            grid[y * SIZE + x] -= 1;
                        }
                    }
                }
            },
            .toggle => {
                for (src_y..dst_y + 1) |y| {
                    for (src_x..dst_x + 1) |x| {
                        grid[y * SIZE + x] += 2;
                    }
                }
            },
        }
    }

    var count: usize = 0;
    for (grid) |value| {
        count += value;
    }
    return count;
}

const Action = enum {
    turn_on,
    turn_off,
    toggle,
};

fn parseAction(input: []const u8) !Action {
    if (std.mem.startsWith(u8, input, "turn on")) {
        return .turn_on;
    }
    if (std.mem.startsWith(u8, input, "turn off")) {
        return .turn_off;
    }
    if (std.mem.startsWith(u8, input, "toggle")) {
        return .toggle;
    }
    return error.InvalidInput;
}
