const std = @import("std");
const Allocator = std.mem.Allocator;
const expectEqual = std.testing.expectEqual;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const input = try std.fs.cwd().readFileAlloc(allocator, "inputs/day07.txt", 1024 * 10);
    defer allocator.free(input);

    const stdout = std.io.getStdOut().writer();
    try stdout.print("Part One: {}\n", .{try partOne(allocator, input)});
    try stdout.print("Part Two: {}\n", .{try partTwo(allocator, input)});
}

fn partOne(allocator: Allocator, input: []const u8) !usize {
    var puzzle = try Puzzle.init(allocator, input);
    defer puzzle.deinit();

    const comparator = struct {
        fn inner(context: void, lhs: Puzzle.Entry, rhs: Puzzle.Entry) bool {
            _ = context;
            const lhs_type = @intFromEnum(Type.buildPartOne(&lhs.hand));
            const rhs_type = @intFromEnum(Type.buildPartOne(&rhs.hand));

            if (lhs_type < rhs_type) {
                return true;
            }

            if (lhs_type > rhs_type) {
                return false;
            }

            for (0..5) |i| {
                const lhs_value = getCardValue(lhs.hand[i]);
                const rhs_value = getCardValue(rhs.hand[i]);
                if (lhs_value == rhs_value) {
                    continue;
                }
                return lhs_value < rhs_value;
            }

            unreachable; // At least in this puzzle.
        }
    }.inner;

    std.sort.heap(Puzzle.Entry, puzzle.entries.items, {}, comparator);

    var answer: usize = 0;
    for (puzzle.entries.items, 1..) |entry, rank| {
        answer += entry.bid * rank;
    }

    return answer;
}

fn partTwo(allocator: Allocator, input: []const u8) !usize {
    var puzzle = try Puzzle.init(allocator, input);
    defer puzzle.deinit();

    const comparator = struct {
        fn inner(context: void, lhs: Puzzle.Entry, rhs: Puzzle.Entry) bool {
            _ = context;
            const lhs_type = @intFromEnum(Type.buildPartTwo(&lhs.hand));
            const rhs_type = @intFromEnum(Type.buildPartTwo(&rhs.hand));

            if (lhs_type < rhs_type) {
                return true;
            }

            if (lhs_type > rhs_type) {
                return false;
            }

            for (0..5) |i| {
                const lhs_value = getCardValuePartTwo(lhs.hand[i]);
                const rhs_value = getCardValuePartTwo(rhs.hand[i]);
                if (lhs_value == rhs_value) {
                    continue;
                }
                return lhs_value < rhs_value;
            }

            std.debug.print("lhs: {s}\n", .{lhs.hand});
            std.debug.print("rhs: {s}\n", .{rhs.hand});
            unreachable; // At least in this puzzle.
        }
    }.inner;

    std.sort.heap(Puzzle.Entry, puzzle.entries.items, {}, comparator);

    var answer: usize = 0;
    for (puzzle.entries.items, 1..) |entry, rank| {
        answer += entry.bid * rank;
    }

    return answer;
}

const Puzzle = struct {
    const Entry = struct {
        hand: [5]u8,
        bid: usize,
    };

    entries: std.ArrayList(Entry),

    fn init(allocator: Allocator, input: []const u8) !Puzzle {
        var entries = std.ArrayList(Entry).init(allocator);
        errdefer entries.deinit();

        var line_iter = std.mem.tokenizeScalar(u8, input, '\n');
        while (line_iter.next()) |line| {
            const bid = try std.fmt.parseInt(usize, line[6..], 10);
            var entry = Entry{ .hand = undefined, .bid = bid };
            @memcpy(&entry.hand, line[0..5]);
            try entries.append(entry);
        }

        return .{
            .entries = entries,
        };
    }

    fn deinit(self: Puzzle) void {
        self.entries.deinit();
    }
};

const Type = enum {
    high_card,
    one_pair,
    two_pair,
    three_of_a_kind,
    full_house,
    four_of_a_kind,
    five_of_a_kind,

    fn buildPartOne(hand: *const [5]u8) Type {
        var buffer: [5]u8 = undefined;
        @memcpy(&buffer, hand);
        std.sort.heap(u8, &buffer, {}, std.sort.asc(u8));

        var last: u8 = buffer[0];
        var groups: usize = 1;
        var current_streak: usize = 1;
        var max_streak: usize = 1;
        for (buffer[1..]) |c| {
            if (last != c) {
                max_streak = @max(max_streak, current_streak);
                current_streak = 1;
                groups += 1;
            } else {
                current_streak += 1;
            }
            last = c;
        }
        max_streak = @max(max_streak, current_streak);

        return switch (groups) {
            1 => .five_of_a_kind,
            2 => if (max_streak == 4) .four_of_a_kind else .full_house,
            3 => if (max_streak == 3) .three_of_a_kind else .two_pair,
            4 => .one_pair,
            5 => .high_card,
            else => unreachable,
        };
    }

    fn buildPartTwo(hand: *const [5]u8) Type {
        var best = Type.high_card;

        var buffer: [5]u8 = undefined;
        for ("AKQT98765432") |replacement| {
            @memcpy(&buffer, hand);
            for (0..5) |i| {
                if (buffer[i] == 'J') {
                    buffer[i] = replacement;
                }
            }
            const current = Type.buildPartOne(&buffer);
            if (@intFromEnum(current) > @intFromEnum(best)) {
                best = current;
            }
        }

        return best;
    }
};

fn getCardValue(label: u8) u8 {
    return switch (label) {
        'A' => 14,
        'K' => 13,
        'Q' => 12,
        'J' => 11,
        'T' => 10,
        '2'...'9' => label - '0',
        else => unreachable,
    };
}

fn getCardValuePartTwo(label: u8) u8 {
    return switch (label) {
        'A' => 14,
        'K' => 13,
        'Q' => 12,
        'J' => 0,
        'T' => 10,
        '2'...'9' => label - '0',
        else => unreachable,
    };
}

test {
    const allocator = std.testing.allocator;
    const input =
        \\32T3K 765
        \\T55J5 684
        \\KK677 28
        \\KTJJT 220
        \\QQQJA 483
    ;

    try expectEqual(Type.five_of_a_kind, Type.buildPartOne("AAAAA"));
    try expectEqual(Type.four_of_a_kind, Type.buildPartOne("AA8AA"));
    try expectEqual(Type.full_house, Type.buildPartOne("23332"));
    try expectEqual(Type.three_of_a_kind, Type.buildPartOne("TTT98"));
    try expectEqual(Type.two_pair, Type.buildPartOne("23432"));
    try expectEqual(Type.one_pair, Type.buildPartOne("A23A4"));
    try expectEqual(Type.high_card, Type.buildPartOne("23456"));

    try expectEqual(@as(usize, 6440), try partOne(allocator, input));

    try expectEqual(Type.four_of_a_kind, Type.buildPartTwo("QJJQ2"));
    try expectEqual(Type.one_pair, Type.buildPartTwo("32T3K"));
    try expectEqual(Type.two_pair, Type.buildPartTwo("KK677"));
    try expectEqual(Type.four_of_a_kind, Type.buildPartTwo("T55J5"));
    try expectEqual(Type.four_of_a_kind, Type.buildPartTwo("KTJJT"));
    try expectEqual(Type.four_of_a_kind, Type.buildPartTwo("QQQJA"));

    try expectEqual(@as(usize, 5905), try partTwo(allocator, input));
}
