const std = @import("std");
const Allocator = std.mem.Allocator;
const expectEqual = std.testing.expectEqual;

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const stdout = std.io.getStdOut().writer();

    const input = try std.fs.cwd().readFileAlloc(allocator, "inputs/day03.txt", 40960);
    defer allocator.free(input);

    try stdout.print("Part One: {}\n", .{try partOne(allocator, input)});
    try stdout.print("Part Two: {}\n", .{try partTwo(allocator, input)});
}

const NumberRect = struct {
    number: usize,
    src: usize,
    dst: usize,
};
const SymbolPoint = struct {
    column: usize,
};

fn partOne(allocator: Allocator, input: []const u8) !usize {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const arena_allocator = arena.allocator();

    var numbers = std.ArrayList(std.ArrayList(NumberRect)).init(arena_allocator);
    var symbols = std.ArrayList(std.ArrayList(SymbolPoint)).init(arena_allocator);

    var line_iter = std.mem.tokenizeScalar(u8, input, '\n');
    while (line_iter.next()) |line| {
        try numbers.append(std.ArrayList(NumberRect).init(arena_allocator));
        try symbols.append(std.ArrayList(SymbolPoint).init(arena_allocator));

        var row_numbers = &numbers.items[numbers.items.len - 1];
        var row_symbols = &symbols.items[symbols.items.len - 1];

        var i: usize = 0;
        while (i < line.len) {
            switch (line[i]) {
                '.' => i += 1,

                '0'...'9' => {
                    const end = std.mem.indexOfNonePos(u8, line, i, "0123456789") orelse line.len;
                    const number = try std.fmt.parseInt(usize, line[i..end], 10);

                    try row_numbers.append(.{
                        .number = number,
                        .src = i,
                        .dst = end,
                    });

                    i = end;
                },

                else => {
                    try row_symbols.append(.{
                        .column = i,
                    });

                    i += 1;
                },
            }
        }
    }

    var sum: usize = 0;

    for (0..numbers.items.len) |line| {
        n: for (numbers.items[line].items) |number| {
            const lhs = if (number.src == 0) number.src else number.src - 1;
            const rhs = number.dst;
            if (line > 0) {
                for (symbols.items[line - 1].items) |symbol| {
                    if (lhs <= symbol.column and symbol.column <= rhs) {
                        sum += number.number;
                        continue :n;
                    }
                }
            }
            for (symbols.items[line].items) |symbol| {
                if (lhs == symbol.column or symbol.column == rhs) {
                    sum += number.number;
                    continue :n;
                }
            }
            if (line + 1 < numbers.items.len) {
                for (symbols.items[line + 1].items) |symbol| {
                    if (lhs <= symbol.column and symbol.column <= rhs) {
                        sum += number.number;
                        continue :n;
                    }
                }
            }
        }
    }

    return sum;
}

fn partTwo(allocator: Allocator, input: []const u8) !usize {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const arena_allocator = arena.allocator();

    var numbers = std.ArrayList(std.ArrayList(NumberRect)).init(arena_allocator);
    var symbols = std.ArrayList(std.ArrayList(SymbolPoint)).init(arena_allocator);

    var line_iter = std.mem.tokenizeScalar(u8, input, '\n');
    while (line_iter.next()) |line| {
        try numbers.append(std.ArrayList(NumberRect).init(arena_allocator));
        try symbols.append(std.ArrayList(SymbolPoint).init(arena_allocator));

        var row_numbers = &numbers.items[numbers.items.len - 1];
        var row_symbols = &symbols.items[symbols.items.len - 1];

        var i: usize = 0;
        while (i < line.len) {
            switch (line[i]) {
                '*' => {
                    try row_symbols.append(.{ .column = i });
                    i += 1;
                },

                '0'...'9' => {
                    const end = std.mem.indexOfNonePos(u8, line, i, "0123456789") orelse line.len;
                    const number = try std.fmt.parseInt(usize, line[i..end], 10);

                    try row_numbers.append(.{
                        .number = number,
                        .src = i,
                        .dst = end,
                    });

                    i = end;
                },

                else => i += 1,
            }
        }
    }

    var sum: usize = 0;

    for (0..symbols.items.len) |line| {
        n: for (symbols.items[line].items) |symbol| {
            var adjacent: [2]usize = undefined;
            var adjacent_count: usize = 0;

            if (line > 0) {
                for (numbers.items[line - 1].items) |number| {
                    const lhs = if (number.src == 0) number.src else number.src - 1;
                    const rhs = number.dst;
                    if (lhs <= symbol.column and symbol.column <= rhs) {
                        if (adjacent_count == 2) {
                            continue :n;
                        }
                        adjacent[adjacent_count] = number.number;
                        adjacent_count += 1;
                    }
                }
            }

            for (numbers.items[line].items) |number| {
                const lhs = if (number.src == 0) number.src else number.src - 1;
                const rhs = number.dst;
                if (lhs == symbol.column or symbol.column == rhs) {
                    if (adjacent_count == 2) {
                        continue :n;
                    }
                    adjacent[adjacent_count] = number.number;
                    adjacent_count += 1;
                }
            }

            if (line + 1 < numbers.items.len) {
                for (numbers.items[line + 1].items) |number| {
                    const lhs = if (number.src == 0) number.src else number.src - 1;
                    const rhs = number.dst;
                    if (lhs <= symbol.column and symbol.column <= rhs) {
                        if (adjacent_count == 2) {
                            continue :n;
                        }
                        adjacent[adjacent_count] = number.number;
                        adjacent_count += 1;
                    }
                }
            }

            if (adjacent_count == 2) {
                sum += adjacent[0] * adjacent[1];
            }
        }
    }

    return sum;
}

test {
    const allocator = std.testing.allocator;
    const input =
        \\467..114..
        \\...*......
        \\..35..633.
        \\......#...
        \\617*......
        \\.....+.58.
        \\..592.....
        \\......755.
        \\...$.*....
        \\.664.598..
    ;
    try expectEqual(@as(usize, 4361), try partOne(allocator, input));
    try expectEqual(@as(usize, 467835), try partTwo(allocator, input));
}
