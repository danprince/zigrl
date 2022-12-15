const types = @import("types.zig");
const engine = @import("engine.zig");
const Entity = types.Entity;

pub const ActionType = enum {
    move,
};

pub const Action = union(ActionType) {
    move: struct { dx: isize, dy: isize },
};

pub fn move(dx: isize, dy: isize) Action {
    return .{ .move = .{ .dx = dx, .dy = dy } };
}

pub fn perform(action: Action, entity: *Entity) void {
    switch (action) {
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

            entity.move(movement.dx, movement.dy);
        },
    }
}
