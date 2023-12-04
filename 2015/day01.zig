const std = @import("std");

pub fn main() !void {
    const input = try std.fs.cwd().openFile("inputs/day01.txt", .{});
    defer input.close();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const content = try input.reader().readAllAlloc(allocator, 10240);

    const stdout = std.io.getStdOut().writer();
    try stdout.print("Part One: {}\n", .{try partOne(content)});
    try stdout.print("Part Two: {}\n", .{try partTwo(content)});
}

fn partOne(content: []const u8) !isize {
    var floor: isize = 0;

    for (content) |c| {
        switch (c) {
            '(' => floor += 1,
            ')' => floor -= 1,
            '\n' => {},
            else => unreachable,
        }
    }

    return floor;
}

fn partTwo(content: []const u8) !usize {
    var floor: isize = 0;

    for (content, 0..) |c, i| {
        switch (c) {
            '(' => floor += 1,
            ')' => floor -= 1,
            '\n' => {},
            else => unreachable,
        }

        if (floor < 0) {
            return i + 1;
        }
    }

    unreachable;
}

test "part one" {
    try std.testing.expectEqual(@as(isize, 0), try partOne("(())"));
    try std.testing.expectEqual(@as(isize, 0), try partOne("()()"));
    try std.testing.expectEqual(@as(isize, 3), try partOne("((("));
    try std.testing.expectEqual(@as(isize, 3), try partOne("(()(()("));
    try std.testing.expectEqual(@as(isize, 3), try partOne("))((((("));
    try std.testing.expectEqual(@as(isize, -1), try partOne("())"));
    try std.testing.expectEqual(@as(isize, -1), try partOne("))("));
    try std.testing.expectEqual(@as(isize, -3), try partOne(")))"));
    try std.testing.expectEqual(@as(isize, -3), try partOne(")())())"));
}

test "part two" {
    try std.testing.expectEqual(@as(usize, 1), try partTwo(")"));
    try std.testing.expectEqual(@as(usize, 5), try partTwo("()())"));
}
