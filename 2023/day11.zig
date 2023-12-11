const std = @import("std");
const Allocator = std.mem.Allocator;
const expectEqual = std.testing.expectEqual;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const input = try std.fs.cwd().readFileAlloc(allocator, "inputs/day11.txt", 1024 * 32);
    defer allocator.free(input);

    const stdout = std.io.getStdOut().writer();
    try stdout.print("Part One: {}\n", .{try sumLengths(allocator, input, 2)});
    try stdout.print("Part Two: {}\n", .{try sumLengths(allocator, input, 1000000)});
}

fn sumLengths(allocator: Allocator, input: []const u8, expand: usize) !usize {
    const puzzle = try Puzzle.init(allocator, input, expand);
    defer puzzle.deinit();

    var sum: usize = 0;
    for (puzzle.galaxies.items[0 .. puzzle.galaxies.items.len - 1], 0..) |lhs, i| {
        for (puzzle.galaxies.items[i + 1 ..]) |rhs| {
            const diff = lhs.diff(rhs);
            sum += diff.x + diff.y;
        }
    }

    return sum;
}

const Vector2i = struct {
    x: usize,
    y: usize,

    fn diff(self: Vector2i, other: Vector2i) Vector2i {
        const x = if (self.x > other.x) self.x - other.x else other.x - self.x;
        const y = if (self.y > other.y) self.y - other.y else other.y - self.y;
        return .{ .x = x, .y = y };
    }
};

const Puzzle = struct {
    galaxies: std.ArrayList(Vector2i),

    fn init(allocator: Allocator, input: []const u8, expand: usize) !Puzzle {
        var galaxies = std.ArrayList(Vector2i).init(allocator);
        errdefer galaxies.deinit();

        var expand_x = std.ArrayList(usize).init(allocator);
        defer expand_x.deinit();

        const input_width = std.mem.indexOfScalar(u8, input, '\n').?;
        const input_stride = input_width + 1;
        const input_height = blk: {
            var line_iter = std.mem.tokenizeScalar(u8, input, '\n');
            var expanded_y: usize = 0;
            var y: usize = 0;
            while (line_iter.next()) |line| {
                var is_empty = true;
                for (line, 0..) |c, x| {
                    if (c == '#') {
                        try galaxies.append(.{ .x = x, .y = expanded_y });
                        is_empty = false;
                    }
                }
                if (is_empty) {
                    expanded_y += (expand - 1);
                }
                y += 1;
                expanded_y += 1;
            }
            break :blk y;
        };
        for (0..input_width) |column| {
            const x = input_width - 1 - column;
            for (0..input_height) |row| {
                if (input[row * input_stride + x] == '#') {
                    break;
                }
            } else {
                for (galaxies.items) |*galaxy| {
                    if (galaxy.x > x) {
                        galaxy.x += (expand - 1);
                    }
                }
                try expand_x.append(column);
            }
        }

        return .{
            .galaxies = galaxies,
        };
    }

    fn deinit(self: Puzzle) void {
        self.galaxies.deinit();
    }
};

test {
    const allocator = std.testing.allocator;
    const input =
        \\...#......
        \\.......#..
        \\#.........
        \\..........
        \\......#...
        \\.#........
        \\.........#
        \\..........
        \\.......#..
        \\#...#.....
    ;

    try expectEqual(@as(usize, 374), try sumLengths(allocator, input, 2));
    try expectEqual(@as(usize, 1030), try sumLengths(allocator, input, 10));
    try expectEqual(@as(usize, 8410), try sumLengths(allocator, input, 100));
}
