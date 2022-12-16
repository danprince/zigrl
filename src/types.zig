const std = @import("std");
const engine = @import("engine.zig");
const registry = @import("registry.zig");
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

pub const Entity = struct {
    const Self = @This();

    x: isize = 0,
    y: isize = 0,
    char: u8,
    color: ?i32,
    name: []const u8,
    blocks_movement: bool = false,

    /// Called internally when the entity is added to the engine. Use `spawn`
    /// instead of init'ing entities yourself.
    pub fn init(self: *Self) void {
        _ = self;
    }

    /// Adds a copy of this entity into the engine and returns a pointer to it.
    /// Does not modify the entity that it is called on.
    pub fn spawn(self: Self) *Entity {
        return registry.addEntity(self);
    }

    pub fn move(self: *Self, dx: isize, dy: isize) void {
        self.x += dx;
        self.y += dy;
    }
};

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
