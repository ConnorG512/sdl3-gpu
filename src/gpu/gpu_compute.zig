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
    FailedToCreateTransferBuffer,
};


fn ptrToEmbedFile(filepath: []const u8) []const u8 {
    const file = @embedFile(filepath); 
    return file;
}

pub const GPUCompute = struct {
    enable_validation_layers: bool = true,

    pub fn startGPU(self: *GPUCompute, window: ?*sdl.SDL_Window) !void {
        std.debug.assert(window != null);

        const gpu_context = try self.createDevice();
        try claimWindow(gpu_context, window);
        const command_buffer = try aquireGPUCommandBuffer(gpu_context);
        const copy_pass = try beginGPUCopyPass(command_buffer);
        const gpu_buffer = try createGPUBuffer(gpu_context);

        const frag_file = comptime ptrToEmbedFile("../shader/vert.spv");
        const vert_file = comptime ptrToEmbedFile("../shader/frag.spv");
        const vertex_shader = try createGPUShader(gpu_context, vert_file, sdl.SDL_GPU_SHADERSTAGE_VERTEX);
        const fragment_shader = try createGPUShader(gpu_context, frag_file, sdl.SDL_GPU_SHADERSTAGE_FRAGMENT);
        const transfer_buffer = try createGPUTransferBuffer(gpu_context);

        uploadToGPUBuffer(copy_pass, transfer_buffer, gpu_buffer);
        _ = try createGPUGraphicsPipeline(gpu_context, vertex_shader, fragment_shader);
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

    fn createGPUShader(gpu_context: *sdl.SDL_GPUDevice, shader_file: []const u8, shader_stage: sdl.SDL_GPUShaderStage) GPUError!*sdl.SDL_GPUShader {

        const shader_create_info: sdl.SDL_GPUShaderCreateInfo = .{
            .code = shader_file.ptr,
            .code_size = shader_file.len,
            .entrypoint = "main",
            .format = sdl.SDL_GPU_SHADERFORMAT_SPIRV, 
            .stage = shader_stage,
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

    fn createGPUTransferBuffer(gpu_context: *sdl.SDL_GPUDevice) GPUError!*sdl.SDL_GPUTransferBuffer {
        const transfer_buffer_create_info: sdl.SDL_GPUTransferBufferCreateInfo = .{
            .props = 0,
            .size = 4096,
            .usage = sdl.SDL_GPU_TRANSFERBUFFERUSAGE_UPLOAD,
        };
        const transfer_buffer = sdl.SDL_CreateGPUTransferBuffer(gpu_context, &transfer_buffer_create_info);
        if (transfer_buffer == null) {
            std.log.err("Failed to create Transfer Buffer: {s}.", .{Error.sdlError()});
            return error.FailedToCreateTransferBuffer;
        }
        std.log.debug("Transfer Buffer: {*}", .{transfer_buffer});
        return transfer_buffer.?;
    }

    fn uploadToGPUBuffer(copy_pass: *sdl.SDL_GPUCopyPass, transfer_buffer: ?*sdl.SDL_GPUTransferBuffer, gpu_buffer: *sdl.SDL_GPUBuffer) void {
        std.debug.assert(transfer_buffer != null);
        const gpu_buffer_reigon_size: u32 = comptime 4096; 

        const gpu_transfer_buffer_location: sdl.SDL_GPUTransferBufferLocation = .{
            .offset = 0,
            .transfer_buffer = transfer_buffer,
        };
        const gpu_buffer_reigon: sdl.SDL_GPUBufferRegion = .{
            .offset = 0,
            .buffer = gpu_buffer,
            .size = gpu_buffer_reigon_size,
        };

        sdl.SDL_UploadToGPUBuffer(copy_pass, &gpu_transfer_buffer_location, &gpu_buffer_reigon, true);
    }

    fn createGPUGraphicsPipeline(gpu_context: ?*sdl.SDL_GPUDevice, vertex_shader: *sdl.SDL_GPUShader, fragment_shader: *sdl.SDL_GPUShader) GPUError!*sdl.SDL_GPUGraphicsPipeline {
        const color_target_descriptions: sdl.SDL_GPUColorTargetDescription = .{
            .blend_state = undefined,
            .format = sdl.SDL_GPU_TEXTUREFORMAT_B8G8R8A8_UNORM_SRGB,
        };

        const graphics_pipeline_create_info: sdl.SDL_GPUGraphicsPipelineCreateInfo = .{
            .target_info = .{
                .num_color_targets = 1,
                .color_target_descriptions = &color_target_descriptions,
            },
            .fragment_shader = fragment_shader,
            .vertex_shader = vertex_shader,
        };

        const graphics_pipeline = sdl.SDL_CreateGPUGraphicsPipeline(gpu_context, &graphics_pipeline_create_info);
        if (graphics_pipeline == null) {
            std.log.err("Failed to create graphics_pipeline: {s}.", .{Error.sdlError()});

        }
        return graphics_pipeline.?;
    }

};
