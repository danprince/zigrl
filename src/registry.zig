const std = @import("std");
const types = @import("types.zig");
const errors = @import("errors.zig");
const utils = @import("utils.zig");
const Entity = types.Entity;
const Allocator = std.mem.Allocator;

/// The registry looks after the actual instances of entities so that the engine
/// can just work with pointers.
var entities: []Entity = undefined;
var entity_index: usize = 0;
var allocator: Allocator = undefined;

/// The registry must be initialised before entities can be initialised.
pub fn init(_allocator: Allocator) !void {
    allocator = _allocator;
    entities = try allocator.alloc(Entity, 256);
}

/// Add a copy of this entity to the registry and return a pointer to it.
pub fn addEntity(entity: Entity) *Entity {
    while (entity_index >= entities.len) {
        const ok = allocator.resize(entities, entities.len * 2);
        if (!ok) errors.crash("Could not init entity!");
    }

    entities[entity_index] = entity;
    var entity_ptr = &entities[entity_index];
    entity_index += 1;
    entity_ptr.init();

    return entity_ptr;
}
