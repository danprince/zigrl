const std = @import("std");
const types = @import("../types.zig");
const colors = @import("../colors.zig");
const engine = @import("../engine.zig");
const actions = @import("../actions.zig");
const Entity = types.Entity;

const Slot = enum { armor, weapon };

const Self = @This();
entity: *Entity = undefined,
armor: ?*Entity = null,
weapon: ?*Entity = null,

pub fn init(self: *Self, entity: *Entity) void {
    self.entity = entity;
}

pub fn deinit(self: *Self) void {
    self.entity = undefined;
}

pub fn getDefenseBonus(self: *const Self) isize {
    var bonus: isize = 0;

    if (self.armor) |item| {
        if (item.equippable) |equippable| {
            bonus += equippable.defense_bonus;
        }
    }

    if (self.weapon) |item| {
        if (item.equippable) |equippable| {
            bonus += equippable.defense_bonus;
        }
    }

    return bonus;
}

pub fn getPowerBonus(self: *const Self) isize {
    var bonus: isize = 0;

    if (self.armor) |item| {
        if (item.equippable) |equippable| {
            bonus += equippable.power_bonus;
        }
    }

    if (self.weapon) |item| {
        if (item.equippable) |equippable| {
            bonus += equippable.power_bonus;
        }
    }

    return bonus;
}

pub fn isItemEquipped(self: *const Self, item: *const Entity) bool {
    return self.armor == item or self.weapon == item;
}

pub fn getItemInSlot(self: *Self, slot: Slot) ?*Entity {
    return switch (slot) {
        .weapon => self.weapon,
        .armor => self.armor,
    };
}

pub fn equipToSlot(self: *Self, slot: Slot, item: *Entity) void {
    var current_item = self.getItemInSlot(slot);

    if (current_item != null) {
        self.unequipFromSlot(slot);
    }

    engine.message_log.print("You equip the {s}.", .{item.name}, colors.white);

    switch (slot) {
        .weapon => self.weapon = item,
        .armor => self.armor = item,
    }
}

pub fn unequipFromSlot(self: *Self, slot: Slot) void {
    if (self.getItemInSlot(slot)) |item| {
        engine.message_log.print("You unequip the {s}.", .{item.name}, colors.white);
    }

    switch (slot) {
        .weapon => self.weapon = null,
        .armor => self.armor = null,
    }
}

pub fn toggleEquip(self: *Self, equippable_item: *Entity) void {
    if (equippable_item.equippable) |equippable| {
        const slot: Slot = switch (equippable.kind) {
            .weapon => .weapon,
            .armor => .armor,
        };

        if (self.getItemInSlot(slot) == equippable_item) {
            self.unequipFromSlot(slot);
        } else {
            self.equipToSlot(slot, equippable_item);
        }
    }
}
