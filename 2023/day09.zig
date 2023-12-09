const std = @import("std");
const Allocator = std.mem.Allocator;
const expectEqual = std.testing.expectEqual;

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const input = try std.fs.cwd().readFileAlloc(allocator, "inputs/day09.txt", 1024 * 22);
    defer allocator.free(input);

    const stdout = std.io.getStdOut().writer();
    try stdout.print("Part One: {}\n", .{try partOne(allocator, input)});
    try stdout.print("Part Two: {}\n", .{try partTwo(allocator, input)});
}

fn partOne(allocator: Allocator, input: []const u8) !isize {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const arena_allocator = arena.allocator();

    var sum: isize = 0;

    var line_iter = std.mem.tokenizeScalar(u8, input, '\n');
    while (line_iter.next()) |line| {
        var seqs = std.ArrayList(std.ArrayList(isize)).init(arena_allocator);

        try seqs.append(std.ArrayList(isize).init(arena_allocator));
        var input_seq = &seqs.items[0];

        var number_iter = std.mem.tokenizeScalar(u8, line, ' ');
        while (number_iter.next()) |token| {
            const number = try std.fmt.parseInt(isize, token, 10);
            try input_seq.append(number);
        }

        while (true) {
            try seqs.append(std.ArrayList(isize).init(arena_allocator));
            var next_seq = &seqs.items[seqs.items.len - 1];
            const last_seq = &seqs.items[seqs.items.len - 2];

            var all_zeros = true;
            var last_number = last_seq.items[0];
            for (last_seq.items[1..]) |number| {
                const combined = number - last_number;
                try next_seq.append(combined);
                last_number = number;
                all_zeros = all_zeros and combined == 0;
            }

            if (all_zeros) {
                break;
            }
        }

        var answer: isize = 0;
        var rev_iter = std.mem.reverseIterator(seqs.items);
        while (rev_iter.next()) |seq| {
            const last = seq.items[seq.items.len - 1];
            answer += last;
        }

        sum += answer;
    }

    return sum;
}

fn partTwo(allocator: Allocator, input: []const u8) !isize {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const arena_allocator = arena.allocator();

    var sum: isize = 0;

    var line_iter = std.mem.tokenizeScalar(u8, input, '\n');
    while (line_iter.next()) |line| {
        var seqs = std.ArrayList(std.ArrayList(isize)).init(arena_allocator);

        try seqs.append(std.ArrayList(isize).init(arena_allocator));
        var input_seq = &seqs.items[0];

        var number_iter = std.mem.tokenizeScalar(u8, line, ' ');
        while (number_iter.next()) |token| {
            const number = try std.fmt.parseInt(isize, token, 10);
            try input_seq.append(number);
        }

        while (true) {
            try seqs.append(std.ArrayList(isize).init(arena_allocator));
            var next_seq = &seqs.items[seqs.items.len - 1];
            const last_seq = &seqs.items[seqs.items.len - 2];

            var all_zeros = true;
            var last_number = last_seq.items[0];
            for (last_seq.items[1..]) |number| {
                const combined = number - last_number;
                try next_seq.append(combined);
                last_number = number;
                all_zeros = all_zeros and combined == 0;
            }

            if (all_zeros) {
                break;
            }
        }

        var answer: isize = 0;
        var rev_iter = std.mem.reverseIterator(seqs.items);
        while (rev_iter.next()) |seq| {
            const first = seq.items[0];
            answer = first - answer;
        }

        sum += answer;
    }

    return sum;
}

test {
    const allocator = std.testing.allocator;
    const input =
        \\0 3 6 9 12 15
        \\1 3 6 10 15 21
        \\10 13 16 21 30 45
    ;

    try expectEqual(@as(isize, 114), try partOne(allocator, input));
    try expectEqual(@as(isize, 2), try partTwo(allocator, input));
}
