const std = @import("std");

const erh = @import("core/error_handling.zig").ErrorHandle;
const Window = @import("core/window.zig").Window;
const Input = @import("core/input.zig").Input;
const GameProperties = @import("core/properties.zig").Properties;

const sdl = @cImport({
    @cInclude("SDL3/SDL.h");
    @cInclude("SDL3/SDL_main.h");
});

pub fn main() !void {    
    const game_props = comptime GameProperties {};
    var win_ren = Window {
        .window_height = 720,
        .window_width = 1280,       
    };

    const metadata_res = sdl.SDL_SetAppMetadata(game_props.app_name, game_props.version, game_props.app_identifier);
    if (!metadata_res) {
        std.log.err("SDL Error: {s}.", .{erh.sdlError()});
        return error.CouldNotCreateAppMetadata;
    }

    try win_ren.createWinRen();
    try win_ren.renderClear();
    try win_ren.renderPresent();

    var input_handler = Input {};

    input_handler.pollForEvent();
    
}
