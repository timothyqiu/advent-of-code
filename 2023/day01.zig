const std = @import("std");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    stdout.print("Part One: {}\n", .{try partOne("inputs/day01.txt")});
    stdout.print("Part Two: {}\n", .{try partTwo("inputs/day01.txt")});
}

fn partOne(path: []const u8) !usize {
    const input = try std.fs.cwd().openFile(path, .{});
    defer input.close();

    var sum: usize = 0;

    var buffer: [256]u8 = undefined;
    while (try input.reader().readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        var first_index: ?usize = null;
        var last_index: ?usize = null;
        for (line, 0..) |c, i| {
            if (!std.ascii.isDigit(c)) {
                continue;
            }
            if (first_index == null) {
                first_index = i;
            }
            last_index = i;
        }
        const value = (line[first_index.?] - '0') * 10 + (line[last_index.?] - '0');
        sum += value;
    }

    return sum;
}

fn partTwo(path: []const u8) !usize {
    const input = try std.fs.cwd().openFile(path, .{});
    defer input.close();

    // from one to nine
    const SPELLS = [_][]const u8{
        "one", "two", "three", "four", "five", "six", "seven", "eight", "nine",
    };

    var sum: usize = 0;

    var buffer: [256]u8 = undefined;
    while (try input.reader().readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        const first = search: for (0..line.len) |i| {
            if (std.ascii.isDigit(line[i])) {
                break line[i] - '0';
            }
            for (SPELLS, 1..) |word, n| {
                if (std.mem.startsWith(u8, line[i..], word)) {
                    break :search n;
                }
            }
        } else unreachable;

        const last = search: for (0..line.len) |i| {
            const from = line.len - 1 - i;
            if (std.ascii.isDigit(line[from])) {
                break line[from] - '0';
            }
            for (SPELLS, 1..) |word, n| {
                if (std.mem.startsWith(u8, line[from..], word)) {
                    break :search n;
                }
            }
        } else unreachable;

        const value = first * 10 + last;
        sum += value;
    }

    return sum;
}

test "part one" {
    try std.testing.expectEqual(@as(usize, 142), try partOne("tests/day01-part01.txt"));
}

test "part two" {
    try std.testing.expectEqual(@as(usize, 281), try partTwo("tests/day01-part02.txt"));
}
