const std = @import("std");
const utils = @import("utils.zig");
const types = @import("types.zig");
const input = @import("input.zig");
const term = @import("term.zig");
const gamemap = @import("map.zig");
const actions = @import("actions.zig");
const Vec = types.Vec;
const Console = term.Console;
const Entity = types.Entity;
const InputEvent = input.InputEvent;
const EventHandler = input.EventHandler;
const EntityList = std.SinglyLinkedList(Entity);
const Map = gamemap.Map;

pub var gpa = std.heap.GeneralPurposeAllocator(.{}){};
pub var allocator = gpa.allocator();

var entity_list: EntityList = undefined;
var active_entities: std.ArrayList(*Entity) = undefined;
var event_handler: EventHandler = undefined;
pub var player: Entity = undefined;
pub var map: gamemap.Map = undefined;

pub fn init(initial_event_handler: EventHandler, initial_map: Map, initial_player: Entity) !void {
    event_handler = initial_event_handler;
    entity_list = EntityList{};
    active_entities = std.ArrayList(*Entity).init(gpa.allocator());
    map = initial_map;
    player = initial_player;
    try active_entities.append(&player);
    updateFieldOfView();
}

pub fn handleEvent(event: InputEvent) void {
    var maybe_action = event_handler.dispatch(event);

    if (maybe_action) |action| {
        actions.perform(action, &player);
        updateFieldOfView();
    }
}

pub fn entities() []*Entity {
    return active_entities.items;
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

    for (entities()) |entity| {
        if (map.visible.has(entity.x, entity.y)) {
            console.put(entity.x, entity.y, entity.color, null, entity.char);
        }
    }
}
