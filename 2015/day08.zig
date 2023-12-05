const std = @import("std");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const content = try std.fs.cwd().readFileAlloc(allocator, "inputs/day08.txt", 10240);
    defer allocator.free(content);

    const stdout = std.io.getStdOut().writer();
    try stdout.print("Part One: {}\n", .{try partOne(content)});
    try stdout.print("Part Two: {}\n", .{try partTwo(content)});
}

fn partOne(input: []const u8) !usize {
    var total_code_len: usize = 0;
    var total_mem_len: usize = 0;

    var iter = std.mem.tokenizeScalar(u8, input, '\n');
    while (iter.next()) |line| {
        std.debug.assert(line.len >= 2);
        std.debug.assert(line[0] == '"');
        std.debug.assert(line[line.len - 1] == '"');

        var code_len: usize = 2; // Quotes
        var mem_len: usize = 0;

        var i: usize = 1;
        while (i < line.len - 1) {
            switch (line[i]) {
                '\\' => {
                    std.debug.assert(i + 1 < line.len - 1);
                    switch (line[i + 1]) {
                        '\\', '"' => {
                            code_len += 2;
                            mem_len += 1;
                            i += 2;
                        },
                        'x' => {
                            std.debug.assert(i + 3 < line.len - 1);
                            code_len += 4;
                            mem_len += 1;
                            i += 4;
                        },
                        else => unreachable,
                    }
                },

                else => {
                    code_len += 1;
                    mem_len += 1;
                    i += 1;
                },
            }
        }

        total_code_len += code_len;
        total_mem_len += mem_len;
    }

    return total_code_len - total_mem_len;
}

fn partTwo(input: []const u8) !usize {
    var total_diff: usize = 0;

    var iter = std.mem.tokenizeScalar(u8, input, '\n');
    while (iter.next()) |line| {
        var diff: usize = 2; // Quotes

        for (line) |c| {
            switch (c) {
                '\\', '"' => diff += 1,
                else => {},
            }
        }

        total_diff += diff;
    }

    return total_diff;
}

test {
    const content =
        \\""
        \\"abc"
        \\"aaa\"aaa"
        \\"\x27"
    ;

    try std.testing.expectEqual(@as(usize, 12), try partOne(content));
    try std.testing.expectEqual(@as(usize, 19), try partTwo(content));
}
