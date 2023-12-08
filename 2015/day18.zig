const std = @import("std");
const Allocator = std.mem.Allocator;
const expectEqual = std.testing.expectEqual;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const input = try std.fs.cwd().readFileAlloc(allocator, "inputs/day18.txt", 1024 * 10);
    defer allocator.free(input);

    const stdout = std.io.getStdOut().writer();
    try stdout.print("Part One: {}\n", .{try partOne(allocator, input, 100, 100)});
    try stdout.print("Part Two: {}\n", .{try partTwo(allocator, input, 100, 100)});
}

fn partOne(allocator: Allocator, input: []const u8, size: u8, steps: usize) !usize {
    var puzzle = try Puzzle.init(allocator, input, .{ .size = size });
    defer puzzle.deinit();

    for (0..steps) |_| {
        puzzle.step();
    }

    var count: usize = 0;
    for (puzzle.grid) |on| {
        if (on) {
            count += 1;
        }
    }
    return count;
}

fn partTwo(allocator: Allocator, input: []const u8, size: u8, steps: usize) !usize {
    var puzzle = try Puzzle.init(allocator, input, .{ .size = size, .broken_corners = true });
    defer puzzle.deinit();

    for (0..steps) |_| {
        puzzle.step();
    }

    var count: usize = 0;
    for (puzzle.grid) |on| {
        if (on) {
            count += 1;
        }
    }
    return count;
}

const Puzzle = struct {
    const Options = struct {
        size: u8,
        broken_corners: bool = false,
    };

    allocator: Allocator,
    size: u8,
    grid: []bool,
    next: []bool,
    broken_corners: bool,

    fn init(allocator: Allocator, input: []const u8, options: Options) !Puzzle {
        const alloc_size: usize = @as(usize, options.size) * @as(usize, options.size);

        var grid = try allocator.alloc(bool, alloc_size);
        errdefer allocator.free(grid);

        var next = try allocator.alloc(bool, alloc_size);
        errdefer allocator.free(next);

        var i: usize = 0;
        for (input) |c| {
            switch (c) {
                '.' => grid[i] = false,
                '#' => grid[i] = true,
                '\n' => continue,
                else => return error.InvalidInput,
            }
            i += 1;
        }

        if (options.broken_corners) {
            turnOnCorners(grid, options.size);
        }

        @memcpy(next, grid);

        return .{
            .allocator = allocator,
            .size = options.size,
            .grid = grid,
            .next = next,
            .broken_corners = options.broken_corners,
        };
    }

    fn deinit(self: Puzzle) void {
        self.allocator.free(self.grid);
        self.allocator.free(self.next);
    }

    fn step(self: *Puzzle) void {
        for (0..self.size) |y| {
            for (0..self.size) |x| {
                const neighbours = self.countNeighbours(x, y);
                if (self.get(x, y)) {
                    if (neighbours != 2 and neighbours != 3) {
                        self.setNext(x, y, false);
                    }
                } else {
                    if (neighbours == 3) {
                        self.setNext(x, y, true);
                    }
                }
            }
        }

        if (self.broken_corners) {
            turnOnCorners(self.next, self.size);
        }

        @memcpy(self.grid, self.next);
    }

    fn turnOnCorners(grid: []bool, size: usize) void {
        grid[0] = true;
        grid[size * size - 1] = true;
        grid[size - 1] = true;
        grid[(size - 1) * size] = true;
    }

    fn setNext(self: Puzzle, x: usize, y: usize, value: bool) void {
        self.next[y * self.size + x] = value;
    }

    fn set(self: Puzzle, x: usize, y: usize, value: bool) void {
        self.grid[y * self.size + x] = value;
    }

    fn get(self: Puzzle, x: usize, y: usize) bool {
        return self.grid[y * self.size + x];
    }

    fn countNeighbours(self: Puzzle, x: usize, y: usize) usize {
        var count: usize = 0;

        for (0..3) |dy| {
            for (0..3) |dx| {
                if (dx == 1 and dy == 1) {
                    continue;
                }
                const cx = @as(i16, @intCast(x + dx)) - 1;
                if (cx < 0 or self.size <= cx) {
                    continue;
                }
                const cy = @as(i16, @intCast(y + dy)) - 1;
                if (cy < 0 or self.size <= cy) {
                    continue;
                }
                if (self.get(@intCast(cx), @intCast(cy))) {
                    count += 1;
                }
            }
        }

        return count;
    }

    fn toString(self: Puzzle, buffer: []u8) ![]const u8 {
        var writer: usize = 0;
        for (self.grid, 0..) |on, i| {
            if (i > 0 and i % self.size == 0) {
                buffer[writer] = '\n';
                writer += 1;
            }
            buffer[writer] = if (on) '#' else '.';
            writer += 1;
        }
        return buffer[0..writer];
    }
};

