const std = @import("std");
const Allocator = std.mem.Allocator;
const expectEqual = std.testing.expectEqual;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const input = try std.fs.cwd().readFileAlloc(allocator, "inputs/day10.txt", 1024 * 32);
    defer allocator.free(input);

    const stdout = std.io.getStdOut().writer();
    try stdout.print("Part One: {}\n", .{try partOne(allocator, input)});
    try stdout.print("Part Two: {}\n", .{try partTwo(allocator, input)});
}

fn partOne(allocator: Allocator, input: []const u8) !usize {
    const puzzle = try Puzzle.init(allocator, input);
    defer puzzle.deinit();

    var last = puzzle.start;
    var current = puzzle.getNext(puzzle.start, null);

    var steps: usize = 1;
    while (current.x != puzzle.start.x or current.y != puzzle.start.y) : (steps += 1) {
        var next = puzzle.getNext(current, last);
        last = current;
        current = next;
    }

    return steps / 2;
}

fn partTwo(allocator: Allocator, input: []const u8) !usize {
    const puzzle = try Puzzle.init(allocator, input);
    defer puzzle.deinit();

    var boundary = Boundary.init(allocator);
    defer boundary.deinit();

    var last = puzzle.start;
    var current = puzzle.getNext(puzzle.start, null);

    try boundary.put(puzzle.start, {});
    var top_left = puzzle.start;
    var bottom_right = puzzle.start;

    while (current.x != puzzle.start.x or current.y != puzzle.start.y) {
        try boundary.put(current, {});
        top_left = .{
            .x = @min(top_left.x, current.x),
            .y = @min(top_left.y, current.y),
        };
        bottom_right = .{
            .x = @max(bottom_right.x, current.x),
            .y = @max(bottom_right.y, current.y),
        };

        var next = puzzle.getNext(current, last);
        last = current;
        current = next;
    }

    var count: usize = 0;
    for (top_left.y..bottom_right.y + 1) |y| {
        for (top_left.x..bottom_right.x + 1) |x| {
            const cell = Vector2i{ .x = x, .y = y };
            if (boundary.contains(cell)) {
                continue;
            }

            if (puzzle.isInside(boundary, cell)) {
                count += 1;
            }
        }
    }

    return count;
}

const Vector2i = struct { x: usize, y: usize };
const Boundary = std.AutoHashMap(Vector2i, void);

