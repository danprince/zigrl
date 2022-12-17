const types = @import("types.zig");
const colors = @import("colors.zig");
const rgb = colors.rgb;
const Tile = types.Tile;
const Graphic = types.Graphic;

pub const shroud = Graphic{ .ch = ' ', .fg = rgb(255, 255, 255), .bg = rgb(0, 0, 0) };

pub const floor = Tile{
    .walkable = true,
    .transparent = true,
    .dark = .{ .ch = ' ', .fg = rgb(255, 255, 255), .bg = rgb(50, 50, 150) },
    .light = .{ .ch = ' ', .fg = rgb(255, 255, 255), .bg = rgb(200, 180, 50) },
};

pub const wall = Tile{
    .walkable = false,
    .transparent = false,
    .dark = .{ .ch = ' ', .fg = rgb(255, 255, 255), .bg = rgb(0, 0, 100) },
    .light = .{ .ch = ' ', .fg = rgb(255, 255, 255), .bg = rgb(130, 110, 50) },
};

pub const down_stairs = Tile{
    .walkable = true,
    .transparent = true,
    .dark = .{ .ch = '>', .fg = rgb(0, 0, 100), .bg = rgb(50, 50, 150) },
    .light = .{ .ch = '>', .fg = rgb(255, 255, 255), .bg = rgb(200, 180, 50) },
};
