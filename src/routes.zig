const std = @import("std");

const Server = std.http.Server;

pub const RouteErrors = error{
    NotFound,
    MethodNotAllowed,
    HttpError,
};

const KEY = *const fn (*Server.Request, std.mem.Allocator) RouteErrors!void;

var routes: std.StringArrayHashMap(KEY) = undefined;

pub fn handle_route(req: *Server.Request, allocator: std.mem.Allocator) RouteErrors!void {
    const route = routes.get(req.head.target);
    if (route == null) {
        return RouteErrors.NotFound;
    }

    return route.?(req, allocator);
}

pub fn init(allocator: std.mem.Allocator) !void {
    routes = std.StringArrayHashMap(KEY).init(allocator);
    try routes.put("/", root);
    try routes.put("/hello", hello);
}

pub fn deinit() void {
    routes.deinit();
}

fn root(req: *Server.Request, allocator: std.mem.Allocator) !void {
    _ = allocator; // autofix
    if (req.head.method != .GET) {
        return RouteErrors.MethodNotAllowed;
    }

    req.respond("Hello from the root", .{}) catch return RouteErrors.HttpError;
}

fn hello(req: *Server.Request, allocator: std.mem.Allocator) !void {
    _ = allocator; // autofix
    if (req.head.method != .GET) {
        return RouteErrors.MethodNotAllowed;
    }

    req.respond("Hello from the hello", .{}) catch return RouteErrors.HttpError;
}
