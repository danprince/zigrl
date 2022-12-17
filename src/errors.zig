const utils = @import("utils.zig");

pub fn crash(msg: []const u8) noreturn {
    utils.printWithLevel("{s}", .{msg}, .err);
    @panic(msg);
}

pub fn oom() noreturn {
    return crash("Out of memory!");
}
