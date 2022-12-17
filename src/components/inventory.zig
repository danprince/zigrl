const std = @import("std");
const types = @import("../types.zig");
const utils = @import("../utils.zig");
const engine = @import("../engine.zig");
const colors = @import("../colors.zig");
const errors = @import("../errors.zig");
const Allocator = std.mem.Allocator;
const Entity = types.Entity;
const Self = @This();

entity: *Entity = undefined,
items: std.ArrayList(*Entity) = undefined,
allocator: Allocator = undefined,
capacity: usize,

pub fn init(self: *Self, entity: *Entity, allocator: Allocator) void {
    self.entity = entity;
    self.items = std.ArrayList(*Entity).init(allocator);
    self.items.ensureTotalCapacity(self.capacity) catch errors.oom();
    self.allocator = allocator;
}

pub fn deinit(self: *Self) void {
    self.items.deinit();
}

pub fn isFull(self: *const Self) bool {
    return self.items.items.len >= self.capacity;
}

pub fn add(self: *Self, item: *Entity) void {
    self.items.append(item) catch errors.oom();
}

pub fn remove(self: *Self, item: *Entity) void {
    const index_or_null = std.mem.indexOfScalar(*Entity, self.items.items, item);
    if (index_or_null) |index| {
        _ = self.items.orderedRemove(index);
    }
}

pub fn getItemAtIndex(self: *const Self, index: usize) ?*Entity {
    if (index < self.items.items.len) {
        return self.items.items[index];
    } else return null;
}

pub fn drop(self: *Self, item: *Entity) void {
    self.remove(item);
    engine.map.addEntityAt(self.entity.x, self.entity.y, item) catch errors.crash("Can't remove from inventory");
    engine.message_log.print("You dropped the {s}.", .{item.name}, colors.white);
}
