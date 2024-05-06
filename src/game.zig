pub const Ruleset = struct {
    name: []const u8,
    version: []const u8,
};

pub const Game = struct {
    id: []const u8,
    ruleset: Ruleset,
    map: []const u8,
    timeout: usize,
    source: []const u8,
};

pub const Location = struct {
    x: usize,
    y: usize,
};

pub const Customization = struct {
    color: []const u8,
    head: []const u8,
    tail: []const u8,
};

pub const Snake = struct {
    id: []const u8,
    name: []const u8,
    health: usize,
    body: []const Location,
    latency: []const u8,
    head: Location,
    length: usize,
    shout: []const u8,
    squad: []const u8,
    customizations: Customization,
};

pub const Board = struct {
    height: usize,
    width: usize,
    food: []const Location,
    hazards: []const Location,
};

pub const Move = struct {
    game: Game,
    turn: usize,
    board: Board,
    you: Snake,
};
