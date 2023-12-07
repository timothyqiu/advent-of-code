const std = @import("std");
const Allocator = std.mem.Allocator;
const expectEqual = std.testing.expectEqual;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const input = try std.fs.cwd().readFileAlloc(allocator, "inputs/day17.txt", 1024);
    defer allocator.free(input);

    const stdout = std.io.getStdOut().writer();
    try stdout.print("Part One: {}\n", .{try partOne(allocator, input, 150)});
    try stdout.print("Part Two: {}\n", .{try partTwo(allocator, input, 150)});
}

fn partOne(allocator: Allocator, input: []const u8, target: usize) !usize {
    const puzzle = try Puzzle.init(allocator, input);
    defer puzzle.deinit();
    const containers_count = puzzle.containers.items.len;

    var amounts = std.ArrayList(usize).init(allocator);
    defer amounts.deinit();
    try amounts.resize(containers_count);
    @memset(amounts.items, 0);

    var count: usize = 0;
    while (true) {
        for (0..containers_count) |i| {
            if (amounts.items[i] == 1) {
                amounts.items[i] = 0;
            } else {
                amounts.items[i] = 1;
                break;
            }
        } else break;

        var sum: usize = 0;
        for (puzzle.containers.items, 0..) |size, i| {
            sum += size * amounts.items[i];
        }

        if (sum == target) {
            count += 1;
        }
    }

    return count;
}

fn partTwo(allocator: Allocator, input: []const u8, target: usize) !usize {
    const puzzle = try Puzzle.init(allocator, input);
    defer puzzle.deinit();
    const containers_count = puzzle.containers.items.len;

    var amounts = std.ArrayList(usize).init(allocator);
    defer amounts.deinit();
    try amounts.resize(containers_count);
    @memset(amounts.items, 0);

    var min: usize = std.math.maxInt(usize);
    var min_count: usize = undefined;

    while (true) {
        for (0..containers_count) |i| {
            if (amounts.items[i] == 1) {
                amounts.items[i] = 0;
            } else {
                amounts.items[i] = 1;
                break;
            }
        } else break;

        var sum: usize = 0;
        for (puzzle.containers.items, 0..) |size, i| {
            sum += size * amounts.items[i];
        }

        if (sum != target) {
            continue;
        }

        var used: usize = 0;
        for (amounts.items) |amount| {
            used += amount;
        }

        if (used < min) {
            min = used;
            min_count = 1;
        } else if (used == min) {
            min_count += 1;
        }
    }

    return min_count;
}

const Puzzle = struct {
    containers: std.ArrayList(u32),

    fn init(allocator: Allocator, input: []const u8) !Puzzle {
        var containers = std.ArrayList(u32).init(allocator);
        errdefer containers.deinit();

        var line_iter = std.mem.tokenizeScalar(u8, input, '\n');
        while (line_iter.next()) |line| {
            try containers.append(try std.fmt.parseInt(u32, line, 10));
        }

        return .{
            .containers = containers,
        };
    }

    fn deinit(self: Puzzle) void {
        self.containers.deinit();
    }
};

test {
    const allocator = std.testing.allocator;
    const input =
        \\20
        \\15
        \\10
        \\5
        \\5
    ;

    try expectEqual(@as(usize, 4), try partOne(allocator, input, 25));
    try expectEqual(@as(usize, 3), try partTwo(allocator, input, 25));
}
