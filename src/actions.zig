const types = @import("types.zig");
const engine = @import("engine.zig");
const utils = @import("utils.zig");
const colors = @import("colors.zig");
const Vec = types.Vec;
const Entity = types.Entity;

pub const ActionType = enum {
    wait,
    move,
    melee,
    bump,
    use,
    pickup,
    drop,
    equip,
    take_stairs,
};

pub const Action = union(ActionType) {
    wait: void,
    move: struct { dx: isize, dy: isize },
    melee: struct { dx: isize, dy: isize },
    bump: struct { dx: isize, dy: isize },
    use: struct { item: *Entity, target: ?Vec = null },
    pickup: void,
    drop: *Entity,
    equip: *Entity,
    take_stairs: void,
};

pub const ActionResultType = enum {
    success,
    failure,
};

pub const ActionResult = union(ActionResultType) {
    success: void,
    failure: []const u8,
};

pub fn success() ActionResult {
    return .{ .success = {} };
}

pub fn failure(message: []const u8) ActionResult {
    return .{ .failure = message };
}

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

pub fn use(item: *Entity) Action {
    return .{ .use = .{ .item = item } };
}

pub fn useAtTarget(item: *Entity, x: isize, y: isize) Action {
    return .{ .use = .{ .item = item, .target = .{ .x = x, .y = y } } };
}

pub fn pickup() Action {
    return .{ .pickup = {} };
}

pub fn drop(item: *Entity) Action {
    return .{ .drop = item };
}

pub fn equip(item: *Entity) Action {
    return .{ .equip = item };
}

pub fn takeStairs() Action {
    return .{ .take_stairs = {} };
}

pub fn perform(any_action: Action, entity: *Entity) ActionResult {
    return switch (any_action) {
        .wait => success(),
        .move => |movement| {
            const dest_x = entity.x + movement.dx;
            const dest_y = entity.y + movement.dy;

            if (!engine.map.inBounds(dest_x, dest_y)) {
                return failure("That way is blocked.");
            }

            const tile = engine.map.getTile(dest_x, dest_y);

            if (!tile.walkable) {
                return failure("That way is blocked.");
            }

            if (engine.map.getBlockingEntityAt(dest_x, dest_y) != null) {
                return failure("That way is blocked.");
            }

            entity.move(movement.dx, movement.dy);
            return success();
        },
        .melee => |movement| {
            const dest_x = entity.x + movement.dx;
            const dest_y = entity.y + movement.dy;
            const target_or_null = engine.map.getBlockingEntityAt(dest_x, dest_y);

            if (target_or_null) |target| {
                if (entity.fighter) |*entity_fighter| {
                    if (target.fighter) |*target_fighter| {
                        const damage = entity_fighter.power() - target_fighter.defense();
                        const color = if (entity == &engine.player) colors.player_atk else colors.enemy_atk;

                        if (damage > 0) {
                            engine.message_log.print("{s} attacks {s} for {d} hit points.", .{ entity.name, target.name, damage }, color);
                        } else {
                            engine.message_log.print("{s} attacks {s} but does no damage.", .{ entity.name, target.name }, color);
                        }

                        _ = target_fighter.damage(damage);
                        return success();
                    }
                }
            }

            return failure("Nothing to attack.");
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
        .use => |action| {
            if (action.item.consumable) |*consumable| {
                return consumable.activate(entity, action.target);
            } else {
                return failure("You can't use this");
            }
        },
        .pickup => {
            while (entity.inventory) |*inventory| {
                while (!inventory.isFull()) {
                    var item_or_null = engine.map.getItemAt(entity.x, entity.y);
                    if (item_or_null) |item| {
                        inventory.add(item);
                        engine.map.removeEntity(item);
                        engine.message_log.print("You picked up the {s}.", .{item.name}, colors.white);
                        return success();
                    } else {
                        return failure("There is nothing here to pickup");
                    }
                } else {
                    return failure("Your inventory is full.");
                }
            } else {
                return failure("You don't have anywhere to put that!");
            }
        },
        .drop => |item| {
            if (entity.inventory) |*inventory| {
                if (entity.equipment) |*equipment| {
                    if (equipment.isItemEquipped(item)) {
                        equipment.toggleEquip(item);
                    }
                }

                inventory.drop(item);
                return success();
            } else return failure("You aren't holding that!");
        },
        .equip => |item| {
            if (entity.equipment) |*equipment| {
                equipment.toggleEquip(item);
                return success();
            } else return failure("You can't equip that");
        },
        .take_stairs => {
            if (engine.player.x == engine.map.downstairs_location.x and engine.player.y == engine.map.downstairs_location.y) {
                engine.map.deinit();
                engine.map = engine.world.generateFloor();
                engine.message_log.add("You descend the staircase.", colors.descend);
                return success();
            } else {
                return failure("There are no stairs here.");
            }
        },
    };
}
