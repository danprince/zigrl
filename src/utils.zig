const std = @import("std");
const host = @import("host.zig");

var fmt_buffer: [1024]u8 = undefined;

/// Equivalent to std.debug.print except it prints the string to the browser's
/// console instead of to stdout. This function uses a fixed 1KB buffer so that
/// the caller doesn't have to worry about memory allocations. Larger strings
/// will be trimmed.
pub fn print(comptime fmt: []const u8, args: anytype) void {
    const str = std.fmt.bufPrint(&fmt_buffer, fmt, args) catch &fmt_buffer;
    host.print(str.ptr, str.len);
}
