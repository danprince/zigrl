const std = @import("std");
const utils = @import("utils.zig");
const term = @import("term.zig");
const host = @import("host.zig");
const errors = @import("errors.zig");
const input = @import("input.zig");
const testing = std.testing;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var terminal: term.Terminal = undefined;
var event_handler = input.EventHandler{};
var player_x: isize = 0;
var player_y: isize = 0;

export fn onInit(seed: u32) void {
    utils.print("seed: {}", .{seed});
    terminal = term.Terminal.init(80, 50, gpa.allocator()) catch errors.crash("Could not initialize terminal");
    player_x = @intCast(isize, terminal.width / 2);
    player_y = @intCast(isize, terminal.height / 2);
    host.initTerm(terminal.width, terminal.height);
}

export fn onFrame() void {
    terminal.reset();
    var root_console = terminal.root();
    root_console.put(player_x, player_y, 0xFFFFFF, 0x000000, '@');
    host.flushTerm(terminal.buffer.ptr, terminal.buffer.len);
}

export fn onKeyDown(key: usize) void {
    utils.print("{d}\n", .{key});
    var maybe_action = event_handler.onKeyDown(key);
    utils.print("{any}\n", .{maybe_action});

    if (maybe_action) |action| switch (action) {
        .move => |move| {
            player_x += move.dx;
            player_y += move.dy;
        },
    };
}

export fn onPointerMove(x: isize, y: isize) void {
    _ = y;
    _ = x;
}

export fn onPointerDown(x: isize, y: isize) void {
    _ = y;
    _ = x;
}

/// Freestanding target needs a default log implementation.
pub fn log(comptime message_level: std.log.Level, comptime scope: @Type(.EnumLiteral), comptime format: []const u8, args: anytype) void {
    _ = scope;
    _ = message_level;
    utils.print(format, args);
}