const Puzzle = struct {
    allocator: Allocator,
    map: []const u8,
    size: Vector2i,
    start: Vector2i,

    fn init(allocator: Allocator, input: []const u8) !Puzzle {
        const width = std.mem.indexOfScalar(u8, input, '\n').?;

        const height = blk: {
            var line_iter = std.mem.tokenizeScalar(u8, input, '\n');
            var y: usize = 0;
            while (line_iter.next()) |_| {
                y += 1;
            }
            break :blk y;
        };

        var map = try allocator.alloc(u8, width * height);
        errdefer allocator.free(map);

        var start: Vector2i = undefined;
        for (0..height) |y| {
            for (0..width) |x| {
                const c = input[y * (width + 1) + x];
                if (c == 'S') {
                    start.x = x;
                    start.y = y;
                }
                map[y * width + x] = c;
            }
        }

        const size = Vector2i{ .x = width, .y = height };
        const start_neighbours = getNeighbours(map, size, start);
        map[start.y * width + start.x] = switch (start_neighbours) {
            0b1100 => 'L',
            0b1010 => '|',
            0b1001 => 'J',
            0b0110 => 'F',
            0b0101 => '-',
            0b0011 => '7',
            else => unreachable,
        };

        return .{
            .allocator = allocator,
            .map = map,
            .size = size,
            .start = start,
        };
    }

    fn deinit(self: Puzzle) void {
        self.allocator.free(self.map);
    }

    fn getCell(self: Puzzle, cell: Vector2i) u8 {
        return self.map[cell.y * self.size.x + cell.x];
    }

    fn getNext(self: Puzzle, current: Vector2i, last: ?Vector2i) Vector2i {
        switch (self.getCell(current)) {
            '|' => if (last == null or last.?.y < current.y) {
                return .{ .x = current.x, .y = current.y + 1 };
            } else {
                return .{ .x = current.x, .y = current.y - 1 };
            },
            '-' => if (last == null or last.?.x < current.x) {
                return .{ .x = current.x + 1, .y = current.y };
            } else {
                return .{ .x = current.x - 1, .y = current.y };
            },
            '7' => if (last == null or last.?.x < current.x) {
                return .{ .x = current.x, .y = current.y + 1 };
            } else {
                return .{ .x = current.x - 1, .y = current.y };
            },
            'L' => if (last == null or last.?.x == current.x) {
                return .{ .x = current.x + 1, .y = current.y };
            } else {
                return .{ .x = current.x, .y = current.y - 1 };
            },
            'J' => if (last == null or last.?.x == current.x) {
                return .{ .x = current.x - 1, .y = current.y };
            } else {
                return .{ .x = current.x, .y = current.y - 1 };
            },
            'F' => if (last == null or last.?.x == current.x) {
                return .{ .x = current.x + 1, .y = current.y };
            } else {
                return .{ .x = current.x, .y = current.y + 1 };
            },
            else => unreachable,
        }
    }

    fn getNeighbours(map: []const u8, size: Vector2i, cell: Vector2i) u4 {
        var neighbours: u4 = 0;

        if (0 < cell.y and cell.y < size.y) {
            const pos = Vector2i{ .x = cell.x, .y = cell.y - 1 };
            switch (map[pos.y * size.x + pos.x]) {
                '|', '7', 'F' => neighbours |= 0b1000,
                else => {},
            }
        }

        if (0 <= cell.x and cell.x < size.x - 1) {
            const pos = Vector2i{ .x = cell.x + 1, .y = cell.y };
            switch (map[pos.y * size.x + pos.x]) {
                '-', 'J', '7' => neighbours |= 0b0100,
                else => {},
            }
        }

        if (0 <= cell.y and cell.y < size.y - 1) {
            const pos = Vector2i{ .x = cell.x, .y = cell.y + 1 };
            switch (map[pos.y * size.x + pos.x]) {
                '|', 'L', 'J' => neighbours |= 0b0010,
                else => {},
            }
        }

        if (0 < cell.x and cell.x < size.x) {
            const pos = Vector2i{ .x = cell.x - 1, .y = cell.y };
            switch (map[pos.y * size.x + pos.x]) {
                '-', 'F', 'L' => neighbours |= 0b0001,
                else => {},
            }
        }

        return neighbours;
    }

    fn isInside(self: Puzzle, boundary: Boundary, cell: Vector2i) bool {
        var count: usize = 0;

        var i: usize = 0;
        while (i < cell.y) {
            const pos = Vector2i{ .x = cell.x, .y = i };
            if (!boundary.contains(pos)) {
                i += 1;
                continue;
            }

            switch (self.getCell(pos)) {
                '-' => {
                    count += 1;
                    i += 1;
                },

                '7' => {
                    i += 1;
                    while (i < cell.y) {
                        switch (self.getCell(.{ .x = cell.x, .y = i })) {
                            'L' => {
                                count += 1;
                                i += 1;
                                break;
                            },

                            'J' => {
                                i += 1;
                                break;
                            },
                            '|' => i += 1,
                            else => unreachable,
                        }
                    }
                },

                'F' => {
                    i += 1;
                    while (i < cell.y) {
                        switch (self.getCell(.{ .x = cell.x, .y = i })) {
                            'J' => {
                                count += 1;
                                i += 1;
                                break;
                            },

                            'L' => {
                                i += 1;
                                break;
                            },
                            '|' => i += 1,
                            else => unreachable,
                        }
                    }
                },

                else => unreachable,
            }
        }

        return count % 2 == 1;
    }
};

test {
    const allocator = std.testing.allocator;

    try expectEqual(@as(usize, 4), try partOne(allocator,
        \\.....
        \\.S-7.
        \\.|.|.
        \\.L-J.
        \\.....
    ));

    try expectEqual(@as(usize, 8), try partOne(allocator,
        \\..F7.
        \\.FJ|.
        \\SJ.L7
        \\|F--J
        \\LJ...
    ));

    try expectEqual(@as(usize, 4), try partTwo(allocator,
        \\...........
        \\.S-------7.
        \\.|F-----7|.
        \\.||.....||.
        \\.||.....||.
        \\.|L-7.F-J|.
        \\.|..|.|..|.
        \\.L--J.L--J.
        \\...........
    ));

    try expectEqual(@as(usize, 4), try partTwo(allocator,
        \\..........
        \\.S------7.
        \\.|F----7|.
        \\.||....||.
        \\.||....||.
        \\.|L-7F-J|.
        \\.|..||..|.
        \\.L--JL--J.
        \\..........
    ));

    try expectEqual(@as(usize, 8), try partTwo(allocator,
        \\.F----7F7F7F7F-7....
        \\.|F--7||||||||FJ....
        \\.||.FJ||||||||L7....
        \\FJL7L7LJLJ||LJ.L-7..
        \\L--J.L7...LJS7F-7L7.
        \\....F-J..F7FJ|L7L7L7
        \\....L7.F7||L7|.L7L7|
        \\.....|FJLJ|FJ|F7|.LJ
        \\....FJL-7.||.||||...
        \\....L---J.LJ.LJLJ...
    ));

    try expectEqual(@as(usize, 10), try partTwo(allocator,
        \\FF7FSF7F7F7F7F7F---7
        \\L|LJ||||||||||||F--J
        \\FL-7LJLJ||||||LJL-77
        \\F--JF--7||LJLJ7F7FJ-
        \\L---JF-JLJ.||-FJLJJ7
        \\|F|F-JF---7F7-L7L|7|
        \\|FFJF7L7F-JF7|JL---7
        \\7-L-JL7||F7|L7F-7F7|
        \\L.L7LFJ|||||FJL7||LJ
        \\L7JLJL-JLJLJL--JLJ.L
    ));
}
