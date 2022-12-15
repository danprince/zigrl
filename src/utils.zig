const std = @import("std");
const host = @import("host.zig");
const testing = std.testing;

var fmt_buffer: [1024]u8 = undefined;

/// Equivalent to std.debug.print except it prints the string to the browser's
/// console instead of to stdout. This function uses a fixed 1KB buffer so that
/// the caller doesn't have to worry about memory allocations. Larger strings
/// will be trimmed.
pub fn print(comptime fmt: []const u8, args: anytype) void {
    const str = std.fmt.bufPrint(&fmt_buffer, fmt, args) catch &fmt_buffer;
    host.print(str.ptr, str.len);
}

const BresenhamIterator = struct {
    x0: isize,
    y0: isize,
    x1: isize,
    y1: isize,

    dx: isize,
    dy: isize,
    sx: isize,
    sy: isize,

    x: isize,
    y: isize,
    err: isize,
    iterations: usize = 0,

    pub fn init(x0: isize, y0: isize, x1: isize, y1: isize) BresenhamIterator {
        const dx = x1 - x0;
        const dy = y1 - y0;
        return .{
            .x0 = x0,
            .y0 = y0,
            .x1 = x1,
            .y1 = y1,

            .dx = std.math.absInt(dx) catch unreachable,
            .dy = std.math.absInt(dy) catch unreachable,
            .sx = std.math.sign(dx),
            .sy = std.math.sign(dy),

            .x = x0,
            .y = y0,
            .err = 0,
        };
    }

    const Step = struct { x: isize, y: isize };

    pub fn next(self: *BresenhamIterator) ?Step {
        if (self.dx == 0 and self.dy == 0) return null;
        if (self.iterations > 1000) return null;
        self.iterations += 1;

        var point = Step{ .x = self.x, .y = self.y };

        if (self.dx > self.dy) {
            if ((self.sx < 0 and self.x >= self.x1) or (self.sx >= 0 and self.x <= self.x1)) {
                self.err += self.dy;
                self.x += self.sx;
                if (self.err * 2 >= self.dx) {
                    self.y += self.sy;
                    self.err -= self.dx;
                }
                return point;
            }
        } else {
            if ((self.sy < 0 and self.y >= self.y1) or (self.sy >= 0 and self.y <= self.y1)) {
                self.err += self.dx;
                self.y += self.sy;
                if (self.err * 2 >= self.dy) {
                    self.x += self.sx;
                    self.err -= self.dy;
                }
                return point;
            }
        }

        return null;
    }
};

pub const bresenham = BresenhamIterator.init;

test "bresenhams empty line" {
    var iter = bresenham(0, 0, 0, 0);
    try testing.expectEqual(iter.next(), null);
}

test "bresenhams horizontal line" {
    var iter = bresenham(0, 0, 3, 0);
    try testing.expectEqual(iter.next(), .{ .x = 0, .y = 0 });
    try testing.expectEqual(iter.next(), .{ .x = 1, .y = 0 });
    try testing.expectEqual(iter.next(), .{ .x = 2, .y = 0 });
    try testing.expectEqual(iter.next(), .{ .x = 3, .y = 0 });
    try testing.expectEqual(iter.next(), null);
}

test "bresenhams horizontal line backwards" {
    var iter = bresenham(3, 0, 0, 0);
    try testing.expectEqual(iter.next(), .{ .x = 3, .y = 0 });
    try testing.expectEqual(iter.next(), .{ .x = 2, .y = 0 });
    try testing.expectEqual(iter.next(), .{ .x = 1, .y = 0 });
    try testing.expectEqual(iter.next(), .{ .x = 0, .y = 0 });
    try testing.expectEqual(iter.next(), null);
}

test "bresenhams vertical line" {
    var iter = bresenham(0, 0, 0, 3);
    try testing.expectEqual(iter.next(), .{ .x = 0, .y = 0 });
    try testing.expectEqual(iter.next(), .{ .x = 0, .y = 1 });
    try testing.expectEqual(iter.next(), .{ .x = 0, .y = 2 });
    try testing.expectEqual(iter.next(), .{ .x = 0, .y = 3 });
    try testing.expectEqual(iter.next(), null);
}

test "bresenhams vertical line backwards" {
    var iter = bresenham(0, 3, 0, 0);
    try testing.expectEqual(iter.next(), .{ .x = 0, .y = 3 });
    try testing.expectEqual(iter.next(), .{ .x = 0, .y = 2 });
    try testing.expectEqual(iter.next(), .{ .x = 0, .y = 1 });
    try testing.expectEqual(iter.next(), .{ .x = 0, .y = 0 });
    try testing.expectEqual(iter.next(), null);
}

test "bresenhams equal step diagonal" {
    var iter = bresenham(0, 0, 3, 3);
    try testing.expectEqual(iter.next(), .{ .x = 0, .y = 0 });
    try testing.expectEqual(iter.next(), .{ .x = 1, .y = 1 });
    try testing.expectEqual(iter.next(), .{ .x = 2, .y = 2 });
    try testing.expectEqual(iter.next(), .{ .x = 3, .y = 3 });
    try testing.expectEqual(iter.next(), null);
}

test "bresenhams equal step diagonal backwards" {
    var iter = bresenham(3, 3, 0, 0);
    try testing.expectEqual(iter.next(), .{ .x = 3, .y = 3 });
    try testing.expectEqual(iter.next(), .{ .x = 2, .y = 2 });
    try testing.expectEqual(iter.next(), .{ .x = 1, .y = 1 });
    try testing.expectEqual(iter.next(), .{ .x = 0, .y = 0 });
    try testing.expectEqual(iter.next(), null);
}

test "bresenhams double step diagonal" {
    var iter = bresenham(0, 0, 7, 3);
    try testing.expectEqual(iter.next(), .{ .x = 0, .y = 0 });
    try testing.expectEqual(iter.next(), .{ .x = 1, .y = 0 });
    try testing.expectEqual(iter.next(), .{ .x = 2, .y = 1 });
    try testing.expectEqual(iter.next(), .{ .x = 3, .y = 1 });
    try testing.expectEqual(iter.next(), .{ .x = 4, .y = 2 });
    try testing.expectEqual(iter.next(), .{ .x = 5, .y = 2 });
    try testing.expectEqual(iter.next(), .{ .x = 6, .y = 3 });
    try testing.expectEqual(iter.next(), .{ .x = 7, .y = 3 });
    try testing.expectEqual(iter.next(), null);
}
