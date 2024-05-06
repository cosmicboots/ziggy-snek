const std = @import("std");

const Server = std.http.Server;

pub const RouteErrors = error{
    NotFound,
    MethodNotAllowed,
    HttpError,
};

const Response = struct {
    content: []const u8,
    options: ?Server.Request.RespondOptions,
};

const KEY = *const fn (*Server.Request, std.mem.Allocator) RouteErrors!Response;

var routes: std.StringArrayHashMap(KEY) = undefined;

pub fn handleRoute(req: *Server.Request, allocator: std.mem.Allocator) RouteErrors!Response {
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

fn root(req: *Server.Request, allocator: std.mem.Allocator) !Response {
    _ = allocator; // autofix
    if (req.head.method != .GET) {
        return RouteErrors.MethodNotAllowed;
    }

    return Response{
        .content = "Hello from the root",
        .options = null,
    };
}

fn hello(req: *Server.Request, allocator: std.mem.Allocator) !Response {
    _ = allocator; // autofix
    if (req.head.method != .GET) {
        return RouteErrors.MethodNotAllowed;
    }

    return Response{
        .content = "Hello from the hello endpoint",
        .options = null,
    };
}
