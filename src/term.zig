const std = @import("std");
const testing = std.testing;

/// Terminals contains the raw character/color data for rendering.
pub const Terminal = struct {
    allocator: std.mem.Allocator,
    width: usize,
    height: usize,

    /// The buffer holds all of the terminal's character/color data in a single
    /// contiguous block of memory. i32 is used because it's the smallest value
    /// that can store 24 bit colors, and still keep the door open for negative
    /// values in future.
    ///
    /// | 'H' | 0xAABBCC | 0x112233 | 'e' | 0xCCBBAA | 0x332211 | ...
    ///  char   fg_color   bg_color   char  fg_color   bg_color
    buffer: []i32,

    /// The step required between each cell when iterating through the buffer.
    const buffer_step = 3;

    /// Creates a terminal with `width` columns and `height` rows.
    /// Deinitialize with `deinit`.
    pub fn init(width: usize, height: usize, allocator: std.mem.Allocator) !Terminal {
        if (width < 0 or height < 0) @panic("Terminal cannot have negative bounds");

        var term = Terminal{
            .width = width,
            .height = height,
            .buffer = try allocator.alloc(i32, width * height * buffer_step),
            .allocator = allocator,
        };

        term.reset();
        return term;
    }

    pub fn deinit(self: *Terminal) void {
        self.allocator.free(self.buffer);
    }

    /// Resets the contents of the terminal's buffer.
    pub fn reset(self: *Terminal) void {
        for (self.buffer) |*val| val.* = 0;
    }

    /// Put a character and a fg/bg color pair into a given cell in the
    /// terminal. If null values are provided for colors, the existing
    /// cell colors will be used instead.
    pub fn put(self: *Terminal, x: usize, y: usize, fg: ?i32, bg: ?i32, ch: u8) void {
        if (x >= self.width or y >= self.height) return;
        const index = (x + y * self.width) * buffer_step;
        self.buffer[index] = ch;
        if (fg) |color| self.buffer[index + 1] = color;
        if (bg) |color| self.buffer[index + 2] = color;
    }

    /// Creates a root console
    pub fn root(self: *Terminal) Console {
        return .{
            .terminal = self,
            .x = 0,
            .y = 0,
            .width = @intCast(isize, self.width),
            .height = @intCast(isize, self.height),
        };
    }

    /// Renders the current state of the terminal to a newline separated string
    /// that is helpful for testing. Allocates additional memory to build the
    /// string. Caller owns the returned string.
    pub fn toString(self: *const Terminal) ![]u8 {
        // Resulting string needs to account for newlines at the end of each
        // every row except the final one.
        const len = (self.width + 1) * self.height - 1;
        var buf = try self.allocator.alloc(u8, len);

        var y: usize = 0;
        while (y < self.height) : (y += 1) {
            var x: usize = 0;
            while (x < self.width) : (x += 1) {
                const idx = (x + y * self.width) * buffer_step;
                const ch = @intCast(u8, self.buffer[idx]);
                buf[x + y * self.width + y] = if (ch > 0) ch else ' ';
            }

            if (y + 1 < self.height) {
                buf[self.width + y * self.width + y] = '\n';
            }
        }

        return buf;
    }
};

