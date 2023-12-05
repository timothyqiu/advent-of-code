const std = @import("std");
const Allocator = std.mem.Allocator;
const expectEqualStrings = std.testing.expectEqualStrings;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const stdout = std.io.getStdOut().writer();

    const input = "1321131112";

    var feed: []const u8 = undefined;

    feed = input;
    for (0..40) |_| {
        feed = try lookAndSay(allocator, feed);
    }
    try stdout.print("Part One: {}\n", .{feed.len});

    feed = input;
    for (0..50) |_| {
        feed = try lookAndSay(allocator, feed);
    }
    try stdout.print("Part Two: {}\n", .{feed.len});
}

fn lookAndSay(allocator: Allocator, input: []const u8) ![]const u8 {
    if (input.len == 0) return error.InvalidInput;

    var output = try allocator.alloc(u8, input.len * 2);
    errdefer allocator.free(output);

    var last: u8 = input[0];
    var count: usize = 1;
    var output_len: usize = 0;

    for (input[1..]) |c| {
        if (c == last) {
            count += 1;
        } else {
            const printed = try std.fmt.bufPrint(output[output_len..], "{}{c}", .{ count, last });
            output_len += printed.len;

            last = c;
            count = 1;
        }
    }

    const printed = try std.fmt.bufPrint(output[output_len..], "{}{c}", .{ count, last });
    output_len += printed.len;

    return output[0..output_len];
}

test {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    try expectEqualStrings("11", try lookAndSay(allocator, "1"));
    try expectEqualStrings("21", try lookAndSay(allocator, "11"));
    try expectEqualStrings("1211", try lookAndSay(allocator, "21"));
    try expectEqualStrings("111221", try lookAndSay(allocator, "1211"));
    try expectEqualStrings("312211", try lookAndSay(allocator, "111221"));
}
