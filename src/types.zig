pub const Vec = struct {
    x: isize,
    y: isize,
};

pub const Entity = struct {
    const Self = @This();

    x: isize = 0,
    y: isize = 0,
    char: u8,
    color: ?i32,

    pub fn move(self: *Self, dx: isize, dy: isize) void {
        self.x += dx;
        self.y += dy;
    }
};

pub const Graphic = struct {
    ch: u8,
    fg: ?i32,
    bg: ?i32,
};

pub const Tile = struct {
    const Self = @This();
    walkable: bool,
    transparent: bool,
    dark: Graphic,
};
