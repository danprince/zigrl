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

const ConsumableKindType = enum { healing };

const ConsumableKind = union(ConsumableKindType) {
    healing: struct { amount: isize },
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
    }
}

pub fn consume(self: *Self, consumer: *Entity) void {
    if (consumer.inventory) |*inventory| inventory.remove(self.entity);
}
