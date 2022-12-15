const utils = @import("utils.zig");

pub fn crash(msg: []const u8) noreturn {
    utils.print("🚨 ZigRL Crashed! 🚨\n{s}", .{msg});
    @panic(msg);
}
