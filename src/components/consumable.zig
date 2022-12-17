const std = @import("std");
const types = @import("../types.zig");
const colors = @import("../colors.zig");
const utils = @import("../utils.zig");
const engine = @import("../engine.zig");
const actions = @import("../actions.zig");
const Action = actions.Action;
const ActionResult = actions.ActionResult;
const rgb = colors.rgb;
const testing = std.testing;
const Entity = types.Entity;
const Self = @This();

const ConsumableKindType = enum {
    healing,
    lightning_damage,
};

const ConsumableKind = union(ConsumableKindType) {
    healing: struct { amount: isize },
    lightning_damage: struct { damage: isize, maximum_range: isize },
};

entity: *Entity = undefined,
kind: ConsumableKind,

pub fn init(self: *Self, entity: *Entity) void {
    self.entity = entity;
}

pub fn deinit(self: *Self) void {
    _ = self;
}

pub fn activate(self: *Self, consumer: *Entity) ActionResult {
    switch (self.kind) {
        .healing => |healing| {
            if (consumer.fighter) |*fighter| {
                const recovered = fighter.heal(healing.amount);
                if (recovered > 0) {
                    engine.message_log.print("You consume the {s}, and recover {d} HP!", .{ self.entity.name, recovered }, colors.health_recovered);
                    self.consume(consumer);
                    return actions.success();
                }
            }
            return actions.failure("Your health is already full.");
        },
        .lightning_damage => |lightning| {
            var target: ?*Entity = null;
            var closest_distance = lightning.maximum_range + 1;

            for (engine.map.entities.items) |entity| {
                if (entity == consumer) continue;
                if (entity.fighter == null) continue;
                const distance = consumer.distance(entity.x, entity.y);
                if (distance < closest_distance) {
                    target = entity;
                    closest_distance = distance;
                }
            }

            if (target) |target_entity| {
                engine.message_log.print(
                    "A lightning bolt strikes the {s} with a loud thunder for {d} damage",
                    .{ target_entity.name, lightning.damage },
                    colors.white,
                );
                _ = target_entity.fighter.?.damage(lightning.damage);
                self.consume(consumer);
                return actions.success();
            } else {
                return actions.failure("No enemy is close enough to strike.");
            }
        },
    }
}

pub fn consume(self: *Self, consumer: *Entity) void {
    if (consumer.inventory) |*inventory| inventory.remove(self.entity);
}
