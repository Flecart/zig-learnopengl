const std = @import("std");
const glfw = @import("mach-glfw");
const gl = @import("zgl");
const math = @import("zlm");
const zigimg = @import("zigimg");

const Shader = @import("shader.zig").Shader;

const log = std.log.scoped(.Engine);

const SCR_WIDTH = 800;
const SCR_HEIGHT = 600;

fn glGetProcAddress(p: glfw.GLProc, proc: [:0]const u8) ?gl.binding.FunctionPointer {
    _ = p;
    return glfw.getProcAddress(proc);
}

/// Default GLFW error handling callback
fn errorCallback(error_code: glfw.ErrorCode, description: [:0]const u8) void {
    std.log.err("glfw: {}: {s}\n", .{ error_code, description });
}

pub fn main() !void {
    // glfw.setErrorCallback(errorCallback);
    if (!glfw.init(.{})) {
        std.log.err("failed to initialize GLFW: {?s}", .{glfw.getErrorString()});
        std.process.exit(1);
    }
    defer glfw.terminate();

    // Create our window
    const window = glfw.Window.create(640, 480, "Learn opengl", null, null, .{
        .opengl_profile = .opengl_core_profile,
        .context_version_major = 4,
        .context_version_minor = 4,
    }) orelse {
        std.log.err("failed to create GLFW window: {?s}", .{glfw.getErrorString()});
        std.process.exit(1);
    };
    defer window.destroy();
    glfw.makeContextCurrent(window);

    const proc: glfw.GLProc = undefined;
    try gl.loadExtensions(proc, glGetProcAddress);

    // build and compile our shader program
    // ------------------------------------
    // vertex shader
    const ourShader = Shader.init("./shaders/6.1.transform.vs", "./shaders/6.1.transform.fs");
    defer ourShader.destroy();
    // // set up vertex data (and buffer(s)) and configure vertex attributes
    // // ------------------------------------------------------------------

    // set up vertex data (and buffer(s)) and configure vertex attributes
    // ------------------------------------------------------------------
    const vertices = [_]f32{
        // positions          // texture coords
         0.5,  0.5, 0.0,   1.0, 1.0, // top right
         0.5, -0.5, 0.0,   1.0, 0.0, // bottom right
        -0.5, -0.5, 0.0,   0.0, 0.0, // bottom left
        -0.5,  0.5, 0.0,   0.0, 1.0  // top left 
    };

    const indices = [_]u32{
        0, 1, 3, // first triangle
        1, 2, 3  // second triangle
    };

    const vao = gl.genVertexArray();
    defer gl.deleteVertexArray(vao);
    const vbo = gl.genBuffer();
    defer gl.deleteBuffer(vbo);
    const ebo = gl.genBuffer();
    defer gl.deleteBuffer(ebo);

    // bind the Vertex Array Object first, then bind and set vertex buffer(s), and then configure vertex attributes(s).
    gl.bindVertexArray(vao);

    gl.bindBuffer(vbo, gl.BufferTarget.array_buffer);
    gl.bufferData(gl.BufferTarget.array_buffer, f32, &vertices, gl.BufferUsage.static_draw);

    gl.bindBuffer(ebo, gl.BufferTarget.element_array_buffer);
    gl.bufferData(gl.BufferTarget.element_array_buffer, u32, &indices, gl.BufferUsage.static_draw);

    // position attribute
    gl.vertexAttribPointer(0, 3, gl.Type.float, false, 5 * @sizeOf(f32), 0);
    gl.enableVertexAttribArray(0);

    // texture coord attribute
    gl.vertexAttribPointer(1, 2, gl.Type.float, false, 5 * @sizeOf(f32), 3 * @sizeOf(f32));
    gl.enableVertexAttribArray(1);

    // load and create a texture
    // -------------------------
    const texture1 = gl.genTexture();
    defer gl.deleteTexture(texture1);
    const texture2 = gl.genTexture();
    defer gl.deleteTexture(texture2);

    gl.bindTexture(texture1, gl.TextureTarget.@"2d");
    // set the texture wrapping parameters
    gl.texParameter(
        gl.TextureTarget.@"2d",
        gl.TextureParameter.wrap_s,
        gl.TextureParameterType(gl.TextureParameter.wrap_s).repeat
    );
    gl.texParameter(
        gl.TextureTarget.@"2d",
        gl.TextureParameter.wrap_t,
        gl.TextureParameterType(gl.TextureParameter.wrap_t).repeat
    );

    // set texture filtering parameters
    gl.texParameter(
        gl.TextureTarget.@"2d",
        gl.TextureParameter.min_filter,
        gl.TextureParameterType(gl.TextureParameter.min_filter).linear
    );
    gl.texParameter(
        gl.TextureTarget.@"2d",
        gl.TextureParameter.mag_filter,
        gl.TextureParameterType(gl.TextureParameter.mag_filter).linear
    );

    // at the time of writing zigimg does not support jpg, so we add png version of that.
    // load image, create texture and generate mipmaps
    var file = try std.fs.cwd().openFile("./textures/container.png", .{});
    defer file.close();

    var image =  try zigimg.Image.fromFile(std.heap.page_allocator, &file);
    defer image.deinit();

    std.log.info("len: {d}", .{image.pixels.len()});
    std.log.info("is indexed: {}", .{image.pixels.isIndexed()});

    gl.textureImage2D(gl.TextureTarget.@"2d", 
        0, 
        gl.TextureInternalFormat.rgb,
        image.width,
        image.height,
        gl.PixelFormat.rgb,
        gl.PixelType.unsigned_byte,
        image.pixels.asBytes().ptr
    );
    gl.generateMipmap(gl.TextureTarget.@"2d");

    gl.bindTexture(texture2, gl.TextureTarget.@"2d");

    var file2 = try std.fs.cwd().openFile("./textures/awesomeface.png", .{});
    defer file2.close();
    var image2 = try zigimg.Image.fromFile(std.heap.page_allocator, &file2);
    defer image2.deinit();

    gl.textureImage2D(
        gl.TextureTarget.@"2d",
        0,
        gl.TextureInternalFormat.rgba,
        image2.width,
        image2.height,
        gl.PixelFormat.rgba,
        gl.PixelType.unsigned_byte,
        image2.pixels.asBytes().ptr
    );
    gl.generateMipmap(gl.TextureTarget.@"2d");

    ourShader.use();
    ourShader.setInt("texture1", 0);
    ourShader.setInt("texture2", 1);

    // render loop
    // -----------
    while (!window.shouldClose()) {
        processInput(window);

        // render
        // ------
        gl.clearColor(0.2, 0.3, 0.3, 1.0);
        gl.clear(.{.color = true});

        gl.activeTexture(gl.TextureUnit.texture_0);
        gl.bindTexture(texture1, gl.TextureTarget.@"2d");
        gl.activeTexture(gl.TextureUnit.texture_1);
        gl.bindTexture(texture2, gl.TextureTarget.@"2d");

        // create transformations
        // const float_time: f32 = @floatCast(glfw.getTime());

        const model = math.Mat4.createAngleAxis(math.Vec3.new(1.0, 0.0, 0), math.toRadians(-55.0));

        // print model matrix
        // for (model.fields) |row| {
        //     std.log.info("{d} {d} {d} {d}", .{row[0], row[1], row[2], row[3]});
        // }

        // const tmp = math.Mat4.createAngleAxis(math.Vec3.new(0, 0, 1), float_time);
        const view = math.Mat4.createTranslation(math.Vec3.new(0.0, 0.0, -3.0));
        const projection = math.Mat4.createPerspective(math.toRadians(45.0), SCR_WIDTH / SCR_HEIGHT, 0.1, 100.0);

        // get matrix's uniform location and set matrix
        ourShader.use();
        ourShader.setMat4("model", model);
        ourShader.setMat4("view", view);
        ourShader.setMat4("projection", projection);

        gl.bindVertexArray(vao); // seeing as we only have a single vao there's no need to bind it every time, but we'll do so to keep things a bit more organized
        gl.drawElements(gl.PrimitiveType.triangles, 6, gl.ElementType.u32, 0);
        // gl.bindVertexArray(gl.VertexArray.invalid); // no need to unbind it every time

        // glfw: swap buffers and poll IO events (keys pressed/released, mouse moved etc.)
        // -------------------------------------------------------------------------------
        window.swapBuffers();
        glfw.pollEvents();
    }
}

// process all input: query GLFW whether relevant keys are pressed/released this frame and react accordingly
// ---------------------------------------------------------------------------------------------------------
fn processInput(window: glfw.Window) void {
    if (window.getKey(glfw.Key.escape) == glfw.Action.press) {
        window.setShouldClose(true);
    }
}
