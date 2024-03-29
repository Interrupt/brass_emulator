const std = @import("std");
const math = std.math;
const ziglua = @import("ziglua");
const zigsdl = @import("../sdl.zig");
const main = @import("../main.zig");
const debug = @import("../debug.zig");
const assets = @import("assets.zig");
const images= @import("../images.zig");

const sdl = @cImport({
    @cInclude("SDL2/SDL.h");
});

const Lua = ziglua.Lua;

var enable_debug_logging = false;

pub fn makeLib(lua: *Lua) i32 {
    const funcs = [_]ziglua.FnReg{
        .{ .name = "blit", .func = ziglua.wrap(blit) },
    };

    lua.newLib(&funcs);
    return 1;
}

fn blit(lua: *Lua) i32 {
    var texture_handle: u32 = @intFromFloat(lua.toNumber(1) catch 0);
    var source_x: i32 = @intFromFloat(lua.toNumber(2) catch 0);
    var source_y: i32 = @intFromFloat(lua.toNumber(3) catch 0);
    var source_width: u32 = @intFromFloat(lua.toNumber(4) catch 0);
    var source_height: u32 = @intFromFloat(lua.toNumber(5) catch 0);
    var dest_x: i32 = @intFromFloat(lua.toNumber(6) catch 0);
    var dest_y: i32 = @intFromFloat(lua.toNumber(7) catch 0);

    if (enable_debug_logging)
        debug.log("Blitting texture {d}", .{texture_handle});

    blitTexture(texture_handle, source_x, source_y, source_width, source_height, dest_x, dest_y);
    return 0;
}

pub fn blitTexture(texture_handle: u32, source_x: i32, source_y: i32, source_width: u32, source_height: u32, dest_x: i32, dest_y: i32) void {
    const renderer = zigsdl.getRenderer();

    // Get the texture to draw!
    var loaded_img: ?images.Image = assets.getTextureFromHandle(texture_handle);
    if (loaded_img == null)
        return;

    // Found the texture, good to go!
    const img = loaded_img.?;

    // Also make sure not to draw outside the bounds of the screen
    var res_x: c_int = 0;
    var res_y: c_int = 0;
    _ = sdl.SDL_GetRendererOutputSize(renderer, &res_x, &res_y);

    for (0..source_width) |x_pos| {
        for (0..source_height) |y_pos| {
            const x_pixel_pos = @as(i32, @intCast(x_pos)) + source_x;
            const y_pixel_pos = @as(i32, @intCast(y_pos)) + source_y;

            if (x_pixel_pos < 0 or x_pixel_pos > img.width)
                continue;
            if (y_pixel_pos < 0 or y_pixel_pos > img.height)
                continue;

            const index = (x_pixel_pos * img.channels) + (y_pixel_pos * @as(i32, @intCast(img.pitch)));

            const final_index: usize = @as(usize, @intCast(index));
            if (index + 2 >= img.width * img.height * img.channels)
                continue;

            const r = img.raw[final_index];
            const g = img.raw[final_index + 1];
            const b = img.raw[final_index + 2];

            // Skip black pixels
            if (r == 0 and g == 0 and b == 0)
                continue;

            const x_pixel = @as(i32, @intCast(x_pos)) + dest_x;
            const y_pixel = @as(i32, @intCast(y_pos)) + dest_y;

            if (x_pixel < 0 or y_pixel < 0 or x_pixel > res_x or y_pixel > res_y)
                continue;

            _ = sdl.SDL_SetRenderDrawColor(renderer, r, g, b, 0xFF);
            _ = sdl.SDL_RenderDrawPoint(renderer, @as(c_int, @truncate(x_pixel)), @as(c_int, @truncate(y_pixel)));
        }
    }
}
