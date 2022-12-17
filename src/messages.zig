const std = @import("std");
const colors = @import("colors.zig");
const utils = @import("utils.zig");
const term = @import("term.zig");
const testing = std.testing;
const Console = term.Console;

pub const Message = struct {
    text: []const u8,
    fg: i32 = colors.white,
    count: usize = 0,
};

pub const MessageLog = struct {
    const Self = @This();

    messages: std.ArrayList(Message) = undefined,
    arena: std.heap.ArenaAllocator = undefined,

    pub fn init(allocator: std.mem.Allocator) MessageLog {
        var arena = std.heap.ArenaAllocator.init(allocator);
        return .{
            .messages = std.ArrayList(Message).init(allocator),
            .arena = arena,
        };
    }

    pub fn deinit(self: *MessageLog) void {
        self.messages.deinit();
        self.arena.deinit();
    }

    pub fn add(self: *MessageLog, text: []const u8, fg: i32) void {
        self.messages.append(.{ .text = text, .fg = fg }) catch unreachable;
    }

    pub fn print(
        self: *MessageLog,
        comptime fmt: []const u8,
        args: anytype,
        fg: i32,
    ) void {
        var allocator = self.arena.allocator();
        var string = std.fmt.allocPrint(allocator, fmt, args) catch unreachable;
        self.add(string, fg);
    }

    pub fn render(self: *Self, console: *const Console) void {
        const messages = self.messages.items;
        const max_width = @intCast(usize, console.width) - 1;
        var y_offset = console.height - 1;

        // Iterate through messages in reverse to show the most recent message
        // first (at the bottom).
        var i: usize = 0;
        while (i < messages.len) : (i += 1) {
            const index = messages.len - 1 - i;
            const message = messages[index];

            // Take an informed guess at how many lines this text will split across.
            var rows = @intCast(isize, message.text.len / max_width) + 1;
            y_offset -= rows;
            var y_cursor = y_offset;

            var lines = utils.textWrap(message.text, max_width);
            while (lines.next()) |line| {
                console.write(3, y_cursor, message.fg, 0, line);
                y_cursor += 1;
            }

            if (y_offset <= 0) break;
        }
    }
};

test "MessageLog.init / MessageLog.deinit" {
    var log = MessageLog.init(testing.allocator);
    defer log.deinit();
    // This will require an allocation in the message array list
    log.add("hello world", colors.white);
    // This will also require allocation for the formatted string
    log.print("hello {s}", .{"world"}, colors.white);
}
