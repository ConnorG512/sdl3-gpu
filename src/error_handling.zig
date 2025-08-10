const std = @import("std");
const sdl = @cImport(@cInclude("SDL3/SDL.h"));

pub const ErrorHandle = struct {
    pub fn sdlError() []const u8 {
        const error_message: []const u8 = std.mem.sliceTo(sdl.SDL_GetError(), 0);
        return error_message;
    } 
};
