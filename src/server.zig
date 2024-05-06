const std = @import("std");
const routes = @import("routes.zig");

const log = std.log.scoped(.server);

fn handleConnection(conn: std.net.Server.Connection, allocator: std.mem.Allocator) !void {
    defer conn.stream.close();
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

    const res = routes.handleRoute(&req, allocator) catch |err| {
        log.err("Error handling route: {s}", .{@errorName(err)});
        if (err == routes.RouteErrors.NotFound) {
            try req.respond("", .{ .status = std.http.Status.not_found, .keep_alive = false });
        } else if (err == routes.RouteErrors.MethodNotAllowed) {
            try req.respond("", .{ .status = std.http.Status.method_not_allowed, .keep_alive = false });
        } else {
            try req.respond("", .{ .status = std.http.Status.internal_server_error, .keep_alive = false });
        }
        return;
    };

    const options = if (res.options) |options|
        options
    else
        std.http.Server.Request.RespondOptions{ .keep_alive = false };

    try req.respond(res.content, options);
}

pub fn runServer(server: *std.net.Server, allocator: std.mem.Allocator) !void {
    var threads = std.ArrayList(std.Thread).init(allocator);

    // Setup routes
    try routes.init(allocator);
    defer routes.deinit();

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
