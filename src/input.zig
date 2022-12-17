const std = @import("std");
const actions = @import("actions.zig");
const engine = @import("engine.zig");
const term = @import("term.zig");
const utils = @import("utils.zig");
const colors = @import("colors.zig");
const types = @import("types.zig");
const Vec = types.Vec;
const Action = actions.Action;
const Console = term.Console;
const Entity = types.Entity;

const modifiers = struct {
    pub const shift = 1;
    pub const alt = 2;
    pub const ctrl = 4;
};

const keys = struct {
    // Arrow keys
    pub const left_arrow = 37;
    pub const up_arrow = 38;
    pub const right_arrow = 39;
    pub const down_arrow = 40;

    // Vi keys
    pub const h = 72; // W
    pub const j = 74; // S
    pub const k = 75; // N
    pub const l = 76; // E
    pub const y = 89; // NW
    pub const u = 85; // NE
    pub const b = 66; // SW
    pub const n = 78; // SE

    // Actions
    pub const a = 65; // Select 0
    pub const z = 91; // Select 26
    pub const g = 71; // Pickup
    pub const i = 73; // Use
    pub const d = 68; // Drop

    // Other keys
    pub const enter = 13;
    pub const shift = 16;
    pub const ctrl = 17;
    pub const alt = 18;
    pub const esc = 27;
    pub const space = 32;
    pub const period = 190;
    pub const slash = 191;
};

fn getMoveKey(key: u8) ?struct { isize, isize } {
    return switch (key) {
        keys.h, keys.left_arrow => .{ -1, 0 },
        keys.l, keys.right_arrow => .{ 1, 0 },
        keys.k, keys.up_arrow => .{ 0, -1 },
        keys.j, keys.down_arrow => .{ 0, 1 },
        keys.y => .{ -1, -1 },
        keys.u => .{ 1, -1 },
        keys.b => .{ -1, 1 },
        keys.n => .{ 1, 1 },
        else => null,
    };
}

pub const InputEventType = enum {
    keydown,
    pointermove,
    pointerdown,
};

pub const InputEvent = union(InputEventType) {
    keydown: struct { key: u8, modifiers: u8 },
    pointermove: struct { x: isize, y: isize },
    pointerdown: struct { x: isize, y: isize },
};

pub const Mode = enum {
    main,
    gameover,
    drop_item,
    use_item,
    look,
    target_point,
    target_area,
};

