const std = @import("std");
const utils = @import("utils.zig");
const types = @import("types.zig");
const tiles = @import("tiles.zig");
const gamemap = @import("map.zig");
const entities = @import("entities.zig");
const testing = std.testing;
const prng = std.rand.DefaultPrng;
const Allocator = std.mem.Allocator;
const Vec = types.Vec;
const Map = gamemap.Map;
const Tile = tiles.Tile;
const Entity = types.Entity;

const RectangularRoom = struct {
    const Self = @This();
    x1: isize,
    y1: isize,
    x2: isize,
    y2: isize,

    pub fn init(x: isize, y: isize, width: isize, height: isize) RectangularRoom {
        return .{ .x1 = x, .y1 = y, .x2 = x + width, .y2 = y + height };
    }

    pub fn center(self: *const Self) Vec {
        const center_x = self.x1 + @divFloor(self.x2 - self.x1, 2);
        const center_y = self.y1 + @divFloor(self.y2 - self.y1, 2);
        return .{ .x = center_x, .y = center_y };
    }

    pub fn intersects(self: *const Self, other: *const Self) bool {
        return (self.x1 <= other.x2 and
            self.x2 >= other.x1 and
            self.y1 <= other.y2 and
            self.y2 >= other.y1);
    }
};

test "RectangularRoom.init" {
    var room = RectangularRoom.init(0, 1, 2, 3);
    try testing.expectEqual(room.x1, 0);
    try testing.expectEqual(room.y1, 1);
    try testing.expectEqual(room.x1, 0);
    try testing.expectEqual(room.y1, 1);
}

test "RectangularRoom.intersects" {
    try testing.expect(RectangularRoom.init(0, 0, 10, 10).intersects(&RectangularRoom.init(0, 0, 10, 10)));
    try testing.expect(RectangularRoom.init(0, 0, 10, 10).intersects(&RectangularRoom.init(5, 0, 10, 10)));
    try testing.expect(!RectangularRoom.init(0, 0, 10, 10).intersects(&RectangularRoom.init(11, 0, 10, 10)));
}

const DungeonParams = struct {
    seed: u64,
    map_width: usize,
    map_height: usize,
    max_rooms: isize,
    room_min_size: isize,
    room_max_size: isize,
    max_monsters_per_room: usize,
    player: *Entity,
    allocator: Allocator,
};

pub fn generateDungeon(params: DungeonParams) !Map {
    var dungeon = try Map.init(.{ .width = params.map_width, .height = params.map_height, .initial_tile = tiles.wall, .allocator = params.allocator });
    var rnd = std.rand.DefaultPrng.init(params.seed);
    var rng = rnd.random();

    var rooms = std.ArrayList(RectangularRoom).init(params.allocator);
    defer rooms.deinit();

    var room_count: usize = 0;
    rooms: while (room_count < params.max_rooms) : (room_count += 1) {
        const room_width = rng.intRangeAtMost(isize, params.room_min_size, params.room_max_size);
        const room_height = rng.intRangeAtMost(isize, params.room_min_size, params.room_max_size);
        const dungeon_width = @intCast(isize, dungeon.width);
        const dungeon_height = @intCast(isize, dungeon.height);
        const x = rng.intRangeAtMost(isize, 0, dungeon_width - room_width - 1);
        const y = rng.intRangeAtMost(isize, 0, dungeon_height - room_height - 1);
        const room = RectangularRoom.init(x, y, room_width, room_height);

        for (rooms.items) |other| {
            if (room.intersects(&other)) {
                continue :rooms;
            }
        }

        if (rooms.items.len == 0) {
            const center = room.center();
            params.player.x = center.x;
            params.player.y = center.y;
        } else {
            const p1 = room.center();
            const p2 = rooms.items[rooms.items.len - 1].center();
            digTunnel(&dungeon, rng, p1.x, p1.y, p2.x, p2.y);
        }

        // Dig out floor for this room
        digRect(&dungeon, x, y, room_width, room_height);

        // Spawn entities in this room
        try placeEntities(&dungeon, rng, room, params.max_monsters_per_room);

        try rooms.append(room);
    }

    return dungeon;
}

fn digTunnel(dungeon: *Map, rng: std.rand.Random, x1: isize, y1: isize, x2: isize, y2: isize) void {
    var corner_x = x1;
    var corner_y = y2;

    if (rng.boolean()) {
        corner_x = x2;
        corner_y = y1;
    }

    var line1 = utils.bresenham(x1, y1, corner_x, corner_y);
    var line2 = utils.bresenham(corner_x, corner_y, x2, y2);
    while (line1.next()) |pos| dungeon.setTile(pos.x, pos.y, tiles.floor);
    while (line2.next()) |pos| dungeon.setTile(pos.x, pos.y, tiles.floor);
}

fn digRect(dungeon: *Map, x: isize, y: isize, w: isize, h: isize) void {
    var j: isize = y;
    while (j < y + h) : (j += 1) {
        var i: isize = x;
        while (i < x + w) : (i += 1) {
            dungeon.setTile(i, j, tiles.floor);
        }
    }
}

fn placeEntities(dungeon: *Map, rng: std.rand.Random, room: RectangularRoom, maximum_monsters: usize) !void {
    const number_of_monsters = rng.intRangeAtMost(usize, 0, maximum_monsters);

    var i: usize = 0;
    while (i < number_of_monsters) : (i += 1) {
        const x = rng.intRangeAtMost(isize, room.x1 + 1, room.x2 - 1);
        const y = rng.intRangeAtMost(isize, room.y1 + 1, room.y2 - 1);
        if (dungeon.getFirstEntityAt(x, y) != null) continue;

        if (rng.float(f32) < 0.8) {
            try dungeon.addEntityAt(x, y, entities.orc.spawn());
        } else {
            try dungeon.addEntityAt(x, y, entities.troll.spawn());
        }
    }
}
