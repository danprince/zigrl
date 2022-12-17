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
current_level: usize = 1,
current_xp: usize = 0,
level_up_base: usize = 0,
level_up_factor: usize = 150,
xp_given: usize = 0,

pub fn init(self: *Self, entity: *Entity) void {
    self.entity = entity;
}

pub fn deinit(self: *Self) void {
    self.entity = undefined;
}

pub fn experienceToNextLevel(self: *const Self) usize {
    return self.level_up_base + self.current_level * self.level_up_factor;
}

pub fn requiresLevelUp(self: *const Self) bool {
    return self.current_xp > self.experienceToNextLevel();
}

pub fn addXp(self: *Self, xp: usize) void {
    if (xp == 0 or self.level_up_base == 0) {
        return;
    }

    self.current_xp += xp;
    engine.message_log.print("You gain {d} experience points.", .{xp}, colors.white);

    if (self.requiresLevelUp()) {
        engine.message_log.print("You advance to level {d}.", .{self.current_level + 1}, colors.white);
    }
}

pub fn increaseLevel(self: *Self) void {
    self.current_xp -= self.experienceToNextLevel();
    self.current_level += 1;
}

pub fn increaseMaxHp(self: *Self, amount: isize) void {
    if (self.entity.fighter) |*fighter| {
        fighter.max_hp += amount;
        fighter.setHP(fighter.hp + amount);
        engine.message_log.add("Your health improves!", colors.white);
        self.increaseLevel();
    }
}

pub fn increasePower(self: *Self, amount: isize) void {
    if (self.entity.fighter) |*fighter| {
        fighter.base_power += amount;
        engine.message_log.add("You feel stronger!", colors.white);
        self.increaseLevel();
    }
}

pub fn increaseDefense(self: *Self, amount: isize) void {
    if (self.entity.fighter) |*fighter| {
        fighter.base_defense += amount;
        engine.message_log.add("Your movements are getting swifter!", colors.white);
        self.increaseLevel();
    }
}
