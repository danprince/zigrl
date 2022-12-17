const std = @import("std");
const engine = @import("engine.zig");
const registry = @import("registry.zig");
const Fighter = @import("components/fighter.zig");
const Ai = @import("components/ai.zig");
const Consumable = @import("components/consumable.zig");
const Inventory = @import("components/inventory.zig");
const Allocator = std.mem.Allocator;
const testing = std.testing;

pub const Vec = struct {
    x: isize,
    y: isize,

    pub fn euclideanDistance(from: Vec, to: Vec) isize {
        const dx = @intToFloat(f32, to.x - from.x);
        const dy = @intToFloat(f32, to.y - from.y);
        return @floatToInt(isize, std.math.hypot(f32, dx, dy));
    }
};

pub fn vec(x: isize, y: isize) Vec {
    return .{ .x = x, .y = y };
}

test "Vec euclidean distance" {
    try testing.expectEqual(vec(0, 0).euclideanDistance(vec(5, 0)), 5);
    try testing.expectEqual(vec(5, 0).euclideanDistance(vec(0, 0)), 5);
    try testing.expectEqual(vec(0, 0).euclideanDistance(vec(0, 5)), 5);
    try testing.expectEqual(vec(0, 5).euclideanDistance(vec(0, 0)), 5);
    try testing.expectEqual(vec(0, 0).euclideanDistance(vec(5, 5)), 7);
    try testing.expectEqual(vec(5, 5).euclideanDistance(vec(0, 0)), 7);
}

const RenderOrder = enum { corpse, item, actor };

pub const Entity = struct {
    const Self = @This();

    x: isize = 0,
    y: isize = 0,
    char: u8,
    color: ?i32,
    name: []const u8,
    blocks_movement: bool = false,
    render_order: RenderOrder = .corpse,
    parent: ?*Entity = null,
    fighter: ?Fighter = null,
    ai: ?Ai = null,
    consumable: ?Consumable = null,
    inventory: ?Inventory = null,
    allocator: Allocator = undefined,

    /// Called internally when the entity is added to the engine. Use `spawn`
    /// instead of init'ing entities yourself.
    pub fn init(self: *Self, allocator: Allocator) void {
        self.allocator = allocator;
        if (self.fighter) |*fighter| fighter.init(self);
        if (self.ai) |*ai| ai.init(self, allocator);
        if (self.consumable) |*consumable| consumable.init(self);
        if (self.inventory) |*inventory| inventory.init(self, allocator);
    }

    pub fn deinit(self: *Self) void {
        if (self.fighter) |*fighter| fighter.deinit(self);
        if (self.ai) |*ai| ai.deinit(self);
        if (self.consumable) |*consumable| consumable.deinit(self);
        if (self.inventory) |*inventory| inventory.deinit(self);
    }

    /// Adds a copy of this entity into the engine and returns a pointer to it.
    /// Does not modify the entity that it is called on.
    pub fn spawn(self: Self) *Entity {
        return registry.addEntity(self);
    }

    /// Checks whether this entity is considered to be "alive". Living entities
    /// either have a fighter component with non-zero HP, or an AI component.
    pub fn isAlive(self: *Self) bool {
        if (self.fighter) |fighter| return fighter.hp > 0;
        if (self.ai != null) return true;
        return false;
    }

    /// Returns the distance between this entity and the given coordinate.
    pub fn distance(self: *const Self, x: isize, y: isize) isize {
        return @floatToInt(isize, std.math.hypot(f32, @intToFloat(f32, self.x - x), @intToFloat(f32, self.y - y)));
    }

    pub fn move(self: *Self, dx: isize, dy: isize) void {
        self.x += dx;
        self.y += dy;
    }

    pub fn tester(name: []const u8) Entity {
        return .{
            .char = 'T',
            .color = 0xFF0000,
            .blocks_movement = false,
            .name = name,
        };
    }

    pub fn compareByRenderOrder(_: void, a: *Entity, b: *Entity) bool {
        return @enumToInt(a.render_order) < @enumToInt(b.render_order);
    }
};

test "Entity.compareByRenderOrder" {
    var a = Entity.tester("a");
    a.render_order = .corpse;
    var b = Entity.tester("b");
    b.render_order = .item;
    var c = Entity.tester("c");
    c.render_order = .actor;
    var entities = &[_]*Entity{ &c, &a, &b };
    std.sort.sort(*Entity, entities, {}, Entity.compareByRenderOrder);
    try testing.expectEqual(entities[0], &a);
    try testing.expectEqual(entities[1], &b);
    try testing.expectEqual(entities[2], &c);
}

pub const Graphic = struct {
    ch: u8,
    fg: ?i32,
    bg: ?i32,
};

pub const Tile = struct {
    const Self = @This();
    walkable: bool,
    transparent: bool,
    dark: Graphic,
    light: Graphic,
};
