const std = @import("std");
const Error = @import("../core/error_handling.zig").ErrorHandle;
const sdl = @cImport(@cInclude("SDL3/SDL.h"));

const GPUError = error {
    FailedToCreateContext,
    CannotClaimWindow,
    FailedToCreateShaderObject,
    FailedToCreateGPUBuffer,
    FailedToAcquireCommandBuffer,
    FailedToCreateGraphicsPipeline,
    FailedToGetCopyPass,
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

pub const GPUCompute = struct {
    enable_validation_layers: bool = true,

    pub fn startGPU(self: *GPUCompute, window: ?*sdl.SDL_Window) !void {
        std.debug.assert(window != null);

        const gpu_context = try self.createDevice();
        try claimWindow(gpu_context, window);
        const command_buffer = try aquireGPUCommandBuffer(gpu_context);
        const copy_pass = try beginGPUCopyPass(command_buffer);
        _ = try createGPUBuffer(gpu_context);
        _ = try createGPUShader(gpu_context);
        uploadToGPUBuffer(copy_pass);
        _ = try createGPUGraphicsPipeline(gpu_context);
    }

    fn createDevice(self: *GPUCompute) GPUError!*sdl.SDL_GPUDevice{
        const gpu_device_context = sdl.SDL_CreateGPUDevice(sdl.SDL_GPU_SHADERFORMAT_SPIRV, self.enable_validation_layers, "vulkan");
        if (gpu_device_context == null) {
            std.log.err("Failed to create GPU context! {s}.", .{Error.sdlError()});
            return error.FailedToCreateContext;
        }
        std.log.debug("GPU Context: {*}", .{gpu_device_context});
        return gpu_device_context.?;
    }
    
    fn claimWindow(gpu_device_context: *sdl.SDL_GPUDevice, window: ?*sdl.SDL_Window) !void {
        const result = sdl.SDL_ClaimWindowForGPUDevice(gpu_device_context, window);
        if (!result) {
            return error.CannotClaimWindow;
        }
    }

    fn aquireGPUCommandBuffer(gpu_context: *sdl.SDL_GPUDevice) GPUError!*sdl.SDL_GPUCommandBuffer {
        const command_buffer = sdl.SDL_AcquireGPUCommandBuffer(gpu_context);
        if (command_buffer == null) {
            std.log.err("Failed to create GPU command buffer! {s}.", .{Error.sdlError()});
            return error.FailedToAcquireCommandBuffer;
        }
        return command_buffer.?;
    }

    fn beginGPUCopyPass(command_buffer: *sdl.SDL_GPUCommandBuffer) GPUError!*sdl.SDL_GPUCopyPass {
        const copy_pass = sdl.SDL_BeginGPUCopyPass(command_buffer);
        if (copy_pass == null) {
            return error.FailedToGetCopyPass;
        }
        return copy_pass.?;
    }

    fn createGPUShader(gpu_context: *sdl.SDL_GPUDevice) GPUError!*sdl.SDL_GPUShader {
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

        const shader_object = sdl.SDL_CreateGPUShader(gpu_context, &shader_create_info);
        if (shader_object == null) {
            std.log.err("Failed to create shader object: {s}.", .{Error.sdlError()});
            return error.FailedToCreateShaderObject;
        }
        std.log.debug("Shader: {*}", .{shader_object});
        return shader_object.?;
    }

    fn createGPUBuffer(gpu_context: *sdl.SDL_GPUDevice) GPUError!*sdl.SDL_GPUBuffer {
        const gpu_buffer_create_info: sdl.SDL_GPUBufferCreateInfo = .{
            .usage = sdl.SDL_GPU_BUFFERUSAGE_VERTEX,
            .size = @sizeOf([3]f32) * 3, // 3 verticies with 3 floats each
            .props = 0,
        };

        const gpu_buffer = sdl.SDL_CreateGPUBuffer(gpu_context, &gpu_buffer_create_info);
        if (gpu_buffer == null) {
            std.log.err("Failed to create GPU buffer: {s}.", .{Error.sdlError()});
            return error.FailedToCreateGPUBuffer;
        }
        std.log.debug("Shader: {*}", .{gpu_buffer});
        return gpu_buffer.?;
    }

    fn createGPUTransferBuffer(_: *GPUCompute) !void {

    }
    fn uploadToGPUBuffer(copy_pass: *sdl.SDL_GPUCopyPass) void {
        sdl.SDL_UploadToGPUBuffer(copy_pass, &gpu_transfer_buffer_location, &gpu_buffer_reigon, true);
    }
    fn createGPUGraphicsPipeline(gpu_context: ?*sdl.SDL_GPUDevice) GPUError!*sdl.SDL_GPUGraphicsPipeline {
        const graphics_pipeline_create_info: sdl.SDL_GPUGraphicsPipelineCreateInfo = .{
        };

        const graphics_pipeline = sdl.SDL_CreateGPUGraphicsPipeline(gpu_context, &graphics_pipeline_create_info);
        if (graphics_pipeline == null) {
            std.log.err("Failed to create graphics_pipeline: {s}.", .{Error.sdlError()});

        }
        return graphics_pipeline.?;
    }
};
