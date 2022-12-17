const std = @import("std");
const types = @import("../types.zig");
const colors = @import("../colors.zig");
const utils = @import("../utils.zig");
const engine = @import("../engine.zig");
const rgb = colors.rgb;
const testing = std.testing;
const Entity = types.Entity;

const Self = @This();

entity: *Entity = undefined,
hp: isize = 0,
max_hp: isize = 0,
base_defense: isize = 0,
base_power: isize = 0,

pub fn init(self: *Self, entity: *Entity) void {
    self.entity = entity;
    self.max_hp = self.hp;
}

pub fn deinit(self: *Self) void {
    _ = self;
}

pub fn defense(self: *const Self) isize {
    return self.base_defense + self.defenseBonus();
}

pub fn defenseBonus(self: *const Self) isize {
    return if (self.entity.equipment) |equipment| equipment.getDefenseBonus() else 0;
}

pub fn power(self: *const Self) isize {
    return self.base_power + self.powerBonus();
}

pub fn powerBonus(self: *const Self) isize {
    return if (self.entity.equipment) |equipment| equipment.getPowerBonus() else 0;
}

pub fn setHP(self: *Self, amount: isize) void {
    self.hp = std.math.clamp(amount, 0, self.max_hp);

    if (self.hp == 0) {
        self.die();
    }
}

pub fn die(self: *Self) void {
    self.entity.char = '%';
    self.entity.color = rgb(191, 0, 0);
    self.entity.blocks_movement = false;
    self.entity.ai = null;
    self.entity.render_order = .corpse;

    if (self.entity == &engine.player) {
        engine.message_log.add("You died!", colors.player_die);
    } else {
        engine.message_log.print("{s} is dead!", .{self.entity.name}, colors.enemy_die);
    }

    if (engine.player.level) |*player_level| {
        if (self.entity.level) |entity_level| {
            player_level.addXp(entity_level.xp_given);
        }
    }
}

pub fn damage(self: *Self, amount: isize) isize {
    const hp_before = self.hp;
    self.setHP(self.hp - amount);
    return std.math.absInt(self.hp - hp_before) catch 0;
}

pub fn heal(self: *Self, amount: isize) isize {
    return self.damage(-amount);
}
