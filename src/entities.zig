const std = @import("std");
const types = @import("types.zig");
const colors = @import("colors.zig");
const rgb = colors.rgb;
const Entity = types.Entity;

pub const player = Entity{ .char = '@', .color = rgb(255, 255, 255), .name = "Player", .blocks_movement = true };
pub const orc = Entity{ .char = 'o', .color = rgb(63, 127, 63), .name = "Orc", .blocks_movement = true };
pub const troll = Entity{ .char = 'T', .color = rgb(0, 127, 0), .name = "Troll", .blocks_movement = true };
