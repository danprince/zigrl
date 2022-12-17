const actions = @import("actions.zig");
const engine = @import("engine.zig");
const term = @import("term.zig");
const utils = @import("utils.zig");
const colors = @import("colors.zig");
const Action = actions.Action;
const Console = term.Console;

const keys = struct {
    // Arrow keys
    pub const left_arrow = 37;
    pub const up_arrow = 38;
    pub const right_arrow = 39;
    pub const down_arrow = 40;

    // Vi keys
    pub const h = 72;
    pub const j = 74;
    pub const k = 75;
    pub const l = 76;
    pub const y = 89;
    pub const u = 85;
    pub const b = 66;
    pub const n = 78;

    // Other keys
    pub const space = 32;
    pub const period = 190;
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

pub const Mode = enum { main, gameover };

pub const EventHandler = union(Mode) {
    const Self = @This();

    main: void,
    gameover: void,

    fn dispatch(self: Self, event: InputEvent) ?Action {
        return switch (event) {
            .keydown => |key| self.onKeyDown(key),
            .pointermove => |pos| self.onMouseMove(pos.x, pos.y),
            else => null,
        };
    }

    fn onKeyDown(self: Self, key: usize) ?Action {
        return switch (self) {
            .main => switch (key) {
                keys.space, keys.period => actions.wait(),
                keys.h, keys.left_arrow => actions.bump(-1, 0),
                keys.l, keys.right_arrow => actions.bump(1, 0),
                keys.k, keys.up_arrow => actions.bump(0, -1),
                keys.j, keys.down_arrow => actions.bump(0, 1),
                keys.y => actions.bump(-1, -1),
                keys.u => actions.bump(1, -1),
                keys.b => actions.bump(-1, 1),
                keys.n => actions.bump(1, 1),
                else => null,
            },
            else => null,
        };
    }

    fn onMouseMove(_: Self, x: isize, y: isize) ?Action {
        engine.mouse_location.x = x;
        engine.mouse_location.y = y;
        return null;
    }

    pub fn handleEvent(self: Self, event: InputEvent) void {
        var maybe_action = self.dispatch(event);

        if (maybe_action) |action| {
            const result = actions.perform(action, &engine.player);

            switch (result) {
                .failure => |msg| {
                    engine.message_log.print("{s}", .{msg}, colors.impossible);
                },
                else => {
                    engine.handleEnemyTurns();
                    engine.updateRenderOrder();
                    engine.updateFieldOfView();
                },
            }
        }
    }

    pub fn render(self: Self, console: *Console) void {
        switch (self) {
            else => engine.render(console),
        }
    }
};
