const std = @import("std");
const utils = @import("utils.zig");
const types = @import("types.zig");
const input = @import("input.zig");
const term = @import("term.zig");
const gamemap = @import("map.zig");
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
}

pub fn handleEvent(event: InputEvent) void {
    var maybe_action = event_handler.dispatch(event);

    if (maybe_action) |action| switch (action) {
        .move => |move| {
            const dest_x = player.x + move.dx;
            const dest_y = player.y + move.dy;
            const tile_or_null = map.getTileOrNull(dest_x, dest_y);

            if (tile_or_null) |tile| {
                if (tile.walkable) {
                    player.x += move.dx;
                    player.y += move.dy;
                }
            }
        },
    };
}

pub fn entities() []*Entity {
    return active_entities.items;
}

pub fn render(console: *Console) void {
    map.render(console);

    for (entities()) |entity| {
        console.put(entity.x, entity.y, entity.color, null, entity.char);
    }
}