test "general" {
    const allocator = std.testing.allocator;
    const input =
        \\.#.#.#
        \\...##.
        \\#....#
        \\..#...
        \\#.#..#
        \\####..
    ;

    var puzzle = try Puzzle.init(allocator, input, .{ .size = 6 });
    defer puzzle.deinit();

    try expectEqual(@as(usize, 2), puzzle.countNeighbours(3, 0));
    try expectEqual(@as(usize, 4), puzzle.countNeighbours(2, 4));
}

test "part one" {
    const allocator = std.testing.allocator;
    const input =
        \\.#.#.#
        \\...##.
        \\#....#
        \\..#...
        \\#.#..#
        \\####..
    ;

    var puzzle = try Puzzle.init(allocator, input, .{ .size = 6 });
    defer puzzle.deinit();

    var buffer: [7 * 6]u8 = undefined;
    try std.testing.expectEqualStrings(
        \\.#.#.#
        \\...##.
        \\#....#
        \\..#...
        \\#.#..#
        \\####..
    , try puzzle.toString(&buffer));

    puzzle.step();
    try std.testing.expectEqualStrings(
        \\..##..
        \\..##.#
        \\...##.
        \\......
        \\#.....
        \\#.##..
    , try puzzle.toString(&buffer));

    puzzle.step();
    try std.testing.expectEqualStrings(
        \\..###.
        \\......
        \\..###.
        \\......
        \\.#....
        \\.#....
    , try puzzle.toString(&buffer));

    puzzle.step();
    try std.testing.expectEqualStrings(
        \\...#..
        \\......
        \\...#..
        \\..##..
        \\......
        \\......
    , try puzzle.toString(&buffer));

    puzzle.step();
    try std.testing.expectEqualStrings(
        \\......
        \\......
        \\..##..
        \\..##..
        \\......
        \\......
    , try puzzle.toString(&buffer));

    try expectEqual(@as(usize, 4), try partOne(allocator, input, 6, 4));
}

test "part two" {
    const allocator = std.testing.allocator;
    const input =
        \\##.#.#
        \\...##.
        \\#....#
        \\..#...
        \\#.#..#
        \\####.#
    ;

    var puzzle = try Puzzle.init(allocator, input, .{ .size = 6, .broken_corners = true });
    defer puzzle.deinit();

    var buffer: [7 * 6]u8 = undefined;
    try std.testing.expectEqualStrings(
        \\##.#.#
        \\...##.
        \\#....#
        \\..#...
        \\#.#..#
        \\####.#
    , try puzzle.toString(&buffer));

    puzzle.step();
    try std.testing.expectEqualStrings(
        \\#.##.#
        \\####.#
        \\...##.
        \\......
        \\#...#.
        \\#.####
    , try puzzle.toString(&buffer));

    puzzle.step();
    try std.testing.expectEqualStrings(
        \\#..#.#
        \\#....#
        \\.#.##.
        \\...##.
        \\.#..##
        \\##.###
    , try puzzle.toString(&buffer));

    puzzle.step();
    try std.testing.expectEqualStrings(
        \\#...##
        \\####.#
        \\..##.#
        \\......
        \\##....
        \\####.#
    , try puzzle.toString(&buffer));

    puzzle.step();
    try std.testing.expectEqualStrings(
        \\#.####
        \\#....#
        \\...#..
        \\.##...
        \\#.....
        \\#.#..#
    , try puzzle.toString(&buffer));

    puzzle.step();
    try std.testing.expectEqualStrings(
        \\##.###
        \\.##..#
        \\.##...
        \\.##...
        \\#.#...
        \\##...#
    , try puzzle.toString(&buffer));

    try expectEqual(@as(usize, 17), try partTwo(allocator, input, 6, 5));
}
