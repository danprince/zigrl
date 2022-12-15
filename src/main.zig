const std = @import("std");
const utils = @import("utils.zig");
const term = @import("term.zig");
const host = @import("host.zig");
const errors = @import("errors.zig");
const input = @import("input.zig");
const types = @import("types.zig");
const engine = @import("engine.zig");
const testing = std.testing;
const Entity = types.Entity;
const Terminal = term.Terminal;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var terminal: term.Terminal = undefined;

export fn onInit() void {
    terminal = Terminal.init(80, 50, gpa.allocator()) catch errors.crash("Could not initialize terminal");
    const event_handler = input.EventHandler{};
    const player = Entity{
        .char = '@',
        .color = 0xFFFFFF,
        .x = @intCast(isize, terminal.width / 2),
        .y = @intCast(isize, terminal.height / 2),
    };
    engine.init(event_handler, player) catch errors.crash("Could not initialize engine!");
    host.initTerm(terminal.width, terminal.height);
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
