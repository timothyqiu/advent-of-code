const std = @import("std");
const expectEqual = std.testing.expectEqual;
const expectEqualStrings = std.testing.expectEqualStrings;

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    const input = "hxbxwxba";

    var buf: [8]u8 = undefined;
    try stdout.print("Part One: {s}\n", .{getNextPassword(&buf, input)});
    try stdout.print("Part Two: {s}\n", .{getNextPassword(&buf, &buf)});
}

fn getNextPassword(buf: *[8]u8, password: *const [8]u8) *[8]u8 {
    for (0..8) |i| {
        buf[i] = password[i];
    }

    while (true) {
        var i: usize = 7;
        while (i >= 0) {
            if (buf[i] == 'z') {
                if (i == 0) break;

                buf[i] = 'a';
                i -= 1;
                continue;
            } else {
                buf[i] += 1;
                break;
            }
        }

        if (isValidPassword(buf)) {
            break;
        }
    }

    return buf;
}

fn isValidPassword(string: *const [8]u8) bool {
    // Must include one increasing straight of at least three letters.
    for (0..string.len - 2) |i| {
        if (string[i] + 1 == string[i + 1] and string[i] + 2 == string[i + 2]) {
            break;
        }
    } else return false;

    // May not contain the letters i, o, or l.
    for (string) |c| {
        switch (c) {
            'i', 'o', 'l' => return false,
            else => {},
        }
    }

    // Must contain at least two different, non-overlapping pairs of letters.
    var pair_count: usize = 0;
    var last: ?u8 = null;
    for (string) |c| {
        if (last == c) {
            pair_count += 1;
            last = null;
        } else {
            last = c;
        }
    }

    return pair_count >= 2;
}

test {
    try expectEqual(false, isValidPassword("hijklmmn"));
    try expectEqual(false, isValidPassword("abbceffg"));
    try expectEqual(false, isValidPassword("abbcegjk"));

    var buf: [8]u8 = undefined;
    try expectEqualStrings("abcdffaa", getNextPassword(&buf, "abcdefgh"));
    try expectEqualStrings("ghjaabcc", getNextPassword(&buf, "ghijklmn"));
}
