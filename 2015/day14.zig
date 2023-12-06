const std = @import("std");
const Allocator = std.mem.Allocator;
const expectEqual = std.testing.expectEqual;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const content = try std.fs.cwd().readFileAlloc(allocator, "inputs/day14.txt", 1024);
    defer allocator.free(content);

    const list = try buildReindeerList(allocator, content);
    defer list.deinit();

    const stdout = std.io.getStdOut().writer();

    try stdout.print("Part One: {}\n", .{try partOne(list, 2503)});
    try stdout.print("Part Two: {}\n", .{try partTwo(allocator, list, 2503)});
}

const DIGITS = "0123456789";
const Reindeer = struct {
    speed: usize,
    fly_time: usize,
    rest_time: usize,

    fn getDistance(self: Reindeer, time: usize) usize {
        const full_cycles = time / (self.fly_time + self.rest_time);
        const remaining = time % (self.fly_time + self.rest_time);
        return self.speed * (self.fly_time * full_cycles + @min(self.fly_time, remaining));
    }
};
const ReindeerList = std.ArrayList(Reindeer);

fn buildReindeerList(allocator: Allocator, input: []const u8) !ReindeerList {
    var reindeers = std.ArrayList(Reindeer).init(allocator);
    errdefer reindeers.deinit();

    var line_iter = std.mem.tokenizeScalar(u8, input, '\n');
    while (line_iter.next()) |line| {
        const speed_start = std.mem.indexOfAny(u8, line, DIGITS).?;
        const speed_end = std.mem.indexOfScalarPos(u8, line, speed_start + 1, ' ').?;
        const speed = try std.fmt.parseInt(usize, line[speed_start..speed_end], 10);

        const fly_time_start = std.mem.indexOfAnyPos(u8, line, speed_end, DIGITS).?;
        const fly_time_end = std.mem.indexOfScalarPos(u8, line, fly_time_start + 1, ' ').?;
        const fly_time = try std.fmt.parseInt(usize, line[fly_time_start..fly_time_end], 10);

        const rest_time_start = std.mem.indexOfAnyPos(u8, line, fly_time_end, DIGITS).?;
        const rest_time_end = std.mem.indexOfScalarPos(u8, line, rest_time_start + 1, ' ').?;
        const rest_time = try std.fmt.parseInt(usize, line[rest_time_start..rest_time_end], 10);

        try reindeers.append(.{ .speed = speed, .fly_time = fly_time, .rest_time = rest_time });
    }

    return reindeers;
}

fn partOne(list: ReindeerList, time: usize) !usize {
    var max: usize = std.math.minInt(usize);
    for (list.items) |reindeer| {
        max = @max(max, reindeer.getDistance(time));
    }

    return max;
}

fn partTwo(allocator: Allocator, list: ReindeerList, time: usize) !usize {
    var distances = std.ArrayList(usize).init(allocator);
    defer distances.deinit();
    try distances.resize(list.items.len);

    var scores = std.ArrayList(usize).init(allocator);
    defer scores.deinit();
    try scores.resize(list.items.len);
    @memset(scores.items, 0);

    for (1..time) |span| {
        var max: usize = std.math.minInt(usize);
        for (list.items, 0..) |reindeer, i| {
            const distance = reindeer.getDistance(span);
            distances.items[i] = distance;
            max = @max(max, distance);
        }

        for (distances.items, 0..) |distance, i| {
            if (distance == max) {
                scores.items[i] += 1;
            }
        }
    }

    var max_score: usize = std.math.minInt(usize);
    for (scores.items) |score| {
        max_score = @max(max_score, score);
    }

    return max_score;
}

test {
    const allocator = std.testing.allocator;
    const input =
        \\Comet can fly 14 km/s for 10 seconds, but then must rest for 127 seconds.
        \\Dancer can fly 16 km/s for 11 seconds, but then must rest for 162 seconds.
    ;

    const list = try buildReindeerList(allocator, input);
    defer list.deinit();

    try expectEqual(@as(usize, 1120), try partOne(list, 1000));
    try expectEqual(@as(usize, 689), try partTwo(allocator, list, 1000));
}
