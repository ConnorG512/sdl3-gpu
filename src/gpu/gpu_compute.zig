const std = @import("std");
const Error = @import("../core/error_handling.zig").ErrorHandle;
const sdl = @cImport(@cInclude("SDL3/SDL.h"));

const GPUError = error {
    FailedToCreateContext,
    CannotClaimWindow,
    FailedToCreateShaderObject,
    FailedToCreateGPUBuffer,
};



var gpu_transfer_buffer_location: sdl.SDL_GPUTransferBufferLocation = .{
    .offset = 0,
};

const gpu_buffer_reigon: sdl.SDL_GPUBufferRegion = .{
    .buffer = undefined,
    .offset = 0,
};

// var pipelineCreateInfo: sdl.SDL_GPUGraphicsPipelineCreateInfo = .{
//     .target_info = .{
//         .num_color_targets = 1,
//         .color_target_descriptions = .{}
//     },
// }

var copy_pass: sdl.SDL_GPUCopyPass = undefined;

pub const GPUCompute = struct {
    gpu_context: ?*sdl.SDL_GPUDevice = null,
    enable_validation_layers: bool = true,
    gpu_buffer: ?*sdl.SDL_GPUBuffer = null,

    pub fn startGPU(self: *GPUCompute, window: ?*sdl.SDL_Window) !void {
        std.debug.assert(window != null);

        try self.createDevice();
        try self.claimWindow(window);
        try self.createGPUShader();
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
        std.debug.assert(window != null);

        const result = sdl.SDL_ClaimWindowForGPUDevice(self.gpu_context, window);
        if (!result) {
            return error.CannotClaimWindow;
        }
    }

    fn createGPUShader(self: *GPUCompute) !void {
        const shader_file = @embedFile("../shader/frag.spv");

        const shader_create_info: sdl.SDL_GPUShaderCreateInfo = .{
            .code = shader_file.ptr,
            .code_size = shader_file.len,
            .entrypoint = "main",
            .format = sdl.SDL_GPU_SHADERFORMAT_SPIRV, 
            .stage = sdl.SDL_GPU_SHADERSTAGE_FRAGMENT,
            .num_samplers = 0,
            .num_storage_buffers = 0,
            .num_storage_textures = 0,
            .num_uniform_buffers = 0,
            .props = 0,
        };

        const shader_object = sdl.SDL_CreateGPUShader(self.gpu_context, &shader_create_info);
        if (shader_object == null) {
            std.log.err("Failed to create shader object: {s}.", .{Error.sdlError()});
            return error.FailedToCreateShaderObject;
        }
        std.log.debug("Shader: {any}", .{shader_object});
    }

    fn createGPUBuffer(self: *GPUCompute) !void {
        const gpu_buffer_create_info: sdl.SDL_GPUBufferCreateInfo = .{
            .usage = sdl.SDL_GPU_BUFFERUSAGE_VERTEX,
            .size = @sizeOf([3]f32) * 3, // 3 verticies with 3 floats each
            .props = 0,
        };

        self.gpu_buffer = sdl.SDL_CreateGPUBuffer(self.gpu_context, &gpu_buffer_create_info);
        if (self.gpu_buffer == null) {
            std.log.err("Failed to create GPU buffer: {s}.", .{Error.sdlError()});
            return error.FailedToCreateGPUBuffer;
        }
        std.log.debug("Shader: {any}", .{self.gpu_buffer});
    }

    fn createGPUTransferBuffer(_: *GPUCompute) !void {

    }
    fn uploadToGPUBuffer() void {
        sdl.SDL_UploadToGPUBuffer(&copy_pass, &gpu_transfer_buffer_location, &gpu_buffer_reigon, true);
    }
    fn createGPUGraphicsPipeline() !void {

    }
};
