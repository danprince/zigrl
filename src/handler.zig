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
    pub const v = 86; // History

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

const ScrollView = struct { scroll_y: isize = 0 };

pub const ModeType = enum {
    main,
    gameover,
    drop_item,
    use_item,
    look,
    target_point,
    target_area,
    history,
};

pub const Mode = union(ModeType) {
    main: void,
    gameover: void,
    drop_item: void,
    use_item: void,
    look: void,
    target_point: struct { item: *Entity },
    target_area: struct { item: *Entity, radius: isize },
    history: ScrollView,
};

const EventResultType = enum { action, mode };

/// An event result is the possible outcome of any given input event.
/// It can either be an action to process for the player, or a mode to switch
/// into for the current handler.
const EventResult = union(EventResultType) {
    action: Action,
    mode: Mode,
};

/// Helper for creating action event results.
fn act(action: Action) EventResult {
    return .{ .action = action };
}

/// Helper for creating mode change event results.
fn swap(mode: Mode) EventResult {
    return .{ .mode = mode };
}

const Self = @This();

mode: Mode,

/// Triggers a game action, if possible, given an input event.
pub fn handleEvent(self: *Self, event: InputEvent) void {
    if (self.dispatch(event)) |action_or_mode| {
        switch (action_or_mode) {
            .action => |action| _ = self.handleAction(action),
            .mode => |new_mode| self.mode = new_mode,
        }
    }
}

/// Process an action for the player. Returns true if the action was successful
/// and false if it failed.
fn handleAction(_: *Self, action: Action) bool {
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

/// Takes an input event and turns it into an EventResult using the appropriate
/// event callbacks.
fn dispatch(self: *Self, event: InputEvent) ?EventResult {
    return switch (event) {
        .keydown => |key_event| self.onKeyDown(key_event.key, key_event.modifiers),
        .pointermove => |pos| self.onMouseMove(pos.x, pos.y),
        .pointerdown => |pos| self.onMouseDown(pos.x, pos.y),
    };
}

/// Called whenever the mouse is moved.
fn onMouseMove(_: *Self, x: isize, y: isize) ?EventResult {
    engine.mouse_location.x = x;
    engine.mouse_location.y = y;
    return null;
}

/// Called whenever the mouse goes down.
fn onMouseDown(self: *Self, x: isize, y: isize) ?EventResult {
    return switch (self.mode) {
        .look, .target_point, .target_area => self.onSelectIndex(x, y),
        else => null,
    };
}

/// Called whenever a key is pressed.
fn onKeyDown(self: *Self, key: u8, mod: u8) ?EventResult {
    switch (key) {
        // Ignore modifier keypresses in all modes.
        keys.shift, keys.alt, keys.ctrl => return null,
        // Esc is always considered as an attempt to exit.
        keys.esc => return self.onExit(),
        else => {},
    }

    return switch (self.mode) {
        .main => switch (key) {
            keys.space, keys.period => act(actions.wait()),
            keys.g => act(actions.pickup()),
            keys.i => swap(.use_item),
            keys.d => swap(.drop_item),
            keys.slash => swap(.look),
            keys.v => swap(.{ .history = .{} }),
            else => if (getMoveKey(key)) |move| {
                return act(actions.bump(move[0], move[1]));
            } else null,
        },
        .drop_item, .use_item => switch (key) {
            keys.a...keys.z => {
                self.onSelectItem(key - keys.a);
                return null;
            },
            else => null,
        },
        .look, .target_point, .target_area => switch (key) {
            keys.enter => self.onSelectIndex(engine.mouse_location.x, engine.mouse_location.y),
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
                    return null;
                }

                return self.onExit();
            },
        },
        .history => |*view| {
            if (getMoveKey(key)) |move| {
                view.scroll_y += move[1];
                if (view.scroll_y < 0) view.scroll_y = 0;
                return null;
            } else {
                return self.onExit();
            }
        },
        else => null,
    };
}

/// Called when the user attempts to exit the current handler mode.
fn onExit(self: *Self) ?EventResult {
    return switch (self.mode) {
        .main, .gameover => null,
        else => swap(.main),
    };
}

/// Called when the user selects an item from an item selection mode.
fn onSelectItem(self: *Self, index: usize) void {
    var action: ?Action = null;

    if (engine.player.inventory.?.getItemAtIndex(index)) |item| {
        switch (self.mode) {
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
            engine.handler.mode = .main;
        }
    }
}

/// Called when the the user selects an index as part of a targeting mode.
fn onSelectIndex(self: *Self, x: isize, y: isize) ?EventResult {
    return switch (self.mode) {
        .target_point => |target| {
            var action = actions.useAtTarget(target.item, x, y);
            var result = self.handleAction(action);
            return if (result) self.onExit() else null;
        },
        .target_area => |target| {
            var action = actions.useAtTarget(target.item, x, y);
            var result = self.handleAction(action);
            return if (result) self.onExit() else null;
        },
        else => self.onExit(),
    };
}

/// Render the current handler's mode.
pub fn render(self: *Self, console: *Console) void {
    switch (self.mode) {
        .drop_item => self.renderItemSelection(console, "Drop which item?"),
        .use_item => self.renderItemSelection(console, "Use which item?"),
        .look, .target_point, .target_area => self.renderTargeting(console),
        .history => |*view| self.renderMessageHistory(console, view),
        else => self.renderGameView(console),
    }
}

fn renderGameView(_: *Self, console: *Console) void {
    engine.render(console);
}

fn renderMessageHistory(self: *Self, parent_console: *Console, view: *ScrollView) void {
    self.renderGameView(parent_console);

    var console = parent_console.centeredChild(60, parent_console.height - 5);
    var y_offset: isize = 1 - view.scroll_y;
    var x_offset: isize = 1;

    console.fillRect(0, 0, console.width, console.height, 0, 0, 0);

    for (engine.message_log.messages.items) |message| {
        var lines = utils.textWrap(message.text, @intCast(usize, console.width - 1));
        while (lines.next()) |line| {
            if (y_offset >= 0 and y_offset < console.height) {
                console.write(x_offset, y_offset, message.fg, null, line);
            }
            y_offset += 1;
        }
    }

    if (engine.message_log.messages.items.len == 0) {
        console.write(1, 1, colors.white, null, "(Empty)");
    }

    console.box(0, 0, console.width, console.height, 0xFFFFFF, null);
    console.write(1, 0, colors.white, null, "Messages");
    console.write(console.width - 15, 0, colors.white, null, "(Esc to close)");
}

fn renderItemSelection(self: *Self, console: *Console, title: []const u8) void {
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

fn renderTargeting(self: *Self, console: *Console) void {
    self.renderGameView(console);
    const x = engine.mouse_location.x;
    const y = engine.mouse_location.y;
    switch (self.mode) {
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
