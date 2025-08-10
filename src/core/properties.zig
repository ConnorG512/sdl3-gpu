const std = @import("std");

const sdl = @cImport(@cInclude("SDL3/SDL.h"));

pub const Properties = struct {
    app_name: [:0]const u8 = "Title.",
    version: [:0]const u8 = "1.0",
    app_identifier: [:0]const u8 = "com.app.gametitle",

    pub fn setProjectMetadata(self: *Properties) void {
        const result = sdl.SDL_SetAppMetadata(
            self.app_name, 
            self.version, 
            self.app_identifier);
        if (!result) {
            std.log.debug("WARNING: Failed to create project metadata!", .{});
        }
    }
};
