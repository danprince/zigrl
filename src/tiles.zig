const types = @import("types.zig");
const colors = @import("colors.zig");
const rgb = colors.rgb;
const Tile = types.Tile;
const Graphic = types.Graphic;

pub const shroud = Graphic{ .ch = ' ', .fg = rgb(255, 255, 255), .bg = rgb(0, 0, 0) };

pub const floor = Tile{
    .walkable = true,
    .transparent = true,
    .dark = .{ .ch = 0x9, .fg = rgb(20, 20, 20), .bg = null },
    .light = .{ .ch = 0xA, .fg = rgb(50, 50, 60), .bg = null },
};

pub const wall = Tile{
    .walkable = false,
    .transparent = false,
    .dark = .{ .ch = 0x7, .fg = rgb(50, 50, 60), .bg = null },
    .light = .{ .ch = 0x8, .fg = rgb(100, 100, 120), .bg = null },
};

pub const down_stairs = Tile{
    .walkable = true,
    .transparent = true,
    .dark = .{ .ch = '>', .fg = rgb(0, 0, 100), .bg = null },
    .light = .{ .ch = '>', .fg = rgb(255, 255, 255), .bg = null },
};
