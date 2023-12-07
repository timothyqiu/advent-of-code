const std = @import("std");
const Allocator = std.mem.Allocator;
const expectEqual = std.testing.expectEqual;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const input = try std.fs.cwd().readFileAlloc(allocator, "inputs/day16.txt", 1024 * 23);
    defer allocator.free(input);

    const stdout = std.io.getStdOut().writer();
    try stdout.print("Part One: {}\n", .{try partOne(allocator, input)});
    try stdout.print("Part Two: {}\n", .{try partTwo(allocator, input)});
}

fn partOne(allocator: Allocator, input: []const u8) !usize {
    const puzzle = try Puzzle.init(allocator, input);
    defer puzzle.deinit();

    for (puzzle.sues.items, 1..) |sue, i| {
        if (sue.matches()) {
            return i;
        }
    }

    unreachable;
}

fn partTwo(allocator: Allocator, input: []const u8) !usize {
    const puzzle = try Puzzle.init(allocator, input);
    defer puzzle.deinit();

    for (puzzle.sues.items, 1..) |sue, i| {
        if (sue.matches_alt()) {
            return i;
        }
    }

    unreachable;
}

const Puzzle = struct {
    const Sue = struct {
        children: ?usize = null,
        cats: ?usize = null,
        samoyeds: ?usize = null,
        pomeranians: ?usize = null,
        akitas: ?usize = null,
        vizslas: ?usize = null,
        goldfish: ?usize = null,
        trees: ?usize = null,
        cars: ?usize = null,
        perfumes: ?usize = null,

        fn matches(self: Sue) bool {
            inline for (@typeInfo(Sue).Struct.fields) |field| {
                if (@field(self, field.name)) |expect| {
                    if (expect != @field(FACT, field.name).?) {
                        return false;
                    }
                }
            }
            return true;
        }

        fn matches_alt(self: Sue) bool {
            inline for (@typeInfo(Sue).Struct.fields) |field| {
                if (std.mem.eql(u8, field.name, "cats") or std.mem.eql(u8, field.name, "trees")) {
                    if (@field(self, field.name)) |expect| {
                        if (expect <= @field(FACT, field.name).?) {
                            return false;
                        }
                    }
                } else if (std.mem.eql(u8, field.name, "pomeranians") or std.mem.eql(u8, field.name, "goldfish")) {
                    if (@field(self, field.name)) |expect| {
                        if (expect >= @field(FACT, field.name).?) {
                            return false;
                        }
                    }
                } else {
                    if (@field(self, field.name)) |expect| {
                        if (expect != @field(FACT, field.name).?) {
                            return false;
                        }
                    }
                }
            }
            return true;
        }
    };

    const FACT = Puzzle.Sue{
        .children = 3,
        .cats = 7,
        .samoyeds = 2,
        .pomeranians = 3,
        .akitas = 0,
        .vizslas = 0,
        .goldfish = 5,
        .trees = 3,
        .cars = 2,
        .perfumes = 1,
    };

    sues: std.ArrayList(Sue),

    fn init(allocator: Allocator, input: []const u8) !Puzzle {
        var sues = std.ArrayList(Sue).init(allocator);
        errdefer sues.deinit();

        var line_iter = std.mem.tokenizeScalar(u8, input, '\n');
        while (line_iter.next()) |line| {
            const list_start = std.mem.indexOfScalar(u8, line, ':').? + 2;
            var item_iter = std.mem.tokenizeSequence(u8, line[list_start..], ", ");

            var sue = Sue{};

            while (item_iter.next()) |spec| {
                const property_end = std.mem.indexOfScalar(u8, spec, ':').?;
                const name = spec[0..property_end];
                const value = try std.fmt.parseInt(usize, spec[property_end + 2 ..], 10);

                inline for (@typeInfo(Sue).Struct.fields) |field| {
                    if (std.mem.eql(u8, field.name, name)) {
                        @field(sue, field.name) = value;
                        break;
                    }
                }
            }

            try sues.append(sue);
        }

        return .{
            .sues = sues,
        };
    }

    fn deinit(self: Puzzle) void {
        self.sues.deinit();
    }
};
