const std = @import("std");
const utils = @import("utils.zig");
const term = @import("term.zig");
const host = @import("host.zig");
const errors = @import("errors.zig");
const testing = std.testing;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var terminal: term.Terminal = undefined;

export fn onInit(seed: u32) void {
    utils.print("seed: {}", .{seed});
    terminal = term.Terminal.init(80, 50, gpa.allocator()) catch errors.crash("Could not initialize terminal");
    host.initTerm(terminal.width, terminal.height);
}

export fn onFrame() void {
    terminal.reset();
    host.flushTerm(terminal.buffer.ptr, terminal.buffer.len);
}

export fn onKeyDown(key: usize, modifiers: u8) void {
    _ = modifiers;
    _ = key;
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
