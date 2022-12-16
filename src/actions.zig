const types = @import("types.zig");
const engine = @import("engine.zig");
const utils = @import("utils.zig");
const colors = @import("colors.zig");
const Entity = types.Entity;

pub const ActionType = enum {
    wait,
    move,
    melee,
    bump,
};

pub const Action = union(ActionType) {
    wait: void,
    move: struct { dx: isize, dy: isize },
    melee: struct { dx: isize, dy: isize },
    bump: struct { dx: isize, dy: isize },
};

pub fn wait() Action {
    return .{ .wait = {} };
}

pub fn move(dx: isize, dy: isize) Action {
    return .{ .move = .{ .dx = dx, .dy = dy } };
}

pub fn melee(dx: isize, dy: isize) Action {
    return .{ .melee = .{ .dx = dx, .dy = dy } };
}

pub fn bump(dx: isize, dy: isize) Action {
    return .{ .bump = .{ .dx = dx, .dy = dy } };
}

pub fn perform(action: Action, entity: *Entity) void {
    switch (action) {
        .wait => {},
        .move => |movement| {
            const dest_x = entity.x + movement.dx;
            const dest_y = entity.y + movement.dy;

            if (!engine.map.inBounds(dest_x, dest_y)) {
                return; // Destination is out of bounds.
            }

            const tile = engine.map.getTile(dest_x, dest_y);

            if (!tile.walkable) {
                return; // Destination is blocked by a tile.
            }

            if (engine.map.getBlockingEntityAt(dest_x, dest_y) != null) {
                return; // Destination is blocked by an entity
            }

            entity.move(movement.dx, movement.dy);
        },
        .melee => |movement| {
            const dest_x = entity.x + movement.dx;
            const dest_y = entity.y + movement.dy;
            const target_or_null = engine.map.getBlockingEntityAt(dest_x, dest_y);
            if (target_or_null) |target| {
                if (entity.fighter) |*entity_fighter| {
                    if (target.fighter) |*target_fighter| {
                        const max_damage = entity_fighter.power - target_fighter.defense;
                        const damage = target_fighter.damage(max_damage);
                        const color = if (entity == &engine.player) colors.player_atk else colors.enemy_atk;

                        if (damage > 0) {
                            engine.message_log.print("{s} attacks {s} for {d} hit points.", .{ entity.name, target.name, damage }, color);
                        } else {
                            engine.message_log.print("{s} attacks {s} but does no damage.", .{ entity.name, target.name }, color);
                        }
                    }
                }
            }
        },
        .bump => |movement| {
            const dest_x = entity.x + movement.dx;
            const dest_y = entity.y + movement.dy;
            const target_or_null = engine.map.getBlockingEntityAt(dest_x, dest_y);

            if (target_or_null) |_| {
                return perform(melee(movement.dx, movement.dy), entity);
            } else {
                return perform(move(movement.dx, movement.dy), entity);
            }
        },
    }
}
