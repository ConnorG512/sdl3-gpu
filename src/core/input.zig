const sdl = @cImport(@cInclude("SDL3/SDL.h"));

pub const Input = struct {
    current_event: sdl.SDL_Event = undefined,

    pub fn pollForEvent(self: *Input) void {
        if (sdl.SDL_PollEvent(&self.current_event)) {
            if (self.current_event.type == sdl.SDL_EVENT_QUIT) {
                // Quit
            }
        }
    }
};
