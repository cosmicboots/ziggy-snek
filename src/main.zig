const std = @import("std");
const server = @import("server.zig");
const log = std.log.scoped(.main);

export fn sigHandler(sig: i32) void {
    if (sig == std.os.linux.SIG.INT) {
        log.info("Shutting down server...", .{});
        std.os.linux.exit(0);
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.testing.expect(gpa.deinit() == .ok) catch unreachable;
    const allocator = gpa.allocator();

    const sigaction: std.os.linux.Sigaction = .{ .handler = .{ .handler = sigHandler }, .mask = .{0} ** 32, .flags = 0 };
    _ = std.os.linux.sigaction(std.os.linux.SIG.INT, &sigaction, null);

    var address = std.net.Address.initIp4(.{ 127, 0, 0, 1 }, 3030);

    var listener: std.net.Server = try address.listen(.{ .reuse_address = true });
    defer listener.deinit();

    log.info("Listening on {}", .{address});
    try server.runServer(&listener, allocator);
}
