const std = @import("std");
const utils = @import("utils.zig");
const term = @import("term.zig");
const rng = @import("rng.zig");
const host = @import("host.zig");
const errors = @import("errors.zig");
const types = @import("types.zig");
const tiles = @import("tiles.zig");
const engine = @import("engine.zig");
const gamemap = @import("map.zig");
const entities = @import("entities.zig");
const procgen = @import("procgen.zig");
const colors = @import("colors.zig");
const Handler = @import("handler.zig");
const testing = std.testing;
const Terminal = term.Terminal;
const Map = gamemap.Map;
const World = gamemap.World;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var terminal: term.Terminal = undefined;

fn init(seed: u64) !void {
    rng.init(seed);

    try engine.init(.{
        .player = entities.player,
        .handler = .{ .mode = .main },
        .allocator = gpa.allocator(),
    });

    engine.world = World.init(.{
        .seed = seed,
        .map_width = 80,
        .map_height = 43,
        .room_max_size = 10,
        .room_min_size = 6,
        .max_monsters_per_room = 2,
        .max_items_per_room = 2,
        .max_rooms = 30,
        .allocator = gpa.allocator(),
    });

    engine.map = engine.world.generateFloor();
    engine.updateFieldOfView();

    const player_equipment = &engine.player.equipment.?;
    const player_inventory = &engine.player.inventory.?;

    const dagger = entities.dagger.spawn();
    player_inventory.add(dagger);
    player_equipment.toggleEquip(dagger);

    const leather_armor = entities.leather_armor.spawn();
    player_inventory.add(leather_armor);
    player_equipment.toggleEquip(leather_armor);

    engine.message_log.active = true;
    engine.message_log.add(
        "Hello and welcome, adventurer, to yet another dungeon!",
        colors.welcome_text,
    );

    terminal = try Terminal.init(80, 50, gpa.allocator());
    host.initTerm(terminal.width, terminal.height);
}

export fn onInit(seed: u32) void {
    init(seed) catch errors.crash("Could not initialize game!");
}

export fn onFrame() void {
    terminal.reset();
    var root_console = terminal.root();
    engine.handler.render(&root_console);
    host.flushTerm(terminal.buffer.ptr, terminal.buffer.len);
}

export fn onKeyDown(key: u8, modifiers: u8) void {
    engine.handler.handleEvent(.{ .keydown = .{ .key = key, .modifiers = modifiers } });
}

export fn onPointerMove(x: isize, y: isize) void {
    engine.handler.handleEvent(.{ .pointermove = .{ .x = x, .y = y } });
}

export fn onPointerDown(x: isize, y: isize) void {
    engine.handler.handleEvent(.{ .pointerdown = .{ .x = x, .y = y } });
}

/// Freestanding target needs a default log implementation.
pub fn log(comptime _: std.log.Level, comptime _: @Type(.EnumLiteral), comptime format: []const u8, args: anytype) void {
    utils.print(format, args);
}

/// Default panic handler also prints to the message log for the player.
pub fn panic(msg: []const u8, trace: ?*std.builtin.StackTrace, ret_addr: ?usize) noreturn {
    engine.message_log.print("Error: {s}", .{msg}, colors.errors);
    std.builtin.default_panic(msg, trace, ret_addr);
}

test {
    _ = @import("colors.zig");
    _ = @import("map.zig");
    _ = @import("rng.zig");
}
