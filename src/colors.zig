const std = @import("std");
const testing = std.testing;

pub fn rgb(comptime r: u8, comptime g: u8, comptime b: u8) i32 {
    return @intCast(i32, @as(u32, r) << 16 | @as(u32, g) << 8 | @as(u32, b));
}

test "rgb" {
    try testing.expectEqual(rgb(0, 0, 0), 0);
    try testing.expectEqual(rgb(255, 255, 255), 0xFFFFFF);
    try testing.expectEqual(rgb(255, 0, 0), 0xFF0000);
    try testing.expectEqual(rgb(0, 255, 0), 0x00FF00);
    try testing.expectEqual(rgb(0, 0, 255), 0x0000FF);
    try testing.expectEqual(rgb(0, 0, 255), 0x0000FF);
}
