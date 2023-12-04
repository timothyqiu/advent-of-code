const std = @import("std");
const expectEqual = std.testing.expectEqual;

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    try stdout.print("Part One: {}\n", .{try partOne()});
    try stdout.print("Part Two: {}\n", .{try partTwo()});
}

fn partOne() !usize {
    const input = try std.fs.cwd().openFile("inputs/day05.txt", .{});
    defer input.close();

    var sum: usize = 0;

    var buffer: [256]u8 = undefined;
    while (try input.reader().readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        if (isNiceString(line)) {
            sum += 1;
        }
    }

    return sum;
}

fn partTwo() !usize {
    const input = try std.fs.cwd().openFile("inputs/day05.txt", .{});
    defer input.close();

    var sum: usize = 0;

    var buffer: [256]u8 = undefined;
    while (try input.reader().readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        if (isNiceStringPro(line)) {
            sum += 1;
        }
    }

    return sum;
}

fn isNiceString(input: []const u8) bool {
    var vowel_count: u8 = 0;
    for (input) |c| {
        if (std.mem.indexOfScalar(u8, "aeiou", c) != null) {
            vowel_count += 1;
            if (vowel_count >= 3) {
                break;
            }
        }
    } else {
        return false;
    }

    var last_letter: u8 = 0;
    for (input) |c| {
        if (c == last_letter) {
            break;
        }
        last_letter = c;
    } else {
        return false;
    }

    const bad_words = [_][]const u8{
        "ab", "cd", "pq", "xy",
    };
    for (bad_words) |word| {
        if (std.mem.indexOf(u8, input, word) != null) {
            return false;
        }
    }

    return true;
}

fn isNiceStringPro(input: []const u8) bool {
    if (input.len < 4) {
        return false;
    }

    for (0..input.len - 3) |start| {
        if (std.mem.indexOf(u8, input[start + 2 ..], input[start .. start + 2]) != null) {
            break;
        }
    } else {
        return false;
    }

    for (0..input.len - 2) |start| {
        if (input[start] == input[start + 2]) {
            break;
        }
    } else {
        return false;
    }

    return true;
}

test "part one" {
    try expectEqual(true, isNiceString("ugknbfddgicrmopn"));
    try expectEqual(true, isNiceString("aaa"));
    try expectEqual(false, isNiceString("jchzalrnumimnmhp"));
    try expectEqual(false, isNiceString("haegwjzuvuyypxyu"));
    try expectEqual(false, isNiceString("dvszwmarrgswjxmb"));
}

test "part two" {
    try expectEqual(true, isNiceStringPro("qjhvhtzxzqqjkmpb"));
    try expectEqual(true, isNiceStringPro("xxyxx"));
    try expectEqual(false, isNiceStringPro("uurcxstgmygtbstg"));
    try expectEqual(false, isNiceStringPro("ieodomkazucvgmuy"));
}
