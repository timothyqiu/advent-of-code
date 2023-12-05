const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const content = try std.fs.cwd().readFileAlloc(allocator, "inputs/day09.txt", 10240);
    defer allocator.free(content);

    const stdout = std.io.getStdOut().writer();
    try stdout.print("Part One: {}\n", .{try partOne(allocator, content)});
    try stdout.print("Part Two: {}\n", .{try partTwo(allocator, content)});
}

const DistanceMap = std.AutoHashMap(struct { u64, u64 }, usize);

fn partOne(allocator: Allocator, input: []const u8) !usize {
    var locations = std.AutoArrayHashMap(u64, void).init(allocator);
    defer locations.deinit();

    var distances = DistanceMap.init(allocator);
    defer distances.deinit();

    var line_iter = std.mem.tokenizeScalar(u8, input, '\n');
    while (line_iter.next()) |line| {
        const to_pos = std.mem.indexOf(u8, line, " to ").?;
        const equal_pos = std.mem.indexOfPos(u8, line, to_pos + 3, " = ").?;

        const src = std.hash.Wyhash.hash(0, line[0..to_pos]);
        const dst = std.hash.Wyhash.hash(0, line[to_pos + 4 .. equal_pos]);
        const distance = try std.fmt.parseInt(usize, line[equal_pos + 3 ..], 10);

        try locations.put(src, {});
        try locations.put(dst, {});
        try distances.put(.{ src, dst }, distance);
        try distances.put(.{ dst, src }, distance);
    }

    var shortest: usize = std.math.maxInt(usize);

    // Heap's algorithm.
    {
        var A = std.ArrayList(u64).init(allocator);
        defer A.deinit();

        try A.resize(locations.count());
        @memcpy(A.items, locations.keys());

        var c = std.ArrayList(usize).init(allocator);
        defer c.deinit();

        try c.resize(locations.count());
        @memset(c.items, 0);

        shortest = @min(shortest, getDistance(distances, A.items));

        var i: usize = 1;
        while (i < locations.count()) {
            if (c.items[i] < i) {
                if (i % 2 == 0) {
                    const tmp = A.items[0];
                    A.items[0] = A.items[i];
                    A.items[i] = tmp;
                } else {
                    const tmp = A.items[c.items[i]];
                    A.items[c.items[i]] = A.items[i];
                    A.items[i] = tmp;
                }

                shortest = @min(shortest, getDistance(distances, A.items));

                c.items[i] += 1;
                i = 1;
            } else {
                c.items[i] = 0;
                i += 1;
            }
        }
    }

    return shortest;
}

fn partTwo(allocator: Allocator, input: []const u8) !usize {
    var locations = std.AutoArrayHashMap(u64, void).init(allocator);
    defer locations.deinit();

    var distances = DistanceMap.init(allocator);
    defer distances.deinit();

    var line_iter = std.mem.tokenizeScalar(u8, input, '\n');
    while (line_iter.next()) |line| {
        const to_pos = std.mem.indexOf(u8, line, " to ").?;
        const equal_pos = std.mem.indexOfPos(u8, line, to_pos + 3, " = ").?;

        const src = std.hash.Wyhash.hash(0, line[0..to_pos]);
        const dst = std.hash.Wyhash.hash(0, line[to_pos + 4 .. equal_pos]);
        const distance = try std.fmt.parseInt(usize, line[equal_pos + 3 ..], 10);

        try locations.put(src, {});
        try locations.put(dst, {});
        try distances.put(.{ src, dst }, distance);
        try distances.put(.{ dst, src }, distance);
    }

    var longest: usize = std.math.minInt(usize);

    // Heap's algorithm.
    {
        var A = std.ArrayList(u64).init(allocator);
        defer A.deinit();

        try A.resize(locations.count());
        @memcpy(A.items, locations.keys());

        var c = std.ArrayList(usize).init(allocator);
        defer c.deinit();

        try c.resize(locations.count());
        @memset(c.items, 0);

        longest = @max(longest, getDistance(distances, A.items));

        var i: usize = 1;
        while (i < locations.count()) {
            if (c.items[i] < i) {
                if (i % 2 == 0) {
                    const tmp = A.items[0];
                    A.items[0] = A.items[i];
                    A.items[i] = tmp;
                } else {
                    const tmp = A.items[c.items[i]];
                    A.items[c.items[i]] = A.items[i];
                    A.items[i] = tmp;
                }

                longest = @max(longest, getDistance(distances, A.items));

                c.items[i] += 1;
                i = 1;
            } else {
                c.items[i] = 0;
                i += 1;
            }
        }
    }

    return longest;
}

fn getDistance(distances: DistanceMap, locations: []u64) usize {
    var sum: usize = 0;
    for (1..locations.len) |i| {
        sum += distances.get(.{ locations[i - 1], locations[i] }).?;
    }
    return sum;
}

test {
    const input =
        \\London to Dublin = 464
        \\London to Belfast = 518
        \\Dublin to Belfast = 141
    ;

    try std.testing.expectEqual(@as(usize, 605), try partOne(std.testing.allocator, input));
    try std.testing.expectEqual(@as(usize, 982), try partTwo(std.testing.allocator, input));
}
