const std = @import("std");
const Allocator = std.mem.Allocator;
const expectEqual = std.testing.expectEqual;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const input = try std.fs.cwd().readFileAlloc(allocator, "inputs/day08.txt", 1024 * 15);
    defer allocator.free(input);

    const stdout = std.io.getStdOut().writer();
    try stdout.print("Part One: {}\n", .{try partOne(allocator, input)});
    try stdout.print("Part Two: {}\n", .{try partTwo(allocator, input)});
}

fn partOne(allocator: Allocator, input: []const u8) !usize {
    var puzzle = try Puzzle.init(allocator, input);
    defer puzzle.deinit();

    var count: usize = 0;
    var current: []const u8 = "AAA";
    while (true) {
        const instruction = puzzle.instructions[count % puzzle.instructions.len];

        count += 1;
        const connection = puzzle.map.get(current).?;
        current = switch (instruction) {
            'L' => connection.left,
            'R' => connection.right,
            else => unreachable,
        };

        if (std.mem.eql(u8, current, "ZZZ")) {
            return count;
        }
    }

    unreachable;
}

fn partTwo(allocator: Allocator, input: []const u8) !usize {
    var puzzle = try Puzzle.init(allocator, input);
    defer puzzle.deinit();

    var steps = std.ArrayList(usize).init(allocator);
    defer steps.deinit();
    try steps.resize(puzzle.starts.items.len);

    start: for (puzzle.starts.items, 0..) |start, i| {
        var count: usize = 0;
        var current: []const u8 = start;
        while (true) {
            const instruction = puzzle.instructions[count % puzzle.instructions.len];

            count += 1;
            const connection = puzzle.map.get(current).?;
            current = switch (instruction) {
                'L' => connection.left,
                'R' => connection.right,
                else => unreachable,
            };

            if (current[2] == 'Z') {
                steps.items[i] = count;
                continue :start;
            }
        }
    }

    var result = steps.items[0];
    for (steps.items[1..]) |value| {
        result = lcm(result, value);
    }
    return result;
}

fn lcm(a: usize, b: usize) usize {
    return (a * b) / std.math.gcd(a, b);
}

const Puzzle = struct {
    const Connection = struct {
        left: []const u8,
        right: []const u8,
    };

    instructions: []const u8,
    map: std.StringHashMap(Connection),
    starts: std.ArrayList([]const u8),

    fn init(allocator: Allocator, input: []const u8) !Puzzle {
        var map = std.StringHashMap(Connection).init(allocator);
        errdefer map.deinit();

        var starts = std.ArrayList([]const u8).init(allocator);
        errdefer starts.deinit();

        var line_iter = std.mem.tokenizeScalar(u8, input, '\n');

        const instructions = line_iter.next().?;

        while (line_iter.next()) |line| {
            const from = line[0..3];
            try map.put(from, .{
                .left = line[7..10],
                .right = line[12..15],
            });
            if (from[2] == 'A') {
                try starts.append(from);
            }
        }

        return .{
            .instructions = instructions,
            .map = map,
            .starts = starts,
        };
    }

    fn deinit(self: *Puzzle) void {
        self.map.deinit();
        self.starts.deinit();
    }
};

test {
    const allocator = std.testing.allocator;

    try expectEqual(@as(usize, 2), try partOne(allocator,
        \\RL
        \\
        \\AAA = (BBB, CCC)
        \\BBB = (DDD, EEE)
        \\CCC = (ZZZ, GGG)
        \\DDD = (DDD, DDD)
        \\EEE = (EEE, EEE)
        \\GGG = (GGG, GGG)
        \\ZZZ = (ZZZ, ZZZ)
    ));
    try expectEqual(@as(usize, 6), try partOne(allocator,
        \\LLR
        \\
        \\AAA = (BBB, BBB)
        \\BBB = (AAA, ZZZ)
        \\ZZZ = (ZZZ, ZZZ)
    ));

    try expectEqual(@as(usize, 6), try partTwo(allocator,
        \\LR
        \\
        \\11A = (11B, XXX)
        \\11B = (XXX, 11Z)
        \\11Z = (11B, XXX)
        \\22A = (22B, XXX)
        \\22B = (22C, 22C)
        \\22C = (22Z, 22Z)
        \\22Z = (22B, 22B)
        \\XXX = (XXX, XXX)
    ));
}
