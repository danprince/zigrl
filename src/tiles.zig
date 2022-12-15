const types = @import("types.zig");
const colors = @import("colors.zig");
const rgb = colors.rgb;
const Tile = types.Tile;

pub const floor = Tile{
    .walkable = true,
    .transparent = true,
    .dark = .{ .ch = ' ', .fg = rgb(255, 255, 255), .bg = rgb(50, 50, 150) },
};

pub const wall = Tile{
    .walkable = false,
    .transparent = false,
    .dark = .{ .ch = ' ', .fg = rgb(255, 255, 255), .bg = rgb(0, 0, 100) },
};
