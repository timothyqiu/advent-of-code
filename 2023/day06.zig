const std = @import("std");
const Allocator = std.mem.Allocator;
const expectEqual = std.testing.expectEqual;

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const input = try std.fs.cwd().readFileAlloc(allocator, "inputs/day06.txt", 40960);
    defer allocator.free(input);

    const stdout = std.io.getStdOut().writer();
    try stdout.print("Part One: {}\n", .{try partOne(allocator, input)});

    const race = try buildRace(input);
    try stdout.print("Part Two: {}\n", .{race.calculateWays()});
}

fn partOne(allocator: Allocator, input: []const u8) !usize {
    const table = try buildRaceTable(allocator, input);
    defer table.deinit();

    var answer: usize = 1;
    for (table.items) |race| {
        answer *= race.calculateWays();
    }
    return answer;
}

fn partTwo(allocator: Allocator, input: []const u8) !usize {
    const table = try buildRaceTable(allocator, input);
    defer table.deinit();

    var answer: usize = 1;
    for (table.items) |race| {
        answer *= race.calculateWays();
    }
    return answer;
}

const Race = struct {
    time: usize,
    distance: usize,

    fn calculateWays(self: @This()) usize {
        var count: usize = 0;

        for (1..self.time) |time| {
            const distance = (self.time - time) * time;
            if (self.distance < distance) {
                count += 1;
            }
        }

        return count;
    }
};

const RaceTable = std.ArrayList(Race);

fn buildRaceTable(allocator: Allocator, input: []const u8) !RaceTable {
    var table = RaceTable.init(allocator);
    errdefer table.deinit();

    const second_line_start = std.mem.indexOfScalar(u8, input, '\n').?;
    const time_line = input[0..second_line_start];
    const dist_line = input[second_line_start + 1 ..];
    const DIGITS = "0123456789";

    var offset: usize = 0;
    while (offset < time_line.len) {
        const time_start = std.mem.indexOfAnyPos(u8, time_line, offset, DIGITS).?;
        const dist_start = std.mem.indexOfAnyPos(u8, dist_line, offset, DIGITS).?;

        const end = std.mem.indexOfNonePos(u8, time_line, time_start + 1, DIGITS) orelse time_line.len;

        const time = try std.fmt.parseInt(usize, time_line[time_start..end], 10);
        const dist = try std.fmt.parseInt(usize, dist_line[dist_start..end], 10);

        try table.append(.{ .time = time, .distance = dist });

        offset = end;
    }

    return table;
}

fn buildRace(input: []const u8) !Race {
    var final_time: usize = 0;
    var final_dist: usize = 0;

    const second_line_start = std.mem.indexOfScalar(u8, input, '\n').?;
    const time_line = input[0..second_line_start];
    const dist_line = input[second_line_start + 1 ..];
    const DIGITS = "0123456789";

    var offset: usize = 0;
    while (offset < time_line.len) {
        const time_start = std.mem.indexOfAnyPos(u8, time_line, offset, DIGITS).?;
        const dist_start = std.mem.indexOfAnyPos(u8, dist_line, offset, DIGITS).?;

        const end = std.mem.indexOfNonePos(u8, time_line, time_start + 1, DIGITS) orelse time_line.len;

        const time = try std.fmt.parseInt(usize, time_line[time_start..end], 10);
        const dist = try std.fmt.parseInt(usize, dist_line[dist_start..end], 10);

        final_time = final_time * try std.math.powi(usize, 10, end - time_start) + time;
        final_dist = final_dist * try std.math.powi(usize, 10, end - dist_start) + dist;

        offset = end;
    }

    return .{ .time = final_time, .distance = final_dist };
}

test {
    const allocator = std.testing.allocator;
    const input =
        \\Time:      7  15   30
        \\Distance:  9  40  200
    ;

    const table = try buildRaceTable(allocator, input);
    defer table.deinit();

    try expectEqual(@as(usize, 3), table.items.len);
    try expectEqual(Race{ .time = 7, .distance = 9 }, table.items[0]);
    try expectEqual(Race{ .time = 15, .distance = 40 }, table.items[1]);
    try expectEqual(Race{ .time = 30, .distance = 200 }, table.items[2]);

    try expectEqual(@as(usize, 4), table.items[0].calculateWays());
    try expectEqual(@as(usize, 8), table.items[1].calculateWays());
    try expectEqual(@as(usize, 9), table.items[2].calculateWays());

    try expectEqual(@as(usize, 288), try partOne(allocator, input));

    const race = try buildRace(input);
    try expectEqual(@as(usize, 71503), race.calculateWays());
}
