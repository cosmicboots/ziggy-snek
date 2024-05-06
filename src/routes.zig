const std = @import("std");
const json = std.json;

const Server = std.http.Server;

pub const RouteErrors = error{
    NotFound,
    MethodNotAllowed,
    JsonError,
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
    if (req.head.method != .GET) {
        return RouteErrors.MethodNotAllowed;
    }

    const blob = json.stringifyAlloc(allocator, .{
        .apiversion = "1",
        //.author = "MyUsername",
        //.color = "#888888",
        //.head = "default",
        //.tail = "default",
        //.version = "0.0.1-beta",
    }, .{}) catch {
        return RouteErrors.JsonError;
    };

    return Response{
        .content = blob,
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
