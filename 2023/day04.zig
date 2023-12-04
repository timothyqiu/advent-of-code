const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    try stdout.print("Part One: {}\n", .{try partOne(std.heap.page_allocator, "inputs/day04.txt")});
    try stdout.print("Part Two: {}\n", .{try partTwo(std.heap.page_allocator, "inputs/day04.txt")});
}

fn partOne(allocator: Allocator, path: []const u8) !usize {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const arena_allocator = arena.allocator();

    const input = try std.fs.cwd().openFile(path, .{});
    defer input.close();

    var sum: usize = 0;

    var buffer: [256]u8 = undefined;
    while (try input.reader().readUntilDelimiterOrEof(&buffer, '\n')) |line| {
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

fn partTwo(allocator: Allocator, path: []const u8) !usize {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const arena_allocator = arena.allocator();

    const input = try std.fs.cwd().openFile(path, .{});
    defer input.close();

    var copies = std.AutoHashMap(u32, usize).init(arena_allocator);
    defer copies.deinit();

    var buffer: [256]u8 = undefined;
    while (try input.reader().readUntilDelimiterOrEof(&buffer, '\n')) |line| {
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

test "part one" {
    try std.testing.expectEqual(@as(usize, 13), try partOne(std.testing.allocator, "tests/day04.txt"));
}

test "part two" {
    try std.testing.expectEqual(@as(usize, 30), try partTwo(std.testing.allocator, "tests/day04.txt"));
}
