const term = @import("term.zig");
const colors = @import("colors.zig");
const Console = term.Console;

pub fn renderBar(
    console: *Console,
    current_value: isize,
    maximum_value: isize,
    total_width: isize,
) void {
    const percent = @intToFloat(f32, current_value) / @intToFloat(f32, maximum_value);
    const bar_width = @floatToInt(isize, percent * @intToFloat(f32, total_width));

    console.fillRect(0, 45, total_width, 1, null, colors.bar_empty, ' ');

    if (bar_width > 0) {
        console.fillRect(0, 45, bar_width, 1, null, colors.bar_filled, ' ');
    }

    console.print(1, 45, colors.bar_text, null, "HP: {d}/{d}", .{ current_value, maximum_value });
}
