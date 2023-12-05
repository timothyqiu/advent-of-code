const std = @import("std");
const Allocator = std.mem.Allocator;
const expectEqual = std.testing.expectEqual;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const arena_allocator = arena.allocator();

    const content = try std.fs.cwd().readFileAlloc(arena_allocator, "inputs/day07.txt", 10240);
    defer arena_allocator.free(content);

    var connections = try buildConnectionMap(arena_allocator, content);
    defer connections.deinit();

    const part_one = try getCircuit(arena_allocator, connections, "a");

    try connections.put("b", .{
        .operands = [2]Operand{
            .{ .signal = part_one },
            undefined,
        },
        .operands_count = 1,
        .operator = .identity,
    });

    const part_two = try getCircuit(arena_allocator, connections, "a");

    const stdout = std.io.getStdOut().writer();
    try stdout.print("Part One: {}\n", .{part_one});
    try stdout.print("Part Two: {}\n", .{part_two});
}

const Operator = enum {
    identity,
    bit_not,
    bit_and,
    bit_or,
    shift_left,
    shift_right,
};

const Operand = union(enum) {
    signal: u16,
    wire: []const u8,
};

const Connection = struct {
    operands: [2]Operand,
    operands_count: usize,
    operator: Operator,
};

const ConnectionMap = std.StringHashMap(Connection);

fn buildConnectionMap(allocator: Allocator, input: []const u8) !ConnectionMap {
    var map = std.StringHashMap(Connection).init(allocator);
    errdefer map.deinit();

    var line_iter = std.mem.tokenizeScalar(u8, input, '\n');
    while (line_iter.next()) |line| {
        var operands: [2]Operand = undefined;
        var operands_count: usize = 0;
        var operator = Operator.identity;

        var iter = std.mem.tokenizeScalar(u8, line, ' ');
        while (iter.next()) |raw| {
            switch (raw[0]) {
                '0'...'9' => {
                    std.debug.assert(operands_count < 2);
                    operands[operands_count] = .{ .signal = try std.fmt.parseInt(u16, raw, 10) };
                    operands_count += 1;
                },

                'a'...'z' => {
                    std.debug.assert(operands_count < 2);
                    operands[operands_count] = .{ .wire = raw };
                    operands_count += 1;
                },

                'N' => operator = .bit_not,
                'A' => operator = .bit_and,
                'O' => operator = .bit_or,
                'L' => operator = .shift_left,
                'R' => operator = .shift_right,

                '-' => {
                    try map.put(iter.next().?, .{
                        .operands = operands,
                        .operands_count = operands_count,
                        .operator = operator,
                    });
                },

                else => unreachable,
            }
        }
    }

    return map;
}

fn getCircuit(allocator: Allocator, connections: ConnectionMap, wire: []const u8) !u16 {
    var signals = std.StringHashMap(u16).init(allocator);
    defer signals.deinit();

    while (!signals.contains(wire)) {
        var iter = connections.iterator();
        iteration: while (iter.next()) |entry| {
            const conn = entry.value_ptr.*;

            var operands: [2]u16 = undefined;
            for (0..conn.operands_count) |i| {
                const op = conn.operands[i];
                if (op != .signal and !signals.contains(op.wire)) {
                    continue :iteration;
                }
                operands[i] = switch (op) {
                    .signal => op.signal,
                    .wire => signals.get(op.wire).?,
                };
            }

            try signals.put(entry.key_ptr.*, switch (conn.operator) {
                .identity => operands[0],
                .bit_not => ~operands[0],
                .bit_and => operands[0] & operands[1],
                .bit_or => operands[0] | operands[1],
                .shift_left => operands[0] << @intCast(operands[1]),
                .shift_right => operands[0] >> @intCast(operands[1]),
            });
        }
    }

    return signals.get(wire).?;
}

test {
    const allocator = std.testing.allocator;

    const content = try std.fs.cwd().readFileAlloc(allocator, "tests/day07.txt", 10240);
    defer allocator.free(content);

    var connections = try buildConnectionMap(allocator, content);
    defer connections.deinit();

    try expectEqual(@as(u16, 65079), try getCircuit(allocator, connections, "i"));
}
