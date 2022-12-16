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
const procgen = @import("procgen.zig");
const testing = std.testing;
const Entity = types.Entity;
const Terminal = term.Terminal;
const Map = gamemap.Map;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var terminal: term.Terminal = undefined;

fn init(seed: u64) !void {
    var player = Entity{ .char = '@', .color = 0xFFFFFF };
    var npc = Entity{ .char = '@', .color = 0xFFFF00 };

    var map = try procgen.generateDungeon(.{
        .seed = seed,
        .map_width = 80,
        .map_height = 45,
        .room_max_size = 10,
        .room_min_size = 6,
        .max_rooms = 30,
        .player = &player,
        .allocator = gpa.allocator(),
    });

    try engine.init(.{
        .map = map,
        .player = player,
        .allocator = gpa.allocator(),
        .event_handler = input.EventHandler{},
    });

    npc.x = player.x + 2;
    npc.y = player.y;
    try engine.map.addEntity(npc.spawn());

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
    engine.handleEvent(.{ .keydown = key });
}

export fn onPointerMove(x: isize, y: isize) void {
    engine.handleEvent(.{ .pointermove = .{ .x = x, .y = y } });
}

export fn onPointerDown(x: isize, y: isize) void {
    engine.handleEvent(.{ .pointerdown = .{ .x = x, .y = y } });
}

/// Freestanding target needs a default log implementation.
pub fn log(comptime _: std.log.Level, comptime _: @Type(.EnumLiteral), comptime format: []const u8, args: anytype) void {
    utils.print(format, args);
}

test {
    _ = @import("colors.zig");
    _ = @import("map.zig");
}
