const std = @import("std");
const types = @import("../types.zig");
const colors = @import("../colors.zig");
const engine = @import("../engine.zig");
const actions = @import("../actions.zig");
const Entity = types.Entity;

const EquipmentType = enum {
    weapon,
    armor,
};

const Self = @This();
entity: *Entity = undefined,
kind: EquipmentType,
power_bonus: isize = 0,
defense_bonus: isize = 0,

pub fn init(self: *Self, entity: *Entity) void {
    self.entity = entity;
}

pub fn deinit(self: *Self) void {
    self.entity = undefined;
}
