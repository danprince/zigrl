const std = @import("std");
const types = @import("types.zig");
const colors = @import("colors.zig");
const rgb = colors.rgb;
const Entity = types.Entity;

pub const player = Entity{
    .char = '@',
    .color = rgb(255, 255, 255),
    .name = "Player",
    .blocks_movement = true,
    .render_order = .actor,
    .fighter = .{ .hp = 30, .defense = 2, .power = 5 },
};

pub const orc = Entity{
    .char = 'o',
    .color = rgb(63, 127, 63),
    .name = "Orc",
    .blocks_movement = true,
    .render_order = .actor,
    .fighter = .{ .hp = 10, .defense = 0, .power = 3 },
    .ai = .{ .behaviour = .hostile },
};

pub const troll = Entity{
    .char = 'T',
    .color = rgb(0, 127, 0),
    .name = "Troll",
    .blocks_movement = true,
    .render_order = .actor,
    .fighter = .{ .hp = 16, .defense = 1, .power = 4 },
    .ai = .{ .behaviour = .hostile },
};
