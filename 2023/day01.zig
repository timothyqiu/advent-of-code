const std = @import("std");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const stdout = std.io.getStdOut().writer();

    const input = try std.fs.cwd().readFileAlloc(allocator, "inputs/day01.txt", 40960);
    defer allocator.free(input);

    try stdout.print("Part One: {}\n", .{try partOne(input)});
    try stdout.print("Part Two: {}\n", .{try partTwo(input)});
}

fn partOne(input: []const u8) !usize {
    var sum: usize = 0;

    var line_iter = std.mem.tokenizeScalar(u8, input, '\n');
    while (line_iter.next()) |line| {
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

fn partTwo(input: []const u8) !usize {
    // from one to nine
    const SPELLS = [_][]const u8{
        "one", "two", "three", "four", "five", "six", "seven", "eight", "nine",
    };

    var sum: usize = 0;

    var line_iter = std.mem.tokenizeScalar(u8, input, '\n');
    while (line_iter.next()) |line| {
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
    try std.testing.expectEqual(@as(usize, 142), try partOne(
        \\1abc2
        \\pqr3stu8vwx
        \\a1b2c3d4e5f
        \\treb7uchet
    ));
}

test "part two" {
    try std.testing.expectEqual(@as(usize, 281), try partTwo(
        \\two1nine
        \\eightwothree
        \\abcone2threexyz
        \\xtwone3four
        \\4nineeightseven2
        \\zoneight234
        \\7pqrstsixteen
    ));
}
