const std = @import("std");
const utils = @import("utils.zig");
const types = @import("types.zig");
const input = @import("input.zig");
const term = @import("term.zig");
const Console = term.Console;
const Entity = types.Entity;
const InputEvent = input.InputEvent;
const EventHandler = input.EventHandler;
const EntityList = std.SinglyLinkedList(Entity);

pub var gpa = std.heap.GeneralPurposeAllocator(.{}){};
pub var allocator = gpa.allocator();

var entity_list: EntityList = undefined;
var active_entities: std.ArrayList(*Entity) = undefined;
var event_handler: EventHandler = undefined;
pub var player: Entity = undefined;

pub fn init(initial_event_handler: EventHandler, initial_player: Entity) !void {
    event_handler = initial_event_handler;
    entity_list = EntityList{};
    active_entities = std.ArrayList(*Entity).init(gpa.allocator());

    player = initial_player;
    try active_entities.append(&player);
}

pub fn handleEvent(event: InputEvent) void {
    var maybe_action = event_handler.dispatch(event);

    if (maybe_action) |action| switch (action) {
        .move => |move| {
            player.x += move.dx;
            player.y += move.dy;
        },
    };
}

pub fn entities() []*Entity {
    return active_entities.items;
}

pub fn render(console: *Console) void {
    for (entities()) |entity| {
        console.put(entity.x, entity.y, entity.color, null, entity.char);
    }
}
