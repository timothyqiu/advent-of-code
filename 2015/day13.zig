const std = @import("std");
const Allocator = std.mem.Allocator;
const expectEqual = std.testing.expectEqual;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const content = try std.fs.cwd().readFileAlloc(allocator, "inputs/day13.txt", 4 * 1024);
    defer allocator.free(content);

    const stdout = std.io.getStdOut().writer();

    var survey = try Survey.init(allocator, content);
    defer survey.deinit();
    try stdout.print("Part One: {}\n", .{try survey.findOptimalChange(allocator)});

    try survey.people.put(0, {});
    try stdout.print("Part Two: {}\n", .{try survey.findOptimalChange(allocator)});
}

const Survey = struct {
    const HappinessMap = std.AutoHashMap(struct { u64, u64 }, isize);

    happiness_map: HappinessMap,
    people: std.AutoArrayHashMap(u64, void),

    fn init(allocator: Allocator, input: []const u8) !Survey {
        var people = std.AutoArrayHashMap(u64, void).init(allocator);
        errdefer people.deinit();

        var happiness_map = HappinessMap.init(allocator);
        errdefer happiness_map.deinit();

        var line_iter = std.mem.tokenizeScalar(u8, input, '\n');
        while (line_iter.next()) |line| {
            // Skip trailing period.
            var iter = std.mem.tokenizeScalar(u8, line[0 .. line.len - 1], ' ');

            const subject = std.hash.Wyhash.hash(0, iter.next().?);
            _ = iter.next(); // "would"

            const multiplier: isize = if (iter.next().?[0] == 'g') 1 else -1;
            const offset = try std.fmt.parseInt(isize, iter.next().?, 10) * multiplier;

            _ = iter.next(); // "happiness"
            _ = iter.next(); // "units"
            _ = iter.next(); // "by"
            _ = iter.next(); // "sitting"
            _ = iter.next(); // "next"
            _ = iter.next(); // "to"

            const object = std.hash.Wyhash.hash(0, iter.next().?);

            try people.put(object, {});
            try people.put(subject, {});
            try happiness_map.put(.{ subject, object }, offset);
        }
        return .{
            .happiness_map = happiness_map,
            .people = people,
        };
    }

    fn deinit(self: *Survey) void {
        self.happiness_map.deinit();
        self.people.deinit();
    }

    fn getTotalChange(self: Survey, arrangement: []u64) isize {
        var sum: isize = 0;

        for (0..arrangement.len) |i| {
            const prev: usize = if (i == 0) arrangement.len - 1 else i - 1;
            const next: usize = if (i == arrangement.len - 1) 0 else i + 1;

            sum += self.happiness_map.get(.{ arrangement[i], arrangement[prev] }) orelse 0;
            sum += self.happiness_map.get(.{ arrangement[i], arrangement[next] }) orelse 0;
        }
        return sum;
    }

    fn findOptimalChange(self: Survey, allocator: Allocator) !isize {
        var optimal: isize = std.math.minInt(isize);

        // Heap's algorithm.
        {
            var A = std.ArrayList(u64).init(allocator);
            defer A.deinit();

            try A.resize(self.people.count());
            @memcpy(A.items, self.people.keys());

            var c = std.ArrayList(usize).init(allocator);
            defer c.deinit();

            try c.resize(self.people.count());
            @memset(c.items, 0);

            optimal = @max(optimal, self.getTotalChange(A.items));

            var i: usize = 1;
            while (i < self.people.count()) {
                if (c.items[i] < i) {
                    if (i % 2 == 0) {
                        std.mem.swap(u64, &A.items[0], &A.items[i]);
                    } else {
                        std.mem.swap(u64, &A.items[c.items[i]], &A.items[i]);
                    }

                    optimal = @max(optimal, self.getTotalChange(A.items));

                    c.items[i] += 1;
                    i = 1;
                } else {
                    c.items[i] = 0;
                    i += 1;
                }
            }
        }

        return optimal;
    }
};

test {
    const allocator = std.testing.allocator;
    const input =
        \\Alice would gain 54 happiness units by sitting next to Bob.
        \\Alice would lose 79 happiness units by sitting next to Carol.
        \\Alice would lose 2 happiness units by sitting next to David.
        \\Bob would gain 83 happiness units by sitting next to Alice.
        \\Bob would lose 7 happiness units by sitting next to Carol.
        \\Bob would lose 63 happiness units by sitting next to David.
        \\Carol would lose 62 happiness units by sitting next to Alice.
        \\Carol would gain 60 happiness units by sitting next to Bob.
        \\Carol would gain 55 happiness units by sitting next to David.
        \\David would gain 46 happiness units by sitting next to Alice.
        \\David would lose 7 happiness units by sitting next to Bob.
        \\David would gain 41 happiness units by sitting next to Carol.
    ;
    var survey = try Survey.init(allocator, input);
    defer survey.deinit();

    try expectEqual(@as(isize, 330), try survey.findOptimalChange(allocator));
}
