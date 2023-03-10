const std = @import("std");
const host = @import("host.zig");
const types = @import("types.zig");
const Vec = types.Vec;
const testing = std.testing;

var fmt_buffer: [1024]u8 = undefined;

const PrintLevel = enum { info, log, warn, err };

/// Print a message to the browser's console using Zig's std.fmt syntax.
/// Specify a log level explicitly to print as console.info/console.log etc.
///
/// This function uses a fixed 1KB buffer so that the caller doesn't have to
/// worry about memory allocations. Larger strings will be trimmed.
pub fn printWithLevel(comptime fmt: []const u8, args: anytype, level: PrintLevel) void {
    const str = std.fmt.bufPrint(&fmt_buffer, fmt, args) catch &fmt_buffer;
    host.print(str.ptr, str.len, @enumToInt(level));
}

/// Equivalent to std.debug.print except it prints the string to the browser's
/// console instead of to stdout. See `printWithLevel` for more options.
///
/// This function uses a fixed 1KB buffer so that the caller doesn't have to
/// worry about memory allocations. Larger strings will be trimmed.
pub fn print(comptime fmt: []const u8, args: anytype) void {
    printWithLevel(fmt, args, .log);
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

    pub fn next(self: *BresenhamIterator) ?Vec {
        if (self.dx == 0 and self.dy == 0) return null;
        if (self.iterations > 1000) return null;
        self.iterations += 1;

        var point = Vec{ .x = self.x, .y = self.y };

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

/// A data structure for holding a set of unique 2d coordinates (isize, isize).
pub const PointSet = struct {
    width: isize,
    height: isize,
    points: std.DynamicBitSet,
    allocator: std.mem.Allocator,

    pub fn init(width: usize, height: usize, allocator: std.mem.Allocator) !PointSet {
        return .{
            .width = @intCast(isize, width),
            .height = @intCast(isize, height),
            .allocator = allocator,
            .points = try std.DynamicBitSet.initEmpty(allocator, width * height),
        };
    }

    pub fn deinit(self: *PointSet) void {
        self.points.deinit();
    }

    /// Translate x, y into an index that can be used with the internal bit set.
    fn index(self: *PointSet, x: isize, y: isize) usize {
        return @intCast(usize, x + y * self.width);
    }

    /// Remove all points from the set.
    pub fn clear(self: *PointSet) void {
        var i: usize = 0;
        while (i < self.points.capacity()) : (i += 1) {
            self.points.unset(i);
        }
    }

    /// Add all possible points to the set.
    pub fn fill(self: *PointSet) void {
        var i: usize = 0;
        while (i < self.points.capacity()) : (i += 1) {
            self.points.set(i);
        }
    }

    /// Remove a point from the set.
    pub fn remove(self: *PointSet, x: isize, y: isize) void {
        const i = self.index(x, y);
        self.points.unset(i);
    }

    /// Add a point to the set.
    pub fn add(self: *PointSet, x: isize, y: isize) void {
        const i = self.index(x, y);
        self.points.set(i);
    }

    /// Check whether the set contains a point.
    pub fn has(self: *PointSet, x: isize, y: isize) bool {
        const i = self.index(x, y);
        return self.points.isSet(i);
    }

    /// Count the number of points currently set.
    pub fn count(self: *PointSet) usize {
        return self.points.count();
    }
};

test "PointSet" {
    var points = try PointSet.init(10, 10, testing.allocator);
    defer points.deinit();

    try testing.expectEqual(points.count(), 0);
    try testing.expect(!points.has(0, 0));

    points.add(1, 2);
    try testing.expectEqual(points.count(), 1);
    try testing.expect(points.has(1, 2));

    points.remove(1, 2);
    try testing.expectEqual(points.count(), 0);
    try testing.expect(!points.has(1, 2));

    points.add(1, 1);
    points.add(2, 2);
    points.add(3, 3);
    points.add(3, 3);
    try testing.expectEqual(points.count(), 3);

    points.clear();
    try testing.expectEqual(points.count(), 0);
    try testing.expect(!points.has(1, 1));
    try testing.expect(!points.has(2, 2));
    try testing.expect(!points.has(3, 3));

    points.fill();
    try testing.expectEqual(points.count(), 100);
    try testing.expect(points.has(1, 1));
    try testing.expect(points.has(2, 2));
    try testing.expect(points.has(3, 3));
}

/// Returns an iterator that wraps text into lines of at most `max_width`
/// characters, attempting to break on the last space in each line.
pub fn textWrap(text: []const u8, max_width: usize) TextWrapIterator {
    return .{
        .text = text,
        .max_width = max_width,
    };
}

const TextWrapIterator = struct {
    text: []const u8,
    max_width: usize,
    line_width: usize = 0,

    pub fn next(self: *TextWrapIterator) ?[]const u8 {
        if (self.text.len == 0) return null;
        if (self.text[0] == ' ') self.text = self.text[1..];
        var end = std.math.min(self.max_width, self.text.len);
        var line = self.text[0..end];

        // Break overflowing words at the last space
        if (line.len == self.max_width) {
            var last_space = std.mem.lastIndexOfScalar(u8, line, ' ');
            if (last_space) |last_space_index| {
                line = line[0..last_space_index];
            }
        }

        self.text = self.text[line.len..];
        return line;
    }
};

test "textWrap" {
    const cases = [_]struct {
        max_width: usize,
        actual: []const u8,
        expect: []const u8,
    }{
        .{
            .max_width = 15,
            .actual = "hello world these are lines",
            .expect = 
            \\hello world
            \\these are
            \\lines
            ,
        },
        .{
            .max_width = 15,
            .actual = "hello astronomical body these are lines",
            .expect = 
            \\hello
            \\astronomical
            \\body these are
            \\lines
            ,
        },
        .{
            .max_width = 8,
            .actual = "hello gargantuous world",
            .expect = 
            \\hello
            \\gargantu
            \\ous
            \\world
            ,
        },
        .{
            .max_width = 40,
            .actual = "Hello and welcome, adventurer, to yet another dungeon!",
            .expect = 
            \\Hello and welcome, adventurer, to yet
            \\another dungeon!
            ,
        },
        .{
            .max_width = 40,
            .actual = "Hello and welcome, adventurer, to yet another dungeon! This is a really obnoxiously long message.",
            .expect = 
            \\Hello and welcome, adventurer, to yet
            \\another dungeon! This is a really
            \\obnoxiously long message.
            ,
        },
    };

    for (cases) |case| {
        var actual_iter = textWrap(case.actual, case.max_width);
        var expect_iter = std.mem.tokenize(u8, case.expect, "\n");
        while (expect_iter.next()) |expect_line| {
            var actual_line = actual_iter.next().?;
            try testing.expectEqualStrings(actual_line, expect_line);
        }
        try testing.expectEqual(actual_iter.next(), null);
    }
}