pub const EventHandler = union(Mode) {
    const Self = @This();

    main: void,
    gameover: void,
    drop_item: void,
    use_item: void,
    look: void,
    target_point: struct { item: *Entity },
    target_area: struct { item: *Entity, radius: isize },

    fn dispatch(self: Self, event: InputEvent) ?Action {
        return switch (event) {
            .keydown => |key_event| self.onKeyDown(key_event.key, key_event.modifiers),
            .pointermove => |pos| self.onMouseMove(pos.x, pos.y),
            .pointerdown => |pos| self.onMouseDown(pos.x, pos.y),
        };
    }

    fn onMouseDown(self: Self, x: isize, y: isize) ?Action {
        switch (self) {
            .look, .target_point, .target_area => self.onSelectIndex(x, y),
            else => {},
        }
        return null;
    }

    fn onKeyDown(self: Self, key: u8, mod: u8) ?Action {
        if (key == keys.esc) {
            self.onExit();
            return null;
        }

        var action: ?Action = null;

        switch (self) {
            .main => switch (key) {
                keys.space, keys.period => action = actions.wait(),
                keys.g => action = actions.pickup(),
                keys.i => engine.event_handler = .use_item,
                keys.d => engine.event_handler = .drop_item,
                keys.slash => engine.event_handler = .look,
                else => if (getMoveKey(key)) |move| {
                    action = actions.bump(move[0], move[1]);
                },
            },
            .drop_item, .use_item => switch (key) {
                keys.a...keys.z => self.onSelectItem(key - keys.a),
                else => {},
            },
            .look, .target_point, .target_area => {
                switch (key) {
                    keys.enter => self.onSelectIndex(engine.mouse_location.x, engine.mouse_location.y),
                    keys.shift => {},
                    else => {
                        var speed: isize = 1;
                        if (mod & modifiers.shift > 0) speed *= 5;

                        if (getMoveKey(key)) |move| {
                            var x = engine.mouse_location.x;
                            var y = engine.mouse_location.y;
                            x += move[0] * speed;
                            y += move[1] * speed;
                            x = std.math.clamp(x, 0, engine.map.width - 1);
                            y = std.math.clamp(y, 0, engine.map.height - 1);
                            engine.mouse_location.x = x;
                            engine.mouse_location.y = y;
                        } else {
                            self.onExit();
                        }
                    },
                }
            },
            else => {},
        }

        return action;
    }

    fn onSelectItem(self: Self, index: usize) void {
        var action: ?Action = null;

        if (engine.player.inventory.?.getItemAtIndex(index)) |item| {
            switch (self) {
                .drop_item => action = actions.drop(item),
                .use_item => if (item.consumable) |consumable| {
                    action = consumable.getAction();
                },
                else => {},
            }
        } else {
            engine.message_log.add("Invalid entry.", colors.invalid);
        }

        if (action != null) {
            if (self.handleAction(action.?)) {
                engine.event_handler = .main;
            }
        }
    }

    fn onExit(self: Self) void {
        switch (self) {
            .main => {},
            .gameover => {},
            else => engine.event_handler = .main,
        }
    }

    fn onSelectIndex(self: Self, x: isize, y: isize) void {
        switch (self) {
            .target_point => |target| {
                _ = actions.perform(actions.useAtTarget(target.item, x, y), &engine.player);
            },
            .target_area => |target| {
                _ = actions.perform(actions.useAtTarget(target.item, x, y), &engine.player);
            },
            else => {},
        }

        self.onExit();
    }

    fn onMouseMove(_: Self, x: isize, y: isize) ?Action {
        engine.mouse_location.x = x;
        engine.mouse_location.y = y;
        return null;
    }

    pub fn handleEvent(self: Self, event: InputEvent) void {
        if (self.dispatch(event)) |action| {
            _ = self.handleAction(action);
        }
    }

    fn handleAction(_: Self, action: Action) bool {
        const result = actions.perform(action, &engine.player);

        switch (result) {
            .failure => |msg| {
                engine.message_log.print("{s}", .{msg}, colors.impossible);
                return false;
            },
            .success => {
                engine.handleEnemyTurns();
                engine.updateRenderOrder();
                engine.updateFieldOfView();
                return true;
            },
        }
    }

    pub fn render(self: Self, console: *Console) void {
        switch (self) {
            .drop_item => self.renderItemSelection(console, "Drop which item?"),
            .use_item => self.renderItemSelection(console, "Use which item?"),
            .look, .target_point, .target_area => self.renderTargeting(console),
            else => self.renderGameView(console),
        }
    }

    fn renderGameView(_: Self, console: *Console) void {
        engine.render(console);
    }

    fn renderItemSelection(self: Self, console: *Console, title: []const u8) void {
        self.renderGameView(console);
        const inventory = engine.player.inventory.?;
        const number_of_items_in_inventory = inventory.items.items.len;
        var x: isize = 40;
        var y: isize = 0;
        if (engine.player.x > 30) x = 0;
        const width = @intCast(isize, title.len + 4);
        var height = @intCast(isize, number_of_items_in_inventory + 2);
        if (height < 3) height = 3;
        console.box(x, y, width, height, colors.white, colors.black);
        console.write(x + 1, y, colors.black, colors.white, title);

        if (number_of_items_in_inventory > 0) {
            for (inventory.items.items) |item, index| {
                const i = @intCast(isize, index);
                const key = 'a' + @intCast(u8, index);
                console.print(x + 1, y + 1 + i, colors.white, null, "({c}) {s}", .{ key, item.name });
            }
        } else {
            console.write(x + 1, y + 1, colors.white, null, "(Empty)");
        }
    }

    fn renderTargeting(self: Self, console: *Console) void {
        self.renderGameView(console);
        const x = engine.mouse_location.x;
        const y = engine.mouse_location.y;
        switch (self) {
            .target_point => {
                const cell = console.get(x, y);
                console.put(x, y, colors.black, colors.white, cell.ch);
            },
            .target_area => |target| {
                console.box(x - target.radius, y - target.radius, target.radius * 2, target.radius * 2, colors.red, null);
            },
            else => {},
        }
    }
};
