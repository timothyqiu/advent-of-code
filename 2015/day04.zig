const std = @import("std");
const Md5 = std.crypto.hash.Md5;

pub fn main() !void {
    const input = "yzbqklnj";
    const stdout = std.io.getStdOut().writer();

    try stdout.print("Part One: {}\n", .{try mineAdventCoin(input, 5)});
    try stdout.print("Part Two: {}\n", .{try mineAdventCoin(input, 6)});
}

fn mineAdventCoin(secret_key: []const u8, leading_zeros: usize) !usize {
    var hash: [Md5.digest_length]u8 = undefined;
    var hex: [Md5.digest_length * 2]u8 = undefined;
    var buffer: [256]u8 = undefined;

    var coin: usize = 1;
    while (true) : (coin += 1) {
        const input = try std.fmt.bufPrint(&buffer, "{s}{}", .{ secret_key, coin });
        Md5.hash(input, &hash, .{});

        for (hash, 0..) |byte, i| {
            _ = try std.fmt.bufPrint(hex[2 * i .. 2 * i + 2], "{x:0>2}", .{byte});
        }

        const count = std.mem.indexOfNone(u8, &hex, "0") orelse hex.len;
        if (count >= leading_zeros) {
            return coin;
        }
    }
}

test {
    try std.testing.expectEqual(@as(usize, 609043), try mineAdventCoin("abcdef", 5));
    try std.testing.expectEqual(@as(usize, 1048970), try mineAdventCoin("pqrstuv", 5));
}
