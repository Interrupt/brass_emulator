const std = @import("std");
const core = @import("core");

const lua = @import("lua.zig");
const sdl = @import("sdl.zig");
const images = @import("images.zig");
const debug = @import("debug.zig");

const Allocator = std.mem.Allocator;

var args_gpa = std.heap.GeneralPurposeAllocator(.{}){};
var args_allocator = args_gpa.allocator();

var isRunning = true;
var numTicks: u64 = 0;

const fallback_assets_path = "../../assets";
// pub var assets_path: [:0]const u8 = undefined;
pub var palette: images.Image = undefined;

pub const App = @This();

title_timer: core.Timer,

pub fn init(app: *App) !void {
    try core.init(.{});

    app.* = .{ .title_timer = try core.Timer.start(), };
    try core.printTitle("Zig Game Test", .{});

    // Start the engine!
    debug.init();
    defer debug.deinit();

    debug.log("Brass Emulator Starting", .{});

    try std.os.chdirZ(fallback_assets_path);

    // Get arguments
    // const args = try std.process.argsAlloc(args_allocator);
    // defer _ = args_gpa.deinit();
    // defer std.process.argsFree(args_allocator, args);
    //
    // // Get the path to the assets
    // assets_path = switch (args.len >= 2) {
    //     true => try args_allocator.dupeZ(u8, args[1]),
    //     else => try args_allocator.dupeZ(u8, fallback_assets_path),
    // };
    // defer args_allocator.free(assets_path);

    // Change the working dir to where the assets are
    // var assets_path = fallback_assets_path;
    // debug.log("Assets Path: {s}", .{assets_path});
    // try std.os.chdirZ(assets_path);

    // Load the palette
    // palette = try images.loadFile("palette.gif");
    // defer palette.destroy();

    // Start up SDL2
    // try sdl.init();
    // defer sdl.deinit();

    // Load the palette
    palette = try images.loadFile("palette.gif");
    defer palette.destroy();

    // Start up Lua
    try lua.init();
    defer lua.deinit();

    // Load and run the main script
    lua.runFile("main.lua") catch {
        try showErrorScreen("Fatal error during startup!");
    };

    // Call the init lifecycle function
    lua.callFunction("_init") catch {
        try showErrorScreen("Fatal error!");
    };
}

pub fn deinit(app: *App) void {
    defer core.deinit();
    _ = app;
}

pub fn update(app: *App) !bool {
    var iter = core.pollEvents();
    while (iter.next()) |event| {
        switch (event) {
            .close => return true,
            else => {},
        }
    }

    // update the window title every second
    if (app.title_timer.read() >= 1.0) {
        app.title_timer.reset();
        try core.printTitle("Zig Game Test [ {d}fps ] [ Input {d}hz ]", .{
            core.frameRate(),
            core.inputRate(),
        });
    }

    return false;
}

pub fn showErrorScreen(error_header: [:0]const u8) !void {
    std.debug.print("Showing error screen: {s}\n", .{error_header});
}

// pub fn main() !void {
//     debug.init();
//     defer debug.deinit();
//
//     debug.log("Brass Emulator Starting", .{});
//
//     // Get arguments
//     const args = try std.process.argsAlloc(args_allocator);
//     defer _ = args_gpa.deinit();
//     defer std.process.argsFree(args_allocator, args);
//
//     // Get the path to the assets
//     assets_path = switch (args.len >= 2) {
//         true => try args_allocator.dupeZ(u8, args[1]),
//         else => try args_allocator.dupeZ(u8, fallback_assets_path),
//     };
//     defer args_allocator.free(assets_path);
//
//     // Change the working dir to where the assets are
//     debug.log("Assets Path: {s}", .{assets_path});
//     try std.os.chdirZ(assets_path);
//
//     // Load the palette
//     palette = try images.loadFile("palette.gif");
//     defer palette.destroy();
//
//     // Start up SDL2
//     try sdl.init();
//     defer sdl.deinit();
//
//     // Start up Lua
//     try lua.init();
//     defer lua.deinit();
//
//     // Load and run the main script
//     lua.runFile("main.lua") catch {
//         try showErrorScreen("Fatal error during startup!");
//     };
//
//     // Call the init lifecycle function
//     lua.callFunction("_init") catch {
//         try showErrorScreen("Fatal error!");
//     };
//
//     // Kick off the game loop!
//     while (isRunning) {
//         sdl.processEvents();
//
//         lua.callFunction("_update") catch {
//             try showErrorScreen("Fatal error!");
//         };
//
//         lua.callFunction("_draw") catch {
//             try showErrorScreen("Fatal error!");
//         };
//
//         debug.drawConsole();
//
//         sdl.present();
//         numTicks += 1;
//     }
//
//     debug.log("Brass Emulator Stopping", .{});
// }
//
// pub fn getAssetPath(file_path: []const u8, allocator: Allocator) ![:0]const u8 {
//     const total_size = assets_path.len + file_path.len + 2;
//     var path: []u8 = try allocator.alloc(u8, total_size);
//     return try std.fmt.bufPrintZ(path, "{s}/{s}", .{ assets_path, file_path });
// }
//
// pub fn stop() void {
//     isRunning = false;
// }
//
// pub fn showErrorScreen(error_header: [:0]const u8) !void {
//     // Simple lua function to make the draw function draw an error screen
//     const error_screen_lua =
//         \\ _draw = function()
//         \\ require('draw').clear(1)
//         \\ require('text').draw("{s}", 8, 8, 0)
//         \\ require('text').draw_wrapped([[{s}]], 8, 24, 264, 0)
//         \\ end
//         \\
//         \\ _update = function() end
//     ;
//
//     // Assume that the last log line is what exploded!
//     const log_history = debug.getLogHistory();
//     var error_desc: [:0]const u8 = undefined;
//     if (log_history.last()) |last_log| {
//         error_desc = last_log.data;
//     } else {
//         error_desc = "Something bad happened!";
//     }
//
//     // Only use until the first newline
//     var error_desc_splits = std.mem.split(u8, error_desc, "\n");
//     var first_split = error_desc_splits.first();
//
//     const written = try std.fmt.allocPrintZ(args_allocator, error_screen_lua, .{ error_header, first_split });
//     defer args_allocator.free(written);
//
//     // Reset to an error palette!
//     palette.raw[0] = 0x22;
//     palette.raw[1] = 0x00;
//     palette.raw[2] = 0x00;
//     palette.raw[3] = 0xFF;
//
//     palette.raw[4] = 0x99;
//     palette.raw[5] = 0x00;
//     palette.raw[6] = 0x00;
//     palette.raw[7] = 0xFF;
//
//     std.debug.print("Showing error screen: {s}\n", .{error_header});
//     try lua.runLine(written);
// }
