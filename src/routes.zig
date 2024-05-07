const std = @import("std");
const json = std.json;
const types = @import("types.zig");

const log = std.log.scoped(.routes);

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
    const route = routes.get(req.head.target);
    if (route == null) {
        return RouteErrors.NotFound;
    }

    return route.?(req, allocator);
}

pub fn init(allocator: std.mem.Allocator) !void {
    routes = std.StringArrayHashMap(KEY).init(allocator);
    try routes.put("/", root);
    try routes.put("/move", move);
    try routes.put("/start", noop);
    try routes.put("/end", noop);
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
        .author = "cosmicboots",
        .color = "#0000ff",
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

    // leaky version can be uses as requests are handled with an arena allocator
    var diag = json.Diagnostics{};
    var tokens = json.Scanner.initCompleteInput(allocator, body);
    tokens.enableDiagnostics(&diag);
    const parsed: types.MoveReq = json.parseFromTokenSourceLeaky(
        types.MoveReq,
        allocator,
        &tokens,
        .{ .ignore_unknown_fields = true },
    ) catch {
        const col = diag.getColumn();
        const ctx = 50;
        // Pretty print json parsing error
        log.err("{s}", .{body[@max(0, col - ctx)..@min(body.len, col + ctx)]});
        log.err("{s: >[1]}", .{ "^", @min(ctx, col - ctx) });
        log.err("Failed to parse json at col {}", .{diag.getColumn()});
        return RouteErrors.JsonError;
    };

    log.debug("Move request: {}\n", .{parsed});

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

fn noop(req: *Server.Request, allocator: std.mem.Allocator) !Response {
    _ = allocator; // autofix
    _ = req; // autofix
    return Response{
        .content = "noop",
        .options = null,
    };
}
