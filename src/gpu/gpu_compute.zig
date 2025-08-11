const std = @import("std");
const Error = @import("../core/error_handling.zig").ErrorHandle;
const sdl = @cImport(@cInclude("SDL3/SDL.h"));

const GPUError = error {
    FailedToCreateContext,
    CannotClaimWindow,
};

pub const GPUCompute = struct {
    gpu_context: ?*sdl.SDL_GPUDevice = null,

    pub fn startGPU(self: *GPUCompute, window: ?*sdl.SDL_Window) !void {
        std.debug.assert(window != null);

        try self.createDevice();
        try self.claimWindow(window);
    }

    fn createDevice(self: *GPUCompute) !void {
        self.gpu_context = sdl.SDL_CreateGPUDevice(sdl.SDL_GPU_SHADERFORMAT_SPIRV, true, "vulkan");
        if (self.gpu_context == null) {
            std.log.err("Failed to create GPU context! {s}.", .{Error.sdlError()});
            return error.FailedToCreateContext;
        }
    }

    fn claimWindow(self: *GPUCompute, window: ?*sdl.SDL_Window) !void {
        const result = sdl.SDL_ClaimWindowForGPUDevice(self.gpu_context, window);
        if (!result) {
            return error.CannotClaimWindow;
        }
    }
};
