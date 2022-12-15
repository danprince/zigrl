pub const ActionType = enum {
    move,
};

pub const Action = union(ActionType) {
    move: struct { dx: isize, dy: isize },
};

pub fn move(dx: isize, dy: isize) Action {
    return .{ .move = .{ .dx = dx, .dy = dy } };
}
