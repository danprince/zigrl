const std = @import("std");
const types = @import("../types.zig");
const actions = @import("../actions.zig");
const engine = @import("../engine.zig");
const colors = @import("../colors.zig");
const errors = @import("../errors.zig");
const rng = @import("../rng.zig");
const utils = @import("../utils.zig");
const testing = std.testing;
const Allocator = std.mem.Allocator;
const Vec = types.Vec;
const Action = actions.Action;
const Entity = types.Entity;

pub const BehaviourType = enum {
    hostile,
    confused,
};

pub const Behaviour = union(BehaviourType) {
    hostile: void,
    confused: Confusion,
};

const Confusion = struct {
    turns_remaining: usize,
};

const Self = @This();

entity: *Entity = undefined,
behaviours: std.ArrayList(Behaviour) = undefined,
initial_behaviour: ?Behaviour = null,
allocator: Allocator = undefined,

pub fn with(behaviour: Behaviour) Self {
    return .{
        .initial_behaviour = behaviour,
    };
}

pub fn init(self: *Self, entity: *Entity, allocator: Allocator) void {
    self.entity = entity;
    self.allocator = allocator;
    self.behaviours = std.ArrayList(Behaviour).init(allocator);
    if (self.initial_behaviour) |initial_behaviour| {
        self.behaviours.append(initial_behaviour) catch errors.oom();
    }
}

pub fn deinit(self: *Self) void {
    self.behaviours.deinit();
}

pub fn isBored(self: *Self) bool {
    return self.behaviours.items.len == 0;
}

pub fn pushBehaviour(self: *Self, behaviour: Behaviour) void {
    self.behaviours.append(behaviour) catch errors.oom();
}

pub fn getCurrentBehaviour(self: *Self) *Behaviour {
    return &self.behaviours.items[self.behaviours.items.len - 1];
}

pub fn perform(self: *Self) void {
    if (self.isBored()) return;

    switch (self.getCurrentBehaviour().*) {
        .hostile => self.performHostile(),
        .confused => |*confusion| self.performConfusion(confusion),
    }
}

fn performHostile(self: *Self) void {
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
}

fn performConfusion(self: *Self, confusion: *Confusion) void {
    if (confusion.turns_remaining <= 0) {
        engine.message_log.print("The {s} is no longer confused.", .{self.entity.name}, colors.white);
        _ = self.behaviours.pop();
    } else {
        const Pos = struct { isize, isize };
        const direction = rng.choose(Pos, &[_]Pos{
            .{ -1, -1 },
            .{ 0, -1 },
            .{ 1, -1 },
            .{ -1, 0 },
            .{ 1, 0 },
            .{ -1, 1 },
            .{ 0, 1 },
            .{ 1, 1 },
        });
        confusion.turns_remaining -= 1;
        _ = actions.perform(actions.bump(direction[0], direction[1]), self.entity);
    }
}
