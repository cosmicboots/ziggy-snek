const std = @import("std");
const log = std.log.scoped(.server);

fn handleConnection(conn: std.net.Server.Connection, allocator: std.mem.Allocator) !void {
    var buf: [4096]u8 = undefined;

    var http = std.http.Server.init(conn, &buf);
    var req = try http.receiveHead();

    log.info("Received request: {s}", .{req.head.target});

    var headers = req.iterateHeaders();
    log.debug("=== HEADERS ===", .{});
    while (headers.next()) |header| {
        log.debug("{s}: {s}", .{ header.name, header.value });
    }
    log.debug("===============", .{});

    var reader = try req.reader();
    const body = try reader.readAllAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(body);

    log.debug("Recieved: [{s}]", .{body});

    const resp_headers: [1]std.http.Header = .{
        std.http.Header{ .name = "Content-Type", .value = "text/plain" },
    };

    try req.respond("Hello world", .{ .extra_headers = &resp_headers });
}

fn runServer(server: *std.net.Server, allocator: std.mem.Allocator) !void {
    var threads = std.ArrayList(std.Thread).init(allocator);

    while (true) {
        const conn = try server.accept();
        log.info("Accepted connection from {}", .{conn.address});

        const handle = try std.Thread.spawn(.{}, handleConnection, .{ conn, allocator });
        try threads.append(handle);
    }

    for (threads.items()) |thread| {
        thread.join();
    }
}

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
    try runServer(&listener, allocator);
}
