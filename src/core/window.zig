const std = @import("std");
const erh = @import("error_handling.zig").ErrorHandle;

const sdl = @cImport({
    @cInclude("SDL3/SDL.h");
});

const WindowError = error {
    CouldNotCreateWindowRenderer,
    CouldNotClearRender,
    CouldNotPresentRender,
};

pub const Window = struct {
    window_width: c_int = 640,
    window_height: c_int = 480,
    window: ?*sdl.SDL_Window = null,
    renderer: ?*sdl.SDL_Renderer = null,
    window_title: [:0]const u8 = "Mobile Game",

    pub fn renderClear(self: *Window) !void {
        const render_clear_res = sdl.SDL_RenderClear(self.renderer);
        if (!render_clear_res) {
            std.log.err("SDL Error: {s}.", .{erh.sdlError()});
            return error.CouldNotClearRender;
        }
    }

    pub fn renderPresent(self: *Window) !void {
        std.debug.assert(self.renderer != null);

        const render_present_res = sdl.SDL_RenderPresent(self.renderer);
        if (!render_present_res) {
            std.log.err("SDL Error: {s}.", .{erh.sdlError()});
            return error.CouldNotPresentRender;
        }
    }

    pub fn createWinRen(self: *Window) !void {
        const win_ren_result = sdl.SDL_CreateWindowAndRenderer(
            self.window_title, self.window_width, self.window_height, sdl.SDL_WINDOW_VULKAN, &self.window, &self.renderer);
        
        if (!win_ren_result) {
            std.log.err("SDL Error: {s}.", .{erh.sdlError()});
            return error.CouldNotCreateWindowRenderer;
        }
    }
};
