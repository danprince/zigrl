const term = @import("term.zig");
const utils = @import("utils.zig");
const colors = @import("colors.zig");
const engine = @import("engine.zig");
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

pub fn renderNamesAtMouseLocation(console: *Console, x: isize, y: isize) void {
    const mouse_x = engine.mouse_location.x;
    const mouse_y = engine.mouse_location.y;
    if (!engine.map.inBounds(mouse_x, mouse_y)) return;
    if (!engine.map.visible.has(mouse_x, mouse_y)) return;

    var x_offset = x;
    for (engine.map.entities.items) |entity| {
        if (entity.x == mouse_x and entity.y == mouse_y) {
            if (x_offset > x) {
                console.write(x_offset, y, colors.white, colors.black, ", ");
                x_offset += 2;
            }
            console.write(x_offset, y, colors.white, colors.black, entity.name);
            x_offset += @intCast(isize, entity.name.len);
        }
    }
}
