const std = @import("std");
const types = @import("types.zig");
const term = @import("term.zig");
const testing = std.testing;
const Allocator = std.mem.Allocator;
const Tile = types.Tile;
const Console = term.Console;

pub const Map = struct {
    const Self = @This();
    width: usize,
    height: usize,
    tiles: []Tile,
    allocator: Allocator,

    pub fn init(width: usize, height: usize, initial_tile: Tile, allocator: Allocator) !Map {
        var tiles = try allocator.alloc(Tile, width * height);
        for (tiles) |*tile| tile.* = initial_tile;

        return .{
            .width = width,
            .height = height,
            .tiles = tiles,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Self) void {
        self.allocator.free(self.tiles);
    }

    /// Sets a tile inside the map. Assumes the coords are inside the bounds.
    pub fn setTile(self: *Self, x: isize, y: isize, tile: Tile) void {
        self.tiles[@intCast(usize, x) + @intCast(usize, y) * self.width] = tile;
    }

    /// Returns a tile from inside the map. Assumes the coords are inside the bounds.
    pub fn getTile(self: *Self, x: isize, y: isize) *Tile {
        return &self.tiles[@intCast(usize, x) + @intCast(usize, y) * self.width];
    }

    /// Returns a tile from inside the map, or null if the coords were out of bounds.
    pub fn getTileOrNull(self: *Self, x: isize, y: isize) ?*Tile {
        return if (self.inBounds(x, y)) self.getTile(x, y) else null;
    }

    /// Returns true if x and y are inside the bounds of this map.
    pub fn inBounds(self: *Self, x: isize, y: isize) bool {
        return x >= 0 and y >= 0 and x < self.width and y < self.height;
    }

    /// Render the map to a console.
    pub fn render(self: *Self, console: *Console) void {
        var y: usize = 0;
        while (y < self.height) : (y += 1) {
            var x: usize = 0;
            while (x < self.width) : (x += 1) {
                var tile = self.tiles[x + y * self.width];
                console.put(@intCast(isize, x), @intCast(isize, y), tile.dark.fg, tile.dark.bg, tile.dark.ch);
            }
        }
    }
};

const test_tile = Tile{
    .walkable = true,
    .transparent = true,
    .dark = .{ .ch = ' ', .fg = 0, .bg = 0 },
};

const test_tile_2 = Tile{
    .walkable = false,
    .transparent = false,
    .dark = .{ .ch = ' ', .fg = 0, .bg = 0 },
};

test "Map.init / Map.deinit" {
    var map = try Map.init(10, 10, test_tile, testing.allocator);
    defer map.deinit();
}

test "Map.init out of memory" {
    var err = Map.init(100, 100, test_tile, testing.failing_allocator);
    try testing.expectError(Allocator.Error.OutOfMemory, err);
}

test "Map.inBounds" {
    var map = try Map.init(2, 3, test_tile, testing.allocator);
    defer map.deinit();
    try testing.expect(map.inBounds(0, 0));
    try testing.expect(map.inBounds(1, 2));
    try testing.expect(!map.inBounds(2, 3));
    try testing.expect(!map.inBounds(-1, -1));
    try testing.expect(!map.inBounds(-1, 0));
    try testing.expect(!map.inBounds(0, -1));
    try testing.expect(!map.inBounds(2, 0));
    try testing.expect(!map.inBounds(0, 3));
}

test "Map.getTile" {
    var map = try Map.init(10, 10, test_tile, testing.allocator);
    defer map.deinit();
    try testing.expectEqual(map.getTile(5, 5).*, test_tile);
}

test "Map.setTile" {
    var map = try Map.init(10, 10, test_tile, testing.allocator);
    defer map.deinit();
    map.setTile(5, 5, test_tile_2);
    try testing.expectEqual(map.getTile(5, 5).*, test_tile_2);
    try testing.expectEqual(map.getTile(4, 4).*, test_tile);
}

test "Map.getTileOrNull" {
    var map = try Map.init(10, 10, test_tile, testing.allocator);
    defer map.deinit();
    try testing.expectEqual(map.getTileOrNull(-1, 0), null);
    try testing.expectEqual(map.getTileOrNull(0, 12), null);
    try testing.expectEqual(map.getTileOrNull(5, 5).?.*, test_tile);
}
