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
const testing = std.testing;
const Entity = types.Entity;
const Terminal = term.Terminal;
const Map = gamemap.Map;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var terminal: term.Terminal = undefined;

fn init() !void {
    const player = Entity{
        .char = '@',
        .color = 0xFFFFFF,
        .x = @intCast(isize, terminal.width / 2),
        .y = @intCast(isize, terminal.height / 2),
    };
    const event_handler = input.EventHandler{};
    var map = try Map.init(80, 45, tiles.floor, gpa.allocator());
    map.setTile(30, 22, tiles.wall);
    try engine.init(event_handler, map, player);
    terminal = try Terminal.init(80, 50, gpa.allocator());
    host.initTerm(terminal.width, terminal.height);
}

export fn onInit() void {
    init() catch errors.crash("Could not initialize game!");
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
