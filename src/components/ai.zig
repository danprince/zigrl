const std = @import("std");
const types = @import("../types.zig");
const actions = @import("../actions.zig");
const engine = @import("../engine.zig");
const testing = std.testing;
const Action = actions.Action;
const Entity = types.Entity;

pub const BehaviourType = enum {
    hostile,
};

pub const Behaviour = union(BehaviourType) {
    hostile: void,
};

const Self = @This();

entity: *Entity = undefined,
behaviour: Behaviour,

pub fn init(self: *Self, entity: *Entity) void {
    self.entity = entity;
}

pub fn deinit(self: *Self) void {
    _ = self;
}

pub fn perform(self: *Self) void {
    switch (self.behaviour) {
        .hostile => {
            const target = engine.player;
            const dx = target.x - self.entity.x;
            const dy = target.y - self.entity.y;
            const distance = std.math.max(std.math.absInt(dx) catch 0, std.math.absInt(dy) catch 0);

            if (engine.map.visible.has(self.entity.x, self.entity.y)) {
                if (distance <= 1) {
                    _ = actions.perform(actions.melee(dx, dy), self.entity);
                } else {
                    // TODO: Use actual pathfinding
                    _ = actions.perform(actions.move(std.math.sign(dx), std.math.sign(dy)), self.entity);
                }
            }

            _ = actions.perform(actions.wait(), self.entity);
        },
    }
}
