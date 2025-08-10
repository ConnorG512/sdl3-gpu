const std = @import("std");
const erh = @import("error_handling.zig").ErrorHandle;
const Window = @import("window.zig").Window;
const Input = @import("input.zig").Input;

const sdl = @cImport({
    @cInclude("SDL3/SDL.h");
    @cInclude("SDL3/SDL_main.h");
});

const GameError = error {
    CouldNotCreateAppMetadata,
};

const GameProperties = struct {
    app_name: [:0]const u8 = "Mobile bounce game.",
    version: [:0]const u8 = "0.0.1",
    app_identifier: [:0]const u8 = "com.app.mobilebouncegame",
};


pub fn main() !void {    
    const game_props = comptime GameProperties {};
    var win_ren = Window {};

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
