const std = @import("std");
const Error = @import("../core/error_handling.zig").ErrorHandle;
const sdl = @cImport(@cInclude("SDL3/SDL.h"));

const GPUError = error {
    FailedToCreateContext,
    CannotClaimWindow,
    FailedToCreateShaderObject,
    FailedToCreateGPUBuffer,
};

const shader_create_info: sdl.SDL_GPUShaderCreateInfo = .{
    
};

const gpu_buffer_create_info: sdl.SDL_GPUBufferCreateInfo = .{

};

const gpu_transfer_buffer_location: sdl.SDL_GPUTransferBufferLocation = .{

};

const gpu_buffer_reigon: sdl.SDL_GPUBufferRegion = .{

};

var copy_pass: sdl.SDL_GPUCopyPass = undefined;

pub const GPUCompute = struct {
    gpu_context: ?*sdl.SDL_GPUDevice = null,
    enable_validation_layers: bool = true,

    pub fn startGPU(self: *GPUCompute, window: ?*sdl.SDL_Window) !void {
        std.debug.assert(window != null);

        try self.createDevice();
        try self.claimWindow(window);
        try self.createShader();
        try self.createGPUBuffer();
        // uploadToGPUBuffer();
    }

    fn createDevice(self: *GPUCompute) !void {
        self.gpu_context = sdl.SDL_CreateGPUDevice(sdl.SDL_GPU_SHADERFORMAT_SPIRV, self.enable_validation_layers, "vulkan");
        if (self.gpu_context == null) {
            std.log.err("Failed to create GPU context! {s}.", .{Error.sdlError()});
            return error.FailedToCreateContext;
        }
        std.log.debug("GPU Context: {any}", .{self.gpu_context});
    }

    fn claimWindow(self: *GPUCompute, window: ?*sdl.SDL_Window) !void {
        const result = sdl.SDL_ClaimWindowForGPUDevice(self.gpu_context, window);
        if (!result) {
            return error.CannotClaimWindow;
        }
    }

    fn createShader(self: *GPUCompute) !void {
        const shader_object = sdl.SDL_CreateGPUShader(self.gpu_context, &shader_create_info);
        if (shader_object == null) {
            std.log.err("Failed to create shader object: {s}.", .{Error.sdlError()});
            return error.FailedToCreateShaderObject;
        }
        std.log.debug("Shader: {any}", .{shader_object});
    }

    fn createGPUBuffer(self: *GPUCompute) !void {
        const gpu_buffer = sdl.SDL_CreateGPUBuffer(self.gpu_context, &gpu_buffer_create_info);
        if (gpu_buffer == null) {
            std.log.err("Failed to create GPU buffer: {s}.", .{Error.sdlError()});
            return error.FailedToCreateGPUBuffer;
        }
        std.log.debug("Shader: {any}", .{gpu_buffer});
    }
    fn uploadToGPUBuffer() void {
        sdl.SDL_UploadToGPUBuffer(&copy_pass, &gpu_transfer_buffer_location, &gpu_buffer_reigon, true);
    }
    fn createGPUGraphicsPipeline() !void {
        // TODO
    }
};
