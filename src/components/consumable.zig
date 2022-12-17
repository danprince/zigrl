const std = @import("std");
const types = @import("../types.zig");
const colors = @import("../colors.zig");
const utils = @import("../utils.zig");
const engine = @import("../engine.zig");
const actions = @import("../actions.zig");
const Ai = @import("./ai.zig");
const Action = actions.Action;
const ActionResult = actions.ActionResult;
const rgb = colors.rgb;
const testing = std.testing;
const Entity = types.Entity;
const Vec = types.Vec;
const Self = @This();

const ConsumableKindType = enum {
    healing,
    lightning_damage,
    fireball_damage,
    confusion,
};

const ConsumableKind = union(ConsumableKindType) {
    healing: struct { amount: isize },
    lightning_damage: struct { damage: isize, maximum_range: isize },
    fireball_damage: struct { damage: isize, radius: isize },
    confusion: struct { number_of_turns: usize },
};

entity: *Entity = undefined,
kind: ConsumableKind,

pub fn init(self: *Self, entity: *Entity) void {
    self.entity = entity;
}

pub fn deinit(self: *Self) void {
    _ = self;
}

pub fn getAction(self: *const Self) ?Action {
    var action: ?Action = null;

    switch (self.kind) {
        .confusion => {
            engine.mouse_location.x = engine.player.x;
            engine.mouse_location.y = engine.player.y;
            engine.event_handler = .{ .target_point = .{ .item = self.entity } };
        },
        .fireball_damage => |fireball| {
            engine.mouse_location.x = engine.player.x;
            engine.mouse_location.y = engine.player.y;
            engine.event_handler = .{
                .target_area = .{
                    .item = self.entity,
                    .radius = fireball.radius,
                },
            };
        },
        else => action = actions.use(self.entity),
    }

    return action;
}

pub fn activate(self: *Self, consumer: *Entity, target_pos: ?Vec) ActionResult {
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
        .fireball_damage => |fireball| {
            if (target_pos) |pos| {
                if (!engine.map.visible.has(pos.x, pos.y)) {
                    return actions.failure("You cannot target an area you cannot see.");
                }

                var targets_hit = false;

                for (engine.map.entities.items) |entity| {
                    if (entity.fighter) |*fighter| {
                        if (entity.distance(pos.x, pos.y) < fireball.radius) {
                            engine.message_log.print("The {s} is engulfed in a fiery explosion, taking {d} damage!", .{ entity.name, fireball.damage }, colors.white);
                            _ = fighter.damage(fireball.damage);
                            targets_hit = true;
                        }
                    }
                }

                if (!targets_hit) {
                    return actions.failure("There are no targets in the radius.");
                }

                self.consume(consumer);
                return actions.success();
            }
            return actions.failure("This spell needs to be targeted.");
        },
        .confusion => |confusion| {
            if (target_pos) |pos| {
                if (!engine.map.visible.has(pos.x, pos.y)) {
                    return actions.failure("You cannot target an area you cannot see.");
                }

                if (engine.map.getActorAt(pos.x, pos.y)) |target| {
                    if (target == &engine.player) {
                        return actions.failure("You cannot confuse yourself");
                    }

                    if (target.ai) |*ai| {
                        engine.message_log.print(
                            "The eyes of the {s} look vacant, as it starts to stumble around!",
                            .{target.name},
                            colors.status_effect_applied,
                        );
                        ai.pushBehaviour(.{ .confused = .{ .turns_remaining = confusion.number_of_turns } });
                    }
                } else {
                    return actions.failure("You must select an enemy to target.");
                }
            }
            return actions.failure("You can't confuse this!");
        },
    }
}

pub fn consume(self: *Self, consumer: *Entity) void {
    if (consumer.inventory) |*inventory| inventory.remove(self.entity);
}
