const std = @import("std");
const utils = @import("utils.zig");
const term = @import("term.zig");
const host = @import("host.zig");
const errors = @import("errors.zig");
const input = @import("input.zig");
const types = @import("types.zig");
const tiles = @import("tiles.zig");
const engine = @import("engine.zig");
const gamemap = @import("map.zig");
const entities = @import("entities.zig");
const procgen = @import("procgen.zig");
const registry = @import("registry.zig");
const testing = std.testing;
const Terminal = term.Terminal;
const Map = gamemap.Map;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var terminal: term.Terminal = undefined;

fn init(seed: u64) !void {
    try registry.init(gpa.allocator());

    var player = entities.player;

    var map = try procgen.generateDungeon(.{
        .seed = seed,
        .map_width = 80,
        .map_height = 45,
        .room_max_size = 10,
        .room_min_size = 6,
        .max_monsters_per_room = 2,
        .max_rooms = 30,
        .player = &player,
        .allocator = gpa.allocator(),
    });

    try engine.init(.{
        .player = player,
        .map = map,
        .event_handler = input.EventHandler{},
        .allocator = gpa.allocator(),
    });

    engine.updateFieldOfView();

    terminal = try Terminal.init(80, 50, gpa.allocator());
    host.initTerm(terminal.width, terminal.height);
}

export fn onInit(seed: u32) void {
    init(seed) catch errors.crash("Could not initialize game!");
}

export fn onFrame() void {
    terminal.reset();
    var root_console = terminal.root();
    engine.render(&root_console);
    host.flushTerm(terminal.buffer.ptr, terminal.buffer.len);
}

export fn onKeyDown(key: u8) void {
    engine.event_handler.handleEvent(.{ .keydown = key });
}

export fn onPointerMove(x: isize, y: isize) void {
    engine.event_handler.handleEvent(.{ .pointermove = .{ .x = x, .y = y } });
}

export fn onPointerDown(x: isize, y: isize) void {
    engine.event_handler.handleEvent(.{ .pointerdown = .{ .x = x, .y = y } });
}

/// Freestanding target needs a default log implementation.
pub fn log(comptime _: std.log.Level, comptime _: @Type(.EnumLiteral), comptime format: []const u8, args: anytype) void {
    utils.print(format, args);
}

test {
    _ = @import("colors.zig");
    _ = @import("map.zig");
}
