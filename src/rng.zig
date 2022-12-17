const std = @import("std");
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

test "choice" {
    init(0x123);
    const items = [_]u8{ 0, 1, 2, 3, 4 };
    try testing.expectEqual(choose(u8, &items), 4);
    try testing.expectEqual(choose(u8, &items), 3);
    try testing.expectEqual(choose(u8, &items), 0);
    try testing.expectEqual(choose(u8, &items), 1);
}
