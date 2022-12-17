const std = @import("std");
const types = @import("types.zig");
const colors = @import("colors.zig");
const Ai = @import("components/ai.zig");
const rgb = colors.rgb;
const Entity = types.Entity;

pub const player = Entity{
    .char = '@',
    .color = rgb(255, 255, 255),
    .name = "Player",
    .blocks_movement = true,
    .render_order = .actor,
    .fighter = .{ .hp = 30, .base_defense = 1, .base_power = 2 },
    .inventory = .{ .capacity = 26 },
    .level = .{ .level_up_base = 200 },
    .equipment = .{},
};

pub const orc = Entity{
    .char = 'o',
    .color = rgb(63, 127, 63),
    .name = "Orc",
    .blocks_movement = true,
    .render_order = .actor,
    .fighter = .{ .hp = 10, .base_defense = 0, .base_power = 3 },
    .ai = Ai.with(.hostile),
    .inventory = .{ .capacity = 0 },
    .level = .{ .xp_given = 35 },
};

pub const troll = Entity{
    .char = 'T',
    .color = rgb(0, 127, 0),
    .name = "Troll",
    .blocks_movement = true,
    .render_order = .actor,
    .fighter = .{ .hp = 16, .base_defense = 1, .base_power = 4 },
    .ai = Ai.with(.hostile),
    .inventory = .{ .capacity = 0 },
    .level = .{ .xp_given = 100 },
};

pub const health_potion = Entity{
    .char = 0x17,
    .color = rgb(127, 0, 255),
    .name = "Health Potion",
    .render_order = .item,
    .consumable = .{ .kind = .{ .healing = .{ .amount = 4 } } },
};

pub const lightning_scroll = Entity{
    .char = '~',
    .color = rgb(255, 255, 0),
    .name = "Lightning Scroll",
    .render_order = .item,
    .consumable = .{ .kind = .{ .lightning_damage = .{ .damage = 20, .maximum_range = 5 } } },
};

pub const confusion_scroll = Entity{
    .char = '~',
    .color = rgb(207, 63, 255),
    .name = "Confusion Scroll",
    .render_order = .item,
    .consumable = .{ .kind = .{ .confusion = .{ .number_of_turns = 10 } } },
};

pub const fireball_scroll = Entity{
    .char = '~',
    .color = rgb(255, 0, 0),
    .name = "Fireball Scroll",
    .render_order = .item,
    .consumable = .{ .kind = .{ .fireball_damage = .{ .damage = 12, .radius = 3 } } },
};

pub const dagger = Entity{
    .char = 0x16,
    .color = rgb(0, 91, 255),
    .name = "Dagger",
    .render_order = .item,
    .equippable = .{ .kind = .weapon, .power_bonus = 2 },
};

pub const sword = Entity{
    .char = 0x16,
    .color = rgb(0, 91, 255),
    .name = "Sword",
    .render_order = .item,
    .equippable = .{ .kind = .weapon, .power_bonus = 4 },
};

pub const leather_armor = Entity{
    .char = 0x15,
    .color = rgb(139, 69, 19),
    .name = "Leather Armor",
    .render_order = .item,
    .equippable = .{ .kind = .armor, .defense_bonus = 1 },
};

pub const chainmail = Entity{
    .char = 0x15,
    .color = rgb(139, 69, 19),
    .name = "Chainmail",
    .render_order = .item,
    .equippable = .{ .kind = .armor, .defense_bonus = 3 },
};
