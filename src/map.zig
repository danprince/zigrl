const std = @import("std");
const types = @import("types.zig");
const term = @import("term.zig");
const utils = @import("utils.zig");
const tile_types = @import("tiles.zig");
const testing = std.testing;
const shroud = tile_types.shroud;
const Allocator = std.mem.Allocator;
const Entity = types.Entity;
const Tile = types.Tile;
const Graphic = types.Graphic;
const Console = term.Console;
const PointSet = utils.PointSet;

const MapParams = struct {
    width: usize,
    height: usize,
    initial_tile: Tile,
    initial_entities: []*Entity = &[0]*Entity{},
    allocator: Allocator,
};

pub const Map = struct {
    const Self = @This();
    width: usize,
    height: usize,
    tiles: []Tile,
    visible: PointSet,
    explored: PointSet,
    allocator: Allocator,
    entities: std.ArrayList(*Entity),

    pub fn init(params: MapParams) !Map {
        var tiles = try params.allocator.alloc(Tile, params.width * params.height);
        for (tiles) |*tile| tile.* = params.initial_tile;

        var entities = std.ArrayList(*Entity).init(params.allocator);
        try entities.appendSlice(params.initial_entities);

        return .{
            .width = params.width,
            .height = params.height,
            .tiles = tiles,
            .entities = entities,
            .visible = try PointSet.init(params.width, params.height, params.allocator),
            .explored = try PointSet.init(params.width, params.height, params.allocator),
            .allocator = params.allocator,
        };
    }

    pub fn deinit(self: *Self) void {
        self.allocator.free(self.tiles);
        self.visible.deinit();
        self.explored.deinit();
        self.entities.deinit();
    }

    /// Adds an entity to the map.
    pub fn addEntity(self: *Self, entity: *Entity) !void {
        try self.entities.append(entity);
    }

    /// Adds an entity to the map at specific coordinates.
    pub fn addEntityAt(self: *Self, x: isize, y: isize, entity: *Entity) !void {
        entity.x = x;
        entity.y = y;
        try self.addEntity(entity);
    }

    /// Removes an entity from the map's entity list.
    pub fn removeEntity(self: *Self, entity: *Entity) void {
        if (std.mem.indexOfScalar(*Entity, self.entities.items, entity)) |index| {
            _ = self.entities.swapRemove(index);
        }
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

    /// Returns the first entity at given coordinates. There may be multiple
    /// entities here, but this method just returns the first.
    pub fn getFirstEntityAt(self: *Self, x: isize, y: isize) ?*Entity {
        for (self.entities.items) |entity| {
            if (entity.x == x and entity.y == y) {
                return entity;
            }
        }
        return null;
    }

    /// Returns the blocking entity a given coordinates. In theory there can
    /// only be one blocking entity per tile.
    pub fn getBlockingEntityAt(self: *Self, x: isize, y: isize) ?*Entity {
        for (self.entities.items) |entity| {
            if (entity.x == x and entity.y == y and entity.blocks_movement) {
                return entity;
            }
        }
        return null;
    }

    /// Returns the first entity with AI at given coordinates.
    pub fn getActorAt(self: *Self, x: isize, y: isize) ?*Entity {
        for (self.entities.items) |entity| {
            if (entity.x == x and entity.y == y and entity.ai != null) {
                return entity;
            }
        }
        return null;
    }

    /// Returns the first item at these coordinates, or null if there are
    /// no items here.
    pub fn getItemAt(self: *Self, x: isize, y: isize) ?*Entity {
        for (self.entities.items) |entity| {
            if (entity.x == x and entity.y == y and entity.consumable != null) {
                return entity;
            }
        }
        return null;
    }

    /// Returns an iterator which yields each of the entities at this position.
    /// The iterator will be invalidated if the map's entity list is modified
    /// during iteration.
    pub fn getEntitiesAt(self: *Self, x: isize, y: isize) EntitiesAtIterator {
        return .{ .map = self, .x = x, .y = y };
    }

    /// Render the map to a console.
    pub fn render(self: *Self, console: *Console) void {
        var y: isize = 0;
        while (y < self.height) : (y += 1) {
            var x: isize = 0;
            while (x < self.width) : (x += 1) {
                const tile = self.getTile(x, y);
                const visible = self.visible.has(x, y);
                const explored = self.explored.has(x, y);
                const graphic = if (visible) tile.light else if (explored) tile.dark else shroud;
                console.put(@intCast(isize, x), @intCast(isize, y), graphic.fg, graphic.bg, graphic.ch);
            }
        }

        for (self.entities.items) |entity| {
            if (self.visible.has(entity.x, entity.y)) {
                console.put(entity.x, entity.y, entity.color, null, entity.char);
            }
        }
    }
};

const EntitiesAtIterator = struct {
    map: *Map,
    x: isize,
    y: isize,
    index: usize = 0,

    pub fn next(self: *EntitiesAtIterator) ?*Entity {
        for (self.map.entities.items[self.index..]) |entity| {
            self.index += 1;
            if (entity.x == self.x and entity.y == self.y) {
                return entity;
            }
        }
        return null;
    }
};

const test_tile = Tile{
    .walkable = true,
    .transparent = true,
    .dark = .{ .ch = ' ', .fg = 0, .bg = 0 },
    .light = .{ .ch = ' ', .fg = 0, .bg = 0 },
};

const test_tile_2 = Tile{
    .walkable = false,
    .transparent = false,
    .dark = .{ .ch = ' ', .fg = 0, .bg = 0 },
    .light = .{ .ch = ' ', .fg = 0, .bg = 0 },
};

test "Map.init / Map.deinit" {
    var map = try Map.init(.{ .width = 10, .height = 10, .initial_tile = test_tile, .allocator = testing.allocator });
    defer map.deinit();
}

test "Map.init with entities" {
    var a = Entity{ .char = 'a', .color = 0x00FF00, .name = "a" };
    var b = Entity{ .char = 'b', .color = 0x00FF00, .name = "b" };
    var c = Entity{ .char = 'c', .color = 0x00FF00, .name = "c" };

    var map = try Map.init(.{
        .width = 10,
        .height = 10,
        .initial_tile = test_tile,
        .initial_entities = &[_]*Entity{ &a, &b, &c },
        .allocator = testing.allocator,
    });
    defer map.deinit();
    try testing.expectEqual(map.entities.items.len, 3);
}

test "Map.init out of memory" {
    var err = Map.init(.{ .width = 10, .height = 10, .initial_tile = test_tile, .allocator = testing.failing_allocator });
    try testing.expectError(Allocator.Error.OutOfMemory, err);
}

test "Map.inBounds" {
    var map = try Map.init(.{ .width = 2, .height = 3, .initial_tile = test_tile, .allocator = testing.allocator });
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
    var map = try Map.init(.{ .width = 10, .height = 10, .initial_tile = test_tile, .allocator = testing.allocator });
    defer map.deinit();
    try testing.expectEqual(map.getTile(5, 5).*, test_tile);
}

test "Map.setTile" {
    var map = try Map.init(.{ .width = 10, .height = 10, .initial_tile = test_tile, .allocator = testing.allocator });
    defer map.deinit();
    map.setTile(5, 5, test_tile_2);
    try testing.expectEqual(map.getTile(5, 5).*, test_tile_2);
    try testing.expectEqual(map.getTile(4, 4).*, test_tile);
}

test "Map.getTileOrNull" {
    var map = try Map.init(.{ .width = 10, .height = 10, .initial_tile = test_tile, .allocator = testing.allocator });
    defer map.deinit();
    try testing.expectEqual(map.getTileOrNull(-1, 0), null);
    try testing.expectEqual(map.getTileOrNull(0, 12), null);
    try testing.expectEqual(map.getTileOrNull(5, 5).?.*, test_tile);
}

test "Map.addEntity" {
    var map = try Map.init(.{ .width = 10, .height = 10, .initial_tile = test_tile, .allocator = testing.allocator });
    defer map.deinit();
    try testing.expectEqual(map.entities.items.len, 0);
    var entity = Entity{ .name = "Foo", .char = 'F', .color = 0xFF0000 };
    try map.addEntity(&entity);
    try testing.expectEqual(map.entities.items.len, 1);
    try testing.expectEqual(map.entities.items[0], &entity);
}

test "Map.addEntityAt" {
    var map = try Map.init(.{ .width = 10, .height = 10, .initial_tile = test_tile, .allocator = testing.allocator });
    defer map.deinit();
    var entity = Entity{ .name = "Foo", .char = 'F', .color = 0xFF0000 };
    try map.addEntityAt(1, 2, &entity);
    try testing.expectEqual(map.entities.items.len, 1);
    try testing.expectEqual(map.entities.items[0], &entity);
    try testing.expectEqual(entity.x, 1);
    try testing.expectEqual(entity.y, 2);
}

test "Map.removeEntity" {
    var map = try Map.init(.{ .width = 10, .height = 10, .initial_tile = test_tile, .allocator = testing.allocator });
    defer map.deinit();
    var entity = Entity.tester("Tester");
    try testing.expectEqual(map.entities.items.len, 0);
    try map.addEntity(&entity);
    try testing.expectEqual(map.entities.items.len, 1);
    map.removeEntity(&entity);
    try testing.expectEqual(map.entities.items.len, 0);
}

test "Map.getFirstEntityAt" {
    var map = try Map.init(.{ .width = 10, .height = 10, .initial_tile = test_tile, .allocator = testing.allocator });
    defer map.deinit();
    var entity_1 = Entity{ .name = "Foo", .char = 'F', .color = 0xFF0000, .x = 1, .y = 2 };
    var entity_2 = Entity{ .name = "Foo", .char = 'F', .color = 0xFF0000, .x = 1, .y = 2 };
    try map.addEntity(&entity_1);
    try map.addEntity(&entity_2);
    try testing.expectEqual(map.getFirstEntityAt(0, 0), null);
    try testing.expectEqual(map.getFirstEntityAt(1, 2), &entity_1);
}

test "Map.getBlockingEntityAt" {
    var map = try Map.init(.{ .width = 10, .height = 10, .initial_tile = test_tile, .allocator = testing.allocator });
    defer map.deinit();
    var non_blocker = Entity{ .name = "Foo", .char = 'F', .color = 0xFF0000, .x = 1, .y = 2, .blocks_movement = false };
    var blocker = Entity{ .name = "Foo", .char = 'F', .color = 0xFF0000, .x = 1, .y = 2, .blocks_movement = true };
    try map.addEntity(&non_blocker);
    try map.addEntity(&blocker);
    try testing.expectEqual(map.getBlockingEntityAt(1, 2), &blocker);
}

test "Map.getEntitiesAt" {
    var map = try Map.init(.{ .width = 10, .height = 10, .initial_tile = test_tile, .allocator = testing.allocator });
    defer map.deinit();
    var a = Entity.tester("a");
    var b = Entity.tester("b");
    var c = Entity.tester("c");
    var d = Entity.tester("d");
    try map.addEntityAt(4, 5, &a);
    try map.addEntityAt(4, 5, &b);
    try map.addEntityAt(4, 5, &c);
    try map.addEntityAt(5, 4, &d);
    var iter = map.getEntitiesAt(4, 5);
    try testing.expectEqual(iter.next(), &a);
    try testing.expectEqual(iter.next(), &b);
    try testing.expectEqual(iter.next(), &c);
    try testing.expectEqual(iter.next(), null);
}

test "Map.getItemAt" {
    var map = try Map.init(.{ .width = 10, .height = 10, .initial_tile = test_tile, .allocator = testing.allocator });
    defer map.deinit();
    var potion = Entity.tester("Potion");
    potion.consumable = .{ .kind = .{ .healing = .{ .amount = 0 } } };
    var player = Entity.tester("Player");
    try map.addEntityAt(1, 2, &player);
    try map.addEntityAt(1, 2, &potion);
    try testing.expectEqual(map.getItemAt(1, 2), &potion);
}
