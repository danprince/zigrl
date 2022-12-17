const std = @import("std");
const builtin = @import("builtin");

pub usingnamespace if (builtin.target.isWasm()) struct {
    // When running in a browser, these functions are provided by JavaScript.
    // See web/index.js for their implementations.
    pub extern fn print(message: [*]u8, length: usize, level: usize) void;
    pub extern fn flushTerm(buffer_ptr: [*]i32, buffer_size: usize) void;
    pub extern fn initTerm(width: usize, height: usize) void;
} else struct {
    // When running outside wasm (e.g. for tests) these functions need to be
    // stubbed out instead.
    const stdout = std.io.getStdOut().writer();

    pub fn print(message: [*]u8, length: usize, _: usize) void {
        stdout.writeAll(message[0..length]) catch unreachable;
    }

    pub fn initTerm(_: usize, _: usize) void {}
    pub fn flushTerm(_: [*]i32, _: usize) void {}
};