/// A console is a cursor into a terminal that has a position, dimensions, and
/// clips when characters are written outside. Consoles should be obtained
/// by calling `terminal.root()`.
pub const Console = struct {
    x: isize,
    y: isize,
    width: isize,
    height: isize,
    terminal: *Terminal,

    /// Creates a subconsole inside this one.
    pub fn child(self: *const Console, x: isize, y: isize, width: isize, height: isize) Console {
        return .{ .terminal = self.terminal, .x = self.x + x, .y = self.y + y, .width = width, .height = height };
    }

    /// Check whether a given point falls inside this console.
    pub fn isInBounds(self: *const Console, x: isize, y: isize) bool {
        return x >= 0 and y >= 0 and x < self.width and y < self.height;
    }

    /// Put a colored character into the terminal's buffer at specific coordinates.
    pub fn put(self: *const Console, x: isize, y: isize, fg: ?i32, bg: ?i32, ch: u8) void {
        if (self.isInBounds(x, y)) {
            const term_x = self.x + x;
            const term_y = self.y + y;
            if (term_x < 0 or term_y < 0) return;
            self.terminal.put(@intCast(usize, term_x), @intCast(usize, term_y), fg, bg, ch);
        }
    }

    /// Write a colored string string into the console at specific coordinates.
    pub fn write(self: *const Console, x: isize, y: isize, fg: ?i32, bg: ?i32, str: []const u8) void {
        for (str) |ch, i| self.put(x + @intCast(isize, i), y, fg, bg, ch);
    }

    var fmt_buffer: [256]u8 = undefined;

    /// Write a colored string into the console using Zig's formatting syntax.
    /// Note that this function uses a fixed buffer for formatting and long
    /// results will be trimmed at 256 chars.
    pub fn print(self: *const Console, x: isize, y: isize, fg: ?i32, bg: ?i32, comptime fmt: []const u8, args: anytype) void {
        // If we run out of space in the buffer, print the entire buffer instead
        var string = std.fmt.bufPrint(&fmt_buffer, fmt, args) catch &fmt_buffer;
        self.write(x, y, fg, bg, string);
    }

    /// Fill a rectangle with a given colored character.
    pub fn fillRect(self: *const Console, x: isize, y: isize, w: isize, h: isize, fg: ?i32, bg: ?i32, ch: u8) void {
        var j: u8 = 0;
        while (j < h) : (j += 1) {
            var i: u8 = 0;
            while (i < w) : (i += 1) {
                self.put(x + i, y + j, fg, bg, ch);
            }
        }
    }
};

test "rendering to string" {
    var term = try Terminal.init(3, 3, testing.allocator);
    defer term.deinit();

    term.put(1, 1, 0, 0, '@');
    term.put(0, 0, 0, 0, 'A');
    term.put(2, 2, 0, 0, 'B');

    const output = try term.toString();
    defer testing.allocator.free(output);
    try testing.expectEqualStrings(
        \\A  
        \\ @ 
        \\  B
    , output);
}

test "root console" {
    var term = try Terminal.init(3, 3, testing.allocator);
    defer term.deinit();
    var root = term.root();
    root.put(1, 1, 0, 0, '@');

    const output = try term.toString();
    defer testing.allocator.free(output);
    try testing.expectEqualStrings(
        \\   
        \\ @ 
        \\   
    , output);
}

test "child consoles" {
    var term = try Terminal.init(5, 1, testing.allocator);
    defer term.deinit();
    var root = term.root();
    var console1 = root.child(1, 0, 1, 1);
    var console2 = root.child(3, 0, 1, 1);
    console1.put(0, 0, null, null, '1');
    console2.put(0, 0, null, null, '2');

    const output = try term.toString();
    defer testing.allocator.free(output);
    try testing.expectEqualStrings(" 1 2 ", output);
}

test "console write" {
    var term = try Terminal.init(5, 1, testing.allocator);
    defer term.deinit();
    term.root().write(0, 0, null, null, "Hello");

    const output = try term.toString();
    defer testing.allocator.free(output);
    try testing.expectEqualStrings("Hello", output);
}

test "console print" {
    var term = try Terminal.init(11, 1, testing.allocator);
    defer term.deinit();
    term.root().print(0, 0, null, null, "Hello {s}", .{"world"});

    const output = try term.toString();
    defer testing.allocator.free(output);
    try testing.expectEqualStrings("Hello world", output);
}

test "console fillRect" {
    var term = try Terminal.init(6, 6, testing.allocator);
    defer term.deinit();
    term.root().fillRect(1, 2, 3, 4, null, null, '@');

    const output = try term.toString();
    defer testing.allocator.free(output);
    try testing.expectEqualStrings(
        \\      
        \\      
        \\ @@@  
        \\ @@@  
        \\ @@@  
        \\ @@@  
    , output);
}

test "console isInBounds" {
    var term = try Terminal.init(5, 10, testing.allocator);
    defer term.deinit();
    const console = term.root();
    try testing.expect(console.isInBounds(0, 0));
    try testing.expect(console.isInBounds(4, 9));
    try testing.expect(!console.isInBounds(-1, -1));
    try testing.expect(!console.isInBounds(5, 10));
    try testing.expect(!console.isInBounds(-1, 0));
    try testing.expect(!console.isInBounds(5, 0));
    try testing.expect(!console.isInBounds(0, -1));
    try testing.expect(!console.isInBounds(0, 11));
}
