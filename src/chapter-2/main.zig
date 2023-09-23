const std = @import("std");
const glfw = @import("mach-glfw");
const gl = @import("zgl");

const log = std.log.scoped(.Engine);

const SCR_WIDTH = 800;
const SCR_HEIGHT = 600;

const vertexShaderSource = [_][] const u8{
    \\#version 330 core
    \\layout (location = 0) in vec3 aPos;
    \\void main()
    \\{
    \\   gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);
    \\}
};


const fragmentShaderSource = [_][] const u8{
    \\#version 330 core
    \\out vec4 FragColor;
    \\void main()
    \\{
    \\   FragColor = vec4(1.0f, 0.5f, 0.2f, 1.0f);
    \\}
};

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
    const vertexShader = gl.createShader(gl.ShaderType.vertex);
    defer gl.deleteShader(vertexShader);
    gl.shaderSource(vertexShader, 1, &vertexShaderSource);
    gl.compileShader(vertexShader);


    var buffer: [100]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    // check for shader compile errors
    if (gl.getShader(vertexShader, gl.ShaderParameter.compile_status) == 0) {
        std.log.err("ERROR::SHADER::VERTEX::COMPILATION_FAILED\n{!s}\n", .{
            gl.getShaderInfoLog(vertexShader, allocator),
        });
    }

    // fragment shader
    const fragmentShader = gl.createShader(gl.ShaderType.fragment);
    defer gl.deleteShader(fragmentShader);
    gl.shaderSource(fragmentShader, 1, &fragmentShaderSource);
    gl.compileShader(fragmentShader);

    // check for shader compile errors
    if (gl.getShader(fragmentShader, gl.ShaderParameter.compile_status) == 0) {
        std.log.err("ERROR::SHADER::FRAGMENT::COMPILATION_FAILED\n{!s}\n", .{
            gl.getShaderInfoLog(fragmentShader, allocator),
        });
    }

    // link shaders
    const shaderProgram = gl.createProgram();
    defer gl.deleteProgram(shaderProgram);
    gl.attachShader(shaderProgram, vertexShader);
    gl.attachShader(shaderProgram, fragmentShader);
    gl.linkProgram(shaderProgram);

    // check for linking errors
    if (gl.getProgram(shaderProgram, gl.ProgramParameter.link_status) == 0) {
        std.log.err("ERROR::SHADER::PROGRAM::LINKING_FAILED\n{!s}\n", .{
            gl.getProgramInfoLog(shaderProgram, allocator),
        });
    }

    // set up vertex data (and buffer(s)) and configure vertex attributes
    // ------------------------------------------------------------------

    const vertices = [_]f32{
        // Original triangle coordinates
        // -0.5, -0.5, 0.0,
        // 0.5, -0.5, 0.0,
        // 0.0,  0.5, 0.0

        // Down here the coordinates used in the tutorial C code
        0.5,  0.5, 0.0,  // top right
        0.5, -0.5, 0.0,  // bottom right
        -0.5, -0.5, 0.0,  // bottom left
        -0.5,  0.5, 0.0   // top left 
    };

    const indices = [_]u32{
        0, 1, 3, // first triangle
        1, 2, 3, // second triangle
    };

    const vao = gl.genVertexArray();
    const vbo = gl.genBuffer();
    const ebo = gl.genBuffer();

    // optional: de-allocate all resources once they've outlived their purpose:
    // ------------------------------------------------------------------------
    defer {
        gl.deleteVertexArray(vao);
        gl.deleteBuffer(vbo);
        gl.deleteBuffer(ebo);
    }

    // bind the Vertex Array Object first, then bind and set vertex buffer(s), and then configure vertex attributes(s).
    gl.bindVertexArray(vao);

    gl.bindBuffer(vbo, gl.BufferTarget.array_buffer);
    gl.bufferData(gl.BufferTarget.array_buffer, f32, &vertices, gl.BufferUsage.static_draw);

    gl.bindBuffer(ebo, gl.BufferTarget.element_array_buffer);
    gl.bufferData(gl.BufferTarget.element_array_buffer, u32, &indices, gl.BufferUsage.static_draw);

    gl.vertexAttribPointer(0, 3, gl.Type.float, false, 3 * @sizeOf(f32), 0);
    gl.enableVertexAttribArray(0);

    // note that this is allowed, the call to glVertexAttribPointer registered vbo as the vertex attribute's bound vertex buffer object so afterwards we can safely unbind
    // gl.bindBuffer(gl.Buffer.invalid,  gl.BufferTarget.array_buffer);

    // remember: do NOT unbind the EBO while a VAO is active as the bound element buffer object IS stored in the VAO; keep the EBO bound.
    // gl.bindBuffer(gl.Buffer.invalid, gl.BufferTarget.element_array_buffer);

    // You can unbind the vao afterwards so other vao calls won't accidentally modify this vao, but this rarely happens. Modifying other
    // vaos requires a call to glBindVertexArray anyways so we generally don't unbind vaos (nor vbos) when it's not directly necessary.
    // gl.bindVertexArray(gl.VertexArray.invalid);

    // uncomment this call to draw in wireframe polygons.
    gl.polygonMode(gl.CullMode.front_and_back, gl.DrawMode.line);

    // render loop
    // -----------
    while (!window.shouldClose()) {
        processInput(window);

        // render
        // ------
        gl.clearColor(0.2, 0.3, 0.3, 1.0);
        gl.clear(.{.color = true});

        // draw our first triangle
        gl.useProgram(shaderProgram);
        gl.bindVertexArray(vao); // seeing as we only have a single vao there's no need to bind it every time, but we'll do so to keep things a bit more organized
        // gl.drawArrays(gl.PrimitiveType.triangles, 0, 3);
        gl.drawElements(gl.PrimitiveType.triangles, 6, gl.ElementType.u32, 0);
        // gl.bindVertexArray(gl.VertexArray.invalid); // no need to unbind it every time


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
