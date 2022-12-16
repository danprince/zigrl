const std = @import("std");
const colors = @import("colors.zig");
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

        var i: usize = 0;
        var y_offset = console.height - 1;

        while (i < messages.len) : (i += 1) {
            const index = messages.len - 1 - i;
            const message = messages[index];
            console.write(0, y_offset, message.fg, 0, message.text);
            if (y_offset <= 0) break else y_offset -= 1;
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
