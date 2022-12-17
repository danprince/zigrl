const term = @import("term.zig");
const utils = @import("utils.zig");
const colors = @import("colors.zig");
const engine = @import("engine.zig");
const Console = term.Console;

pub fn renderBar(
    console: *Console,
    x: isize,
    y: isize,
    label: []const u8,
    current_value: isize,
    maximum_value: isize,
    total_width: isize,
    fill_color: ?i32,
    empty_color: ?i32,
) void {
    const percent = @intToFloat(f32, current_value) / @intToFloat(f32, maximum_value);
    const bar_width = @floatToInt(isize, percent * @intToFloat(f32, total_width));

    console.fillRect(x, y, total_width, 1, null, empty_color, ' ');

    if (bar_width > 0) {
        console.fillRect(x, y, bar_width, 1, null, fill_color, ' ');
    }

    console.print(x + 1, y, colors.bar_text, null, "{s}: {d}/{d}", .{
        label,
        current_value,
        maximum_value,
    });
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

pub fn renderDungeonLevel(console: *Console, dungeon_level: usize, x: isize, y: isize) void {
    console.print(x, y, colors.white, null, "Dungeon level: {d}", .{dungeon_level});
}
