const std = @import("std");
const utils = @import("utils.zig");
const prng = std.rand.DefaultPrng;
const assert = std.debug.assert;
const testing = std.testing;

var rng: std.rand.DefaultPrng = undefined;

pub fn init(seed: u64) void {
    rng = std.rand.DefaultPrng.init(seed);
}

pub fn choose(comptime T: type, items: []const T) T {
    assert(items.len > 0);
    const index = rng.random().intRangeLessThan(usize, 0, items.len);
    return items[index];
}

test "choose" {
    init(0x123);
    const items = [_]u8{ 0, 1, 2, 3, 4 };
    try testing.expectEqual(choose(u8, &items), 4);
    try testing.expectEqual(choose(u8, &items), 3);
    try testing.expectEqual(choose(u8, &items), 0);
    try testing.expectEqual(choose(u8, &items), 1);
}

pub fn WeightedChanceMap(comptime T: type) type {
    return std.AutoHashMap(T, usize);
}

pub fn chooseWeighted(comptime T: type, chances: *WeightedChanceMap(T)) T {
    var total_weight: usize = 0;

    var weights_iter = chances.valueIterator();
    while (weights_iter.next()) |weight| total_weight += weight.*;

    var random_weight = rng.random().intRangeLessThan(usize, 0, total_weight);
    var iter = chances.iterator();

    while (iter.next()) |entry| {
        const weight = entry.value_ptr.*;
        const item = entry.key_ptr.*;
        if (weight > random_weight) return item;
        random_weight -= weight;
    }

    unreachable;
}

test "chooseWeighted" {
    init(0x123);
    var weights = WeightedChanceMap(u8).init(testing.allocator);
    defer weights.deinit();
    try weights.put(0, 10);
    try weights.put(1, 20);
    try weights.put(2, 50);
    try testing.expectEqual(chooseWeighted(u8, &weights), 2);
    try testing.expectEqual(chooseWeighted(u8, &weights), 2);
    try testing.expectEqual(chooseWeighted(u8, &weights), 1);
    try testing.expectEqual(chooseWeighted(u8, &weights), 1);
    try testing.expectEqual(chooseWeighted(u8, &weights), 2);
}
