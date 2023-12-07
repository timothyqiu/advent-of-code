const std = @import("std");
const Allocator = std.mem.Allocator;
const expectEqual = std.testing.expectEqual;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const input = try std.fs.cwd().readFileAlloc(allocator, "inputs/day15.txt", 1024);
    defer allocator.free(input);

    const stdout = std.io.getStdOut().writer();
    try stdout.print("Part One: {}\n", .{try partOne(allocator, input)});
    try stdout.print("Part Two: {}\n", .{try partTwo(allocator, input)});
}

fn partOne(allocator: Allocator, input: []const u8) !usize {
    const puzzle = try Puzzle.init(allocator, input);
    defer puzzle.deinit();
    const ingredients_count = puzzle.ingredients.items.len;

    var amounts = std.ArrayList(usize).init(allocator);
    defer amounts.deinit();
    try amounts.resize(ingredients_count);
    @memset(amounts.items, 0);

    var max_score: usize = 0;

    while (true) {
        for (0..ingredients_count - 1) |i| {
            if (amounts.items[i] == 100) {
                amounts.items[i] = 1;
            } else {
                amounts.items[i] += 1;
                break;
            }
        } else break;

        var amount_total: usize = 0;
        for (amounts.items[0 .. ingredients_count - 1]) |amount| {
            amount_total += amount;
        }
        if (amount_total >= 100) {
            continue;
        }
        amounts.items[ingredients_count - 1] = 100 - amount_total;

        const score = puzzle.scoreCookie(amounts.items, null);

        if (score > max_score) {
            max_score = score;
        }
    }

    return max_score;
}

fn partTwo(allocator: Allocator, input: []const u8) !usize {
    const puzzle = try Puzzle.init(allocator, input);
    defer puzzle.deinit();
    const ingredients_count = puzzle.ingredients.items.len;

    var amounts = std.ArrayList(usize).init(allocator);
    defer amounts.deinit();
    try amounts.resize(ingredients_count);
    @memset(amounts.items, 0);

    var max_score: usize = 0;

    while (true) {
        for (0..ingredients_count - 1) |i| {
            if (amounts.items[i] == 100) {
                amounts.items[i] = 1;
            } else {
                amounts.items[i] += 1;
                break;
            }
        } else break;

        var amount_total: usize = 0;
        for (amounts.items[0 .. ingredients_count - 1]) |amount| {
            amount_total += amount;
        }
        if (amount_total >= 100) {
            continue;
        }
        amounts.items[ingredients_count - 1] = 100 - amount_total;

        const score = puzzle.scoreCookie(amounts.items, 500);

        if (score > max_score) {
            max_score = score;
        }
    }

    return max_score;
}

const Puzzle = struct {
    const Ingredient = struct {
        capacity: isize,
        durability: isize,
        flavor: isize,
        texture: isize,
        calories: isize,
    };

    ingredients: std.ArrayList(Ingredient),

    fn init(allocator: Allocator, input: []const u8) !Puzzle {
        var ingredients = std.ArrayList(Ingredient).init(allocator);
        errdefer ingredients.deinit();

        var line_iter = std.mem.tokenizeScalar(u8, input, '\n');
        while (line_iter.next()) |line| {
            var offset: usize = 0;
            try ingredients.append(.{
                .capacity = try getNextInt(line, &offset),
                .durability = try getNextInt(line, &offset),
                .flavor = try getNextInt(line, &offset),
                .texture = try getNextInt(line, &offset),
                .calories = try getNextInt(line, &offset),
            });
        }

        return .{
            .ingredients = ingredients,
        };
    }

    fn deinit(self: Puzzle) void {
        self.ingredients.deinit();
    }

    fn scoreCookie(self: Puzzle, amounts: []const usize, calories_limit: ?isize) usize {
        var capacity: isize = 0;
        var durability: isize = 0;
        var flavor: isize = 0;
        var texture: isize = 0;
        var calories: isize = 0;
        for (self.ingredients.items, 0..) |ingredient, i| {
            const amount: isize = @intCast(amounts[i]);
            capacity += ingredient.capacity * amount;
            durability += ingredient.durability * amount;
            flavor += ingredient.flavor * amount;
            texture += ingredient.texture * amount;
            calories += ingredient.calories * amount;
        }

        if (calories_limit) |limit| {
            if (calories != limit) {
                return 0;
            }
        }

        return @max(0, capacity) * @max(0, durability) * @max(0, flavor) * @max(0, texture);
    }
};

fn getNextInt(input: []const u8, offset: *usize) !isize {
    const VALID_CHARS = "-9876543210";
    const start = std.mem.indexOfAnyPos(u8, input, offset.*, VALID_CHARS) orelse return error.InvalidInput;
    const end = std.mem.indexOfNonePos(u8, input, start + 1, VALID_CHARS) orelse input.len;
    offset.* = end;
    return try std.fmt.parseInt(isize, input[start..end], 10);
}

test {
    const allocator = std.testing.allocator;
    const input =
        \\Butterscotch: capacity -1, durability -2, flavor 6, texture 3, calories 8
        \\Cinnamon: capacity 2, durability 3, flavor -2, texture -1, calories 3
    ;

    try expectEqual(@as(usize, 62842880), try partOne(allocator, input));
    try expectEqual(@as(usize, 57600000), try partTwo(allocator, input));
}
