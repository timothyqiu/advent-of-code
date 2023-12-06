const std = @import("std");
const Allocator = std.mem.Allocator;
const expectEqual = std.testing.expectEqual;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const content = try std.fs.cwd().readFileAlloc(allocator, "inputs/day12.txt", 28 * 1024);
    defer allocator.free(content);

    const stdout = std.io.getStdOut().writer();
    try stdout.print("Part One: {}\n", .{try partOne(allocator, content)});
    try stdout.print("Part Two: {}\n", .{try partTwo(allocator, content)});
}

fn partOne(allocator: Allocator, input: []const u8) !isize {
    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, input, .{});
    defer parsed.deinit();

    return sumNumbers(parsed.value);
}

fn partTwo(allocator: Allocator, input: []const u8) !isize {
    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, input, .{});
    defer parsed.deinit();

    return sumNonRedNumbers(parsed.value);
}

fn sumNumbers(value: std.json.Value) isize {
    switch (value) {
        .integer => return value.integer,
        .array => {
            var sum: isize = 0;
            for (value.array.items) |item| {
                sum += sumNumbers(item);
            }
            return sum;
        },
        .object => {
            var sum: isize = 0;
            for (value.object.values()) |item| {
                sum += sumNumbers(item);
            }
            return sum;
        },
        .string => return 0,
        else => unreachable,
    }
}

fn sumNonRedNumbers(value: std.json.Value) isize {
    switch (value) {
        .integer => return value.integer,
        .array => {
            var sum: isize = 0;
            for (value.array.items) |item| {
                sum += sumNonRedNumbers(item);
            }
            return sum;
        },
        .object => {
            var sum: isize = 0;
            for (value.object.values()) |item| {
                if (item == .string and std.mem.eql(u8, item.string, "red")) {
                    return 0;
                }
                sum += sumNonRedNumbers(item);
            }
            return sum;
        },
        .string => return 0,
        else => unreachable,
    }
}

test {
    const allocator = std.testing.allocator;

    try expectEqual(@as(isize, 6), try partOne(allocator, "[1,2,3]"));
    try expectEqual(@as(isize, 6), try partOne(allocator,
        \\{"a":2,"b":4}
    ));
    try expectEqual(@as(isize, 3), try partOne(allocator, "[[[3]]]"));
    try expectEqual(@as(isize, 3), try partOne(allocator,
        \\{"a":{"b":4},"c":-1}
    ));
    try expectEqual(@as(isize, 0), try partOne(allocator,
        \\{"a":[-1,1]}
    ));
    try expectEqual(@as(isize, 0), try partOne(allocator,
        \\[-1,{"a":1}]
    ));
    try expectEqual(@as(isize, 0), try partOne(allocator, "[]"));
    try expectEqual(@as(isize, 0), try partOne(allocator, "{}"));

    try expectEqual(@as(isize, 6), try partTwo(allocator, "[1,2,3]"));
    try expectEqual(@as(isize, 4), try partTwo(allocator,
        \\[1,{"c":"red","b":2},3]
    ));
    try expectEqual(@as(isize, 0), try partTwo(allocator,
        \\{"d":"red","e":[1,2,3,4],"f":5}
    ));
    try expectEqual(@as(isize, 6), try partTwo(allocator,
        \\[1,"red",5]
    ));
}
