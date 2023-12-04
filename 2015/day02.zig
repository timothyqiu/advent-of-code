const std = @import("std");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    try stdout.print("Part One: {}\n", .{try partOne("inputs/day02.txt")});
    try stdout.print("Part Two: {}\n", .{try partTwo("inputs/day02.txt")});
}

fn partOne(path: []const u8) !usize {
    const input = try std.fs.cwd().openFile(path, .{});
    defer input.close();

    var sum: usize = 0;

    var buffer: [256]u8 = undefined;
    while (try input.reader().readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        sum += try getWrappingPaperArea(line);
    }

    return sum;
}

fn partTwo(path: []const u8) !usize {
    const input = try std.fs.cwd().openFile(path, .{});
    defer input.close();

    var sum: usize = 0;

    var buffer: [256]u8 = undefined;
    while (try input.reader().readUntilDelimiterOrEof(&buffer, '\n')) |line| {
        sum += try getRibbonLength(line);
    }

    return sum;
}

fn getWrappingPaperArea(input: []const u8) !usize {
    var iter = std.mem.tokenizeScalar(u8, input, 'x');

    const l = try std.fmt.parseInt(usize, iter.next().?, 10);
    const w = try std.fmt.parseInt(usize, iter.next().?, 10);
    const h = try std.fmt.parseInt(usize, iter.next().?, 10);
    std.debug.assert(iter.next() == null);

    const a = l * w;
    const b = w * h;
    const c = h * l;

    return 2 * (a + b + c) + @min(a, @min(b, c));
}

fn getRibbonLength(input: []const u8) !usize {
    var iter = std.mem.tokenizeScalar(u8, input, 'x');

    const l = try std.fmt.parseInt(usize, iter.next().?, 10);
    const w = try std.fmt.parseInt(usize, iter.next().?, 10);
    const h = try std.fmt.parseInt(usize, iter.next().?, 10);
    std.debug.assert(iter.next() == null);

    var sides: [2]usize = undefined;
    if (l > w) {
        sides[0] = w;
        sides[1] = @min(h, l);
    } else {
        sides[0] = l;
        sides[1] = @min(h, w);
    }

    return 2 * (sides[0] + sides[1]) + l * w * h;
}

test "part one" {
    try std.testing.expectEqual(@as(usize, 58), try getWrappingPaperArea("2x3x4"));
    try std.testing.expectEqual(@as(usize, 43), try getWrappingPaperArea("1x1x10"));
}

test "part two" {
    try std.testing.expectEqual(@as(usize, 34), try getRibbonLength("2x3x4"));
    try std.testing.expectEqual(@as(usize, 14), try getRibbonLength("1x1x10"));
}
