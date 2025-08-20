const std = @import("std");
const Error = @import("../core/error_handling.zig").ErrorHandle;
const sdl = @cImport(@cInclude("SDL3/SDL.h"));

const GPUError = error {
    WindowIsNull,
    FailedToCreateContext,
    CannotClaimWindow,
    FailedToCreateShaderObject,
    FailedToCreateGPUBuffer,
    FailedToAcquireCommandBuffer,
    FailedToCreateGraphicsPipeline,
    FailedToGetCopyPass,
    FailedToCreateTransferBuffer,
    FailedToCreateFillPipeline,
    FailedToCreateLinePipeline,
    FailedToCreateSwapchainTexture,
};


fn ptrToEmbedFile(filepath: []const u8) []const u8 {
    const file = @embedFile(filepath); 
    return file;
}

pub const GPUCompute = struct {
    enable_validation_layers: bool = true,

    pub fn startGPU(self: *GPUCompute, window: ?*sdl.SDL_Window) !void {
        if (window == null) {
            return error.WindowIsNull;
        }
        const window_ptr = window.?;

        const gpu_context = try self.createDevice();
        try claimWindow(gpu_context, window);
        const command_buffer = try aquireGPUCommandBuffer(gpu_context);
        const copy_pass = try beginGPUCopyPass(command_buffer);
        const gpu_buffer = try createGPUBuffer(gpu_context);

        const frag_file = comptime ptrToEmbedFile("../shader/vert.spv");
        const vert_file = comptime ptrToEmbedFile("../shader/frag.spv");

        const vertex_shader = try createGPUShader(gpu_context, vert_file, sdl.SDL_GPU_SHADERSTAGE_VERTEX);
        defer releaseShaders(gpu_context, vertex_shader);

        const fragment_shader = try createGPUShader(gpu_context, frag_file, sdl.SDL_GPU_SHADERSTAGE_FRAGMENT);
        defer releaseShaders(gpu_context, fragment_shader);
        
        const transfer_buffer = try createGPUTransferBuffer(gpu_context);

        uploadToGPUBuffer(copy_pass, transfer_buffer, gpu_buffer);
        const graphics_pipeline = try createGPUGraphicsPipeline(gpu_context, window_ptr, vertex_shader, fragment_shader);
        
        try drawSwapchain(command_buffer, window_ptr, graphics_pipeline);

        GPUQuit(gpu_context, window_ptr);
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

    fn createGPUGraphicsPipeline(gpu_context: *sdl.SDL_GPUDevice, window: *sdl.SDL_Window, vertex_shader: *sdl.SDL_GPUShader, fragment_shader: *sdl.SDL_GPUShader) GPUError!*sdl.SDL_GPUGraphicsPipeline {

        const color_target_descriptions: sdl.SDL_GPUColorTargetDescription = .{
            .format = sdl.SDL_GetGPUSwapchainTextureFormat(gpu_context, window),
        }; 

        var graphics_pipeline_create_info: sdl.SDL_GPUGraphicsPipelineCreateInfo = .{
            .target_info = .{
                .num_color_targets = 1,
                .color_target_descriptions = &color_target_descriptions,
            },

            .primitive_type = sdl.SDL_GPU_PRIMITIVETYPE_TRIANGLELIST,
            .vertex_shader = vertex_shader,
            .fragment_shader = fragment_shader,
        };

        graphics_pipeline_create_info.rasterizer_state.fill_mode = sdl.SDL_GPU_FILLMODE_FILL;
        const fill_pipeline: ?*sdl.SDL_GPUGraphicsPipeline = sdl.SDL_CreateGPUGraphicsPipeline(gpu_context, &graphics_pipeline_create_info);
        if (fill_pipeline == null) {
            std.log.err("Failed to create fill pipeline: {s}", .{Error.sdlError()});
            return error.FailedToCreateFillPipeline;
        }

        const graphics_pipeline = sdl.SDL_CreateGPUGraphicsPipeline(gpu_context, &graphics_pipeline_create_info);
        if (graphics_pipeline == null) {
            std.log.err("Failed to create graphics pipeline: {s}.", .{Error.sdlError()});
            return error.FailedToCreateGraphicsPipeline;
        }

        graphics_pipeline_create_info.rasterizer_state.fill_mode = sdl.SDL_GPU_FILLMODE_LINE;
        const line_pipeline = sdl.SDL_CreateGPUGraphicsPipeline(gpu_context, &graphics_pipeline_create_info);
        if (line_pipeline == null) {
            std.log.err("Failed to create line pipeline: {s}.", .{Error.sdlError()});
            return error.FailedToCreateLinePipeline;
        }

        return graphics_pipeline.?;
    }

    fn drawSwapchain(command_buffer: *sdl.SDL_GPUCommandBuffer, window: *sdl.SDL_Window, graphics_pipeline: *sdl.SDL_GPUGraphicsPipeline) !void {
        var swapchain_texture: ?*sdl.SDL_GPUTexture = null;

        if(!sdl.SDL_WaitAndAcquireGPUSwapchainTexture(command_buffer, window, &swapchain_texture, null, null)) {
            std.log.err("Failed to create wait and aquire swapchain: {s}.", .{Error.sdlError()});
            return error.FailedToCreateSwapchainTexture;
        }

        if (swapchain_texture != null) {
            const color_target_info: sdl.SDL_GPUColorTargetInfo = .{
                .texture = swapchain_texture,
                .clear_color = .{.a = 1.0, .b = 0.0, .g = 0.0, .r = 0.0 },
                .load_op = sdl.SDL_GPU_LOADOP_CLEAR,
                .store_op = sdl.SDL_GPU_STOREOP_STORE,
            };

            const num_color_targets: u32 = comptime 1;
            const render_pass: ?*sdl.SDL_GPURenderPass = sdl.SDL_BeginGPURenderPass(command_buffer, &color_target_info, num_color_targets, null);
            sdl.SDL_BindGPUGraphicsPipeline(render_pass, graphics_pipeline);
            
            const num_vertices: u32 = comptime 3;
            const num_instances: u32 = comptime 1;
            const first_vertex: u32 = comptime 0;
            const first_instance: u32 = comptime 0;

            sdl.SDL_DrawGPUPrimitives(render_pass, num_vertices, num_instances, first_vertex, first_instance);
        }

        _ = sdl.SDL_SubmitGPUCommandBuffer(command_buffer);

    }

    fn releaseShaders(gpu_context: *sdl.SDL_GPUDevice, shader: *sdl.SDL_GPUShader) void {
        sdl.SDL_ReleaseGPUShader(gpu_context, shader);
    }

    fn GPUQuit(gpu_context: *sdl.SDL_GPUDevice, window: *sdl.SDL_Window) void {
        sdl.SDL_ReleaseWindowFromGPUDevice(gpu_context, window);
        sdl.SDL_DestroyWindow(window);
        sdl.SDL_DestroyGPUDevice(gpu_context);
    }

};
