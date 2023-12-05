const std = @import("std");
const Allocator = std.mem.Allocator;
const expectEqual = std.testing.expectEqual;

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const stdout = std.io.getStdOut().writer();

    const input = try std.fs.cwd().readFileAlloc(allocator, "inputs/day04.txt", 40960);
    defer allocator.free(input);

    try stdout.print("Part One: {}\n", .{try partOne(std.heap.page_allocator, input)});
    try stdout.print("Part Two: {}\n", .{try partTwo(std.heap.page_allocator, input)});
}

fn partOne(allocator: Allocator, input: []const u8) !usize {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const arena_allocator = arena.allocator();

    var sum: usize = 0;

    var line_iter = std.mem.tokenizeScalar(u8, input, '\n');
    while (line_iter.next()) |line| {
        std.debug.assert(std.mem.startsWith(u8, line, "Card "));
        const winning_from = std.mem.indexOfScalarPos(u8, line, 5, ':').? + 1;
        const numbers_from = std.mem.indexOfScalarPos(u8, line, winning_from, '|').? + 1;

        var winning_numbers = std.AutoHashMap(u32, void).init(arena_allocator);
        defer winning_numbers.deinit();

        var winning_iter = std.mem.tokenizeScalar(u8, line[winning_from .. numbers_from - 1], ' ');
        while (winning_iter.next()) |token| {
            const number = try std.fmt.parseInt(u32, token, 10);
            try winning_numbers.put(number, {});
        }

        var matching: usize = 0;
        var numbers_iter = std.mem.tokenizeScalar(u8, line[numbers_from..], ' ');
        while (numbers_iter.next()) |token| {
            const number = try std.fmt.parseInt(u32, token, 10);
            if (winning_numbers.contains(number)) {
                matching += 1;
            }
        }

        if (matching > 0) {
            sum += try std.math.powi(usize, 2, matching - 1);
        }
    }

    return sum;
}

fn partTwo(allocator: Allocator, input: []const u8) !usize {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const arena_allocator = arena.allocator();

    var copies = std.AutoHashMap(u32, usize).init(arena_allocator);
    defer copies.deinit();

    var line_iter = std.mem.tokenizeScalar(u8, input, '\n');
    while (line_iter.next()) |line| {
        std.debug.assert(std.mem.startsWith(u8, line, "Card "));
        const id_from = std.mem.indexOfNonePos(u8, line, 5, " ").?;
        const winning_from = std.mem.indexOfScalarPos(u8, line, id_from, ':').? + 1;
        const numbers_from = std.mem.indexOfScalarPos(u8, line, winning_from, '|').? + 1;

        const id = try std.fmt.parseInt(u32, line[id_from .. winning_from - 1], 10);

        var winning_numbers = std.AutoHashMap(u32, void).init(arena_allocator);
        defer winning_numbers.deinit();

        var winning_iter = std.mem.tokenizeScalar(u8, line[winning_from .. numbers_from - 1], ' ');
        while (winning_iter.next()) |token| {
            const number = try std.fmt.parseInt(u32, token, 10);
            try winning_numbers.put(number, {});
        }

        var matching: usize = 0;
        var numbers_iter = std.mem.tokenizeScalar(u8, line[numbers_from..], ' ');
        while (numbers_iter.next()) |token| {
            const number = try std.fmt.parseInt(u32, token, 10);
            if (winning_numbers.contains(number)) {
                matching += 1;
            }
        }

        const current_copies = (try copies.getOrPutValue(id, 1)).value_ptr.*;
        for (0..matching) |i| {
            const card_id = id + 1 + @as(u32, @intCast(i));
            try copies.put(card_id, (try copies.getOrPutValue(card_id, 1)).value_ptr.* + current_copies);
        }
    }

    var sum: usize = 0;
    var iter = copies.valueIterator();
    while (iter.next()) |value| {
        sum += value.*;
    }

    return sum;
}

test {
    const input =
        \\Card 1: 41 48 83 86 17 | 83 86  6 31 17  9 48 53
        \\Card 2: 13 32 20 16 61 | 61 30 68 82 17 32 24 19
        \\Card 3:  1 21 53 59 44 | 69 82 63 72 16 21 14  1
        \\Card 4: 41 92 73 84 69 | 59 84 76 51 58  5 54 83
        \\Card 5: 87 83 26 28 32 | 88 30 70 12 93 22 82 36
        \\Card 6: 31 18 13 56 72 | 74 77 10 23 35 67 36 11
    ;
    try expectEqual(@as(usize, 13), try partOne(std.testing.allocator, input));
    try expectEqual(@as(usize, 30), try partTwo(std.testing.allocator, input));
}
