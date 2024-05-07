const t = @import("types.zig");

pub fn calcMove(req: t.MoveReq) t.MoveRes {
    _ = req; // autofix
    return t.MoveRes{
        .move = .up,
        .shout = null,
    };
}
