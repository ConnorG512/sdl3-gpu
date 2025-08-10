const std = @import("std");
const Error = @import("../core/error_handling.zig").ErrorHandle;
const sdl = @cImport(@cInclude("SDL3/SDL.h"));

const GPUError = error {
    FailedToCreateContext,
};

pub const GPUCompute = struct {
    gpu_context: ?*sdl.SDL_GPUDevice = null,

    pub fn createDevice(self: *GPUCompute) !void {
        self.gpu_context = sdl.SDL_CreateGPUDevice(sdl.SDL_GPU_SHADERFORMAT_SPIRV, true, null);
        if (self.gpu_context == null) {
            std.log.err("Failed to create GPU context! {s}.", .{Error.sdlError()});
            return error.FailedToCreateContext;
        }
    }
};
