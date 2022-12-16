const actions = @import("actions.zig");
const Action = actions.Action;

const keys = struct {
    pub const left_arrow = 37;
    pub const up_arrow = 38;
    pub const right_arrow = 39;
    pub const down_arrow = 40;
};

pub const InputEventType = enum {
    keydown,
    pointermove,
    pointerdown,
};

pub const InputEvent = union(InputEventType) {
    keydown: u8,
    pointermove: struct { x: isize, y: isize },
    pointerdown: struct { x: isize, y: isize },
};

pub const EventHandler = struct {
    const Self = @This();

    pub fn dispatch(_: *Self, event: InputEvent) ?Action {
        return switch (event) {
            .keydown => |key| switch (key) {
                keys.left_arrow => actions.bump(-1, 0),
                keys.right_arrow => actions.bump(1, 0),
                keys.up_arrow => actions.bump(0, -1),
                keys.down_arrow => actions.bump(0, 1),
                else => null,
            },
            else => null,
        };
    }
};
