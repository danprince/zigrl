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
