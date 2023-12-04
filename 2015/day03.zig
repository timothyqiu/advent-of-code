const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const input = try std.fs.cwd().openFile("inputs/day03.txt", .{});
    defer input.close();

    const content = try input.reader().readAllAlloc(allocator, 10240);

    const stdout = std.io.getStdOut().writer();

    try stdout.print("Part One: {}\n", .{try getHousesFirstYear(allocator, content)});
    try stdout.print("Part Two: {}\n", .{try getHousesSecondYear(allocator, content)});
}

const Vector2i = struct {
    x: i32,
    y: i32,
};

fn getHousesFirstYear(allocator: Allocator, input: []const u8) !usize {
    var visited = std.AutoHashMap(Vector2i, void).init(allocator);
    defer visited.deinit();

    var current = Vector2i{ .x = 0, .y = 0 };
    try visited.put(current, {});

    for (input) |c| {
        switch (c) {
            '^' => current.y -= 1,
            'v' => current.y += 1,
            '<' => current.x -= 1,
            '>' => current.x += 1,
            '\n' => {},
            else => unreachable,
        }

        try visited.put(current, {});
    }

    return visited.count();
}

fn getHousesSecondYear(allocator: Allocator, input: []const u8) !usize {
    var visited = std.AutoHashMap(Vector2i, void).init(allocator);
    defer visited.deinit();

    var santa = Vector2i{ .x = 0, .y = 0 };
    var robot = Vector2i{ .x = 0, .y = 0 };
    try visited.put(santa, {});

    var current: *Vector2i = &santa;

    for (input) |c| {
        switch (c) {
            '^' => current.y -= 1,
            'v' => current.y += 1,
            '<' => current.x -= 1,
            '>' => current.x += 1,
            '\n' => {},
            else => unreachable,
        }

        try visited.put(current.*, {});

        if (current == &santa) {
            current = &robot;
        } else {
            current = &santa;
        }
    }

    return visited.count();
}

test "part one" {
    try std.testing.expectEqual(@as(usize, 2), try getHousesFirstYear(std.testing.allocator, ">"));
    try std.testing.expectEqual(@as(usize, 4), try getHousesFirstYear(std.testing.allocator, "^>v<"));
    try std.testing.expectEqual(@as(usize, 2), try getHousesFirstYear(std.testing.allocator, "^v^v^v^v^v"));
}

test "part two" {
    try std.testing.expectEqual(@as(usize, 3), try getHousesSecondYear(std.testing.allocator, "^v"));
    try std.testing.expectEqual(@as(usize, 3), try getHousesSecondYear(std.testing.allocator, "^>v<"));
    try std.testing.expectEqual(@as(usize, 11), try getHousesSecondYear(std.testing.allocator, "^v^v^v^v^v"));
}
