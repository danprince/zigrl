const std = @import("std");
const utils = @import("utils.zig");
const types = @import("types.zig");
const term = @import("term.zig");
const colors = @import("colors.zig");
const gamemap = @import("map.zig");
const widgets = @import("widgets.zig");
const actions = @import("actions.zig");
const messages = @import("messages.zig");
const Handler = @import("handler.zig");
const testing = std.testing;
const Allocator = std.mem.Allocator;
const Vec = types.Vec;
const Console = term.Console;
const Entity = types.Entity;
const Map = gamemap.Map;
const World = gamemap.World;
const MessageLog = messages.MessageLog;

pub var allocator: Allocator = undefined;
pub var handler: Handler = undefined;
pub var player: Entity = undefined;
pub var map: Map = undefined;
pub var world: World = undefined;
pub var message_log: MessageLog = undefined;
pub var mouse_location: Vec = .{ .x = 0, .y = 0 };

const EngineParams = struct {
    handler: Handler,
    player: Entity,
    allocator: Allocator,
};

pub fn init(params: EngineParams) !void {
    allocator = params.allocator;
    player = params.player;
    handler = params.handler;
    message_log = MessageLog.init(params.allocator);
    player = params.player;
    player.init(params.allocator);
}

pub fn handleEnemyTurns() void {
    for (map.entities.items) |entity| {
        if (entity == &player) continue;
        if (entity.ai) |*ai| ai.perform();
    }
}

pub fn updateRenderOrder() void {
    std.sort.sort(*Entity, map.entities.items, {}, Entity.compareByRenderOrder);
}

/// Recompute the visible area based on the player's point of view.
pub fn updateFieldOfView() void {
    map.visible.clear();

    const los_radius = 8;
    const center = Vec{ .x = player.x, .y = player.y };
    const x1 = center.x - los_radius;
    const y1 = center.y - los_radius;
    const x2 = center.x + los_radius;
    const y2 = center.y + los_radius;

    var y: isize = y1;
    while (y <= y2) : (y += 1) {
        var x: isize = x1;
        while (x <= x2) : (x += 1) {
            // We only want to trace out to the outer edges of the rect
            if (!(x == x1 or x == x2) and (y == x1 or y == y2)) continue;

            var iter = utils.bresenham(center.x, center.y, x, y);
            while (iter.next()) |point| {
                if (!map.inBounds(point.x, point.y)) break;
                if (point.euclideanDistance(center) > los_radius) break;
                const tile = map.getTile(point.x, point.y);
                map.visible.add(point.x, point.y);
                map.explored.add(point.x, point.y);
                if (!tile.transparent) break;
            }
        }
    }
}

pub fn render(console: *Console) void {
    map.render(console);

    message_log.render(&console.child(21, 45, 40, 5));

    if (player.fighter) |fighter| {
        widgets.renderBar(
            console,
            0,
            45,
            "HP",
            fighter.hp,
            fighter.max_hp,
            20,
            colors.bar_filled,
            colors.bar_empty,
        );
    }

    if (player.level) |level| {
        widgets.renderBar(
            console,
            0,
            46,
            "XP",
            @intCast(isize, level.current_xp),
            @intCast(isize, level.experienceToNextLevel()),
            20,
            0x008888,
            0x003333,
        );
    }

    widgets.renderNamesAtMouseLocation(console, 21, 44);
    widgets.renderDungeonLevel(console, world.current_floor, 0, 48);
    console.write(0, 49, 0x555555, null, "Press ? for help");
}
