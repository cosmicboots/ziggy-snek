const std = @import("std");
const json = std.json;
const game = @import("game.zig");

const Server = std.http.Server;

pub const RouteErrors = error{
    NotFound,
    MethodNotAllowed,
    JsonError,
    HttpError,
    MemoryError,
};

const Response = struct {
    content: []const u8,
    options: ?Server.Request.RespondOptions,
};

const KEY = *const fn (*Server.Request, std.mem.Allocator) RouteErrors!Response;

var routes: std.StringArrayHashMap(KEY) = undefined;

pub fn handleRoute(req: *Server.Request, allocator: std.mem.Allocator) RouteErrors!Response {
    var path: []const u8 = undefined;
    if (req.head.target[req.head.target.len - 1] == '/') {
        const target = req.head.target[0..(req.head.target.len - 1)];
        path = target;
    } else {
        path = req.head.target;
    }
    const route = routes.get(path);
    if (route == null) {
        return RouteErrors.NotFound;
    }

    return route.?(req, allocator);
}

pub fn init(allocator: std.mem.Allocator) !void {
    routes = std.StringArrayHashMap(KEY).init(allocator);
    try routes.put("/", root);
    try routes.put("/move", move);
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

fn move(req: *Server.Request, allocator: std.mem.Allocator) !Response {
    if (req.head.method != .POST) {
        return RouteErrors.MethodNotAllowed;
    }

    var req_reader = req.reader() catch {
        return RouteErrors.HttpError;
    };
    const body = req_reader.readAllAlloc(allocator, std.math.maxInt(usize)) catch {
        return RouteErrors.MemoryError;
    };

    const parsed: json.Parsed(game.Move) = json.parseFromSlice(
        game.Move,
        allocator,
        body,
        .{},
    ) catch {
        return RouteErrors.JsonError;
    };
    defer parsed.deinit();

    const blob = json.stringifyAlloc(allocator, .{
        .move = "up",
        .shout = "I'm a zig snake!",
    }, .{}) catch {
        return RouteErrors.JsonError;
    };

    return Response{
        .content = blob,
        .options = null,
    };
}
