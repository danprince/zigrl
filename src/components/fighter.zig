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
defense: isize = 0,
power: isize = 0,

pub fn init(self: *Self, entity: *Entity) void {
    self.entity = entity;
    self.max_hp = self.hp;
}

pub fn deinit(self: *Self) void {
    _ = self;
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
        engine.handler.mode = .gameover;
    } else {
        engine.message_log.print("{s} is dead!", .{self.entity.name}, colors.enemy_die);
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
