const std = @import("std");
const log = std.log.scoped(.server);

fn handleRequest(req: *std.http.Server.Request) !void {
    log.info("Received request: {s}", .{req.head.target});

    var headers = req.iterateHeaders();
    while (headers.next()) |header| {
        log.info("{s}: {s}", .{ header.name, header.value });
    }

    const resp_headers: [1]std.http.Header = .{
        std.http.Header{ .name = "Content-Type", .value = "text/plain" },
    };
    try req.respond("Hello world", .{ .extra_headers = &resp_headers });
}

fn handleConnection(conn: std.net.Server.Connection) !void {
    var buf: [1024]u8 = undefined;
    var http = std.http.Server.init(conn, &buf);

    var req = try http.receiveHead();
    try handleRequest(&req);
}

fn runServer(server: *std.net.Server, allocator: std.mem.Allocator) !void {
    var threads = std.ArrayList(std.Thread).init(allocator);

    while (true) {
        const conn = try server.accept();
        log.info("Accepted connection from {}", .{conn.address});

        const handle = try std.Thread.spawn(.{}, handleConnection, .{conn});
        try threads.append(handle);
    }

    for (threads.items()) |thread| {
        thread.join();
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const address = std.net.Address.initIp4(.{ 127, 0, 0, 1 }, 3030);
    var listener = try address.listen(.{});
    try runServer(&listener, allocator);
}
