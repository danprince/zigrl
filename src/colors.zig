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

pub const white = rgb(0xFF, 0xFF, 0xFF);
pub const black = rgb(0x0, 0x0, 0x0);

pub const player_atk = rgb(0xE0, 0xE0, 0xE0);
pub const enemy_atk = rgb(0xFF, 0xC0, 0xC0);

pub const player_die = rgb(0xFF, 0x30, 0x30);
pub const enemy_die = rgb(0xFF, 0xA0, 0x30);

pub const welcome_text = rgb(0x20, 0xA0, 0xFF);

pub const bar_text = white;
pub const bar_filled = rgb(0x0, 0x60, 0x0);
pub const bar_empty = rgb(0x40, 0x10, 0x10);
