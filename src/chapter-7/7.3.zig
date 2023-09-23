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

var cameraPos = math.vec3(0.0, 0.0, 3.0);
var cameraFront = math.vec3(0.0, 0.0, -1.0);
var cameraUp = math.vec3(0.0, 1.0, 0.0);

var firstMouse: bool = true;
var yaw: f32 = -90.0; // yaw is initialized to -90.0 degrees since a yaw of 0.0 results in a direction vector pointing to the right so we initially rotate a bit to the left.
var pitch: f32 = 0.0;
var lastX: f32 = @as(f32, SCR_WIDTH) / 2.0;
var lastY: f32 = @as(f32, SCR_HEIGHT) / 2.0;
var fov: f32 = 45.0;

// timing
var deltaTime: f32 = 0.0; // time between current frame and last frame
var lastFrame: f32 = 0.0;

fn scrollCallback(window: glfw.Window, xoffset: f64, yoffset: f64) void {
    _ = window;
    _ = xoffset;

    fov -= @as(f32, @floatCast(yoffset));
    if (fov < 1.0) {
        fov = 1.0;
    } else if (fov > 45.0) {
        fov = 45.0;
    }
}

fn cursorPosCallback(window: glfw.Window, xposIn: f64, yposIn: f64) void {
    _ = window;

    const xpos = @as(f32, @floatCast(xposIn));
    const ypos = @as(f32, @floatCast(yposIn));

    if (firstMouse) {
        lastX = xpos;
        lastY = ypos;
        firstMouse = false;
    }

    const xoffset = xpos - lastX;
    const yoffset = lastY - ypos; // reversed since y-coordinates go from bottom to top
    lastX = xpos;
    lastY = ypos;

    const sensitivity: f32 = 0.1; // change this value to your liking
    yaw += xoffset * sensitivity;
    pitch += yoffset * sensitivity;

    if (pitch > 89.0) {
        pitch = 89.0;
    } else if (pitch < -89.0) {
        pitch = -89.0;
    }

    var front = math.vec3(
        @cos(math.toRadians(yaw)) * @cos(math.toRadians(pitch)),
        @sin(math.toRadians(pitch)),
        @sin(math.toRadians(yaw)) * @cos(math.toRadians(pitch))
    );

    cameraFront = front.normalize();
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
    window.setCursorPosCallback(cursorPosCallback);
    window.setScrollCallback(scrollCallback);

    // tell GLFW to capture our mouse
    window.setInputModeCursor(glfw.Window.InputModeCursor.disabled);    

    const proc: glfw.GLProc = undefined;
    try gl.loadExtensions(proc, glGetProcAddress);
    gl.enable(gl.Capabilities.depth_test);


    // build and compile our shader program
    // ------------------------------------
    // vertex shader
    const ourShader = Shader.init("./shaders/7.1.transform.vs", "./shaders/7.1.transform.fs");
    defer ourShader.destroy();
    // // set up vertex data (and buffer(s)) and configure vertex attributes
    // // ------------------------------------------------------------------

    // set up vertex data (and buffer(s)) and configure vertex attributes
    // ------------------------------------------------------------------
    const vertices = [_]f32{
        -0.5, -0.5, -0.5,  0.0, 0.0,
        0.5, -0.5, -0.5,  1.0, 0.0,
        0.5,  0.5, -0.5,  1.0, 1.0,
        0.5,  0.5, -0.5,  1.0, 1.0,
        -0.5,  0.5, -0.5,  0.0, 1.0,
        -0.5, -0.5, -0.5,  0.0, 0.0,

        -0.5, -0.5,  0.5,  0.0, 0.0,
        0.5, -0.5,  0.5,  1.0, 0.0,
        0.5,  0.5,  0.5,  1.0, 1.0,
        0.5,  0.5,  0.5,  1.0, 1.0,
        -0.5,  0.5,  0.5,  0.0, 1.0,
        -0.5, -0.5,  0.5,  0.0, 0.0,

        -0.5,  0.5,  0.5,  1.0, 0.0,
        -0.5,  0.5, -0.5,  1.0, 1.0,
        -0.5, -0.5, -0.5,  0.0, 1.0,
        -0.5, -0.5, -0.5,  0.0, 1.0,
        -0.5, -0.5,  0.5,  0.0, 0.0,
        -0.5,  0.5,  0.5,  1.0, 0.0,

        0.5,  0.5,  0.5,  1.0, 0.0,
        0.5,  0.5, -0.5,  1.0, 1.0,
        0.5, -0.5, -0.5,  0.0, 1.0,
        0.5, -0.5, -0.5,  0.0, 1.0,
        0.5, -0.5,  0.5,  0.0, 0.0,
        0.5,  0.5,  0.5,  1.0, 0.0,

        -0.5, -0.5, -0.5,  0.0, 1.0,
        0.5, -0.5, -0.5,  1.0, 1.0,
        0.5, -0.5,  0.5,  1.0, 0.0,
        0.5, -0.5,  0.5,  1.0, 0.0,
        -0.5, -0.5,  0.5,  0.0, 0.0,
        -0.5, -0.5, -0.5,  0.0, 1.0,

        -0.5,  0.5, -0.5,  0.0, 1.0,
        0.5,  0.5, -0.5,  1.0, 1.0,
        0.5,  0.5,  0.5,  1.0, 0.0,
        0.5,  0.5,  0.5,  1.0, 0.0,
        -0.5,  0.5,  0.5,  0.0, 0.0,
        -0.5,  0.5, -0.5,  0.0, 1.0
    };

    const cubePositions = [_]math.Vec3 {
        math.Vec3.new( 0.0,  0.0,  0.0),
        math.Vec3.new( 2.0,  5.0, -15.0), 
        math.Vec3.new(-1.5, -2.2, -2.5),  
        math.Vec3.new(-3.8, -2.0, -12.3),  
        math.Vec3.new( 2.4, -0.4, -3.5),  
        math.Vec3.new(-1.7,  3.0, -7.5),  
        math.Vec3.new( 1.3, -2.0, -2.5),  
        math.Vec3.new( 1.5,  2.0, -2.5), 
        math.Vec3.new( 1.5,  0.2, -1.5), 
        math.Vec3.new(-1.3,  1.0, -1.5)  
    };

    const vao = gl.genVertexArray();
    defer gl.deleteVertexArray(vao);
    const vbo = gl.genBuffer();
    defer gl.deleteBuffer(vbo);

    // bind the Vertex Array Object first, then bind and set vertex buffer(s), and then configure vertex attributes(s).
    gl.bindVertexArray(vao);

    gl.bindBuffer(vbo, gl.BufferTarget.array_buffer);
    gl.bufferData(gl.BufferTarget.array_buffer, f32, &vertices, gl.BufferUsage.static_draw);

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
    
    // pass projection matrix to shader (as projection matrix rarely changes there's no need to do this per frame)
    // -----------------------------------------------------------------------------------------------------------
    // render loop
    // -----------
    while (!window.shouldClose()) {
        // per-frame time logic
        const currentFrame: f32 = @floatCast(glfw.getTime());
        deltaTime = currentFrame - lastFrame;
        lastFrame = currentFrame;

        processInput(window);

        // render
        // ------
        gl.clearColor(0.2, 0.3, 0.3, 1.0);
        gl.clear(.{.color = true, .depth = true});

        gl.activeTexture(gl.TextureUnit.texture_0);
        gl.bindTexture(texture1, gl.TextureTarget.@"2d");
        gl.activeTexture(gl.TextureUnit.texture_1);
        gl.bindTexture(texture2, gl.TextureTarget.@"2d");

        // get matrix's uniform location and set matrix
        // const view = math.Mat4.createTranslation(math.Vec3.new(0.0, 0.0, -3));
        ourShader.use();

        const view = math.Mat4.createLook(
            cameraPos,
            cameraFront,
            cameraUp
        );

        ourShader.setMat4("view", view);
        const projection = math.Mat4.createPerspective(math.toRadians(fov), SCR_WIDTH / SCR_HEIGHT, 0.1, 100.0);
        ourShader.setMat4("projection", projection);

        gl.bindVertexArray(vao); // seeing as we only have a single vao there's no need to bind it every time, but we'll do so to keep things a bit more organized

        // render boxes
        for (cubePositions, 0..) |pos, i| {
            const model = math.Mat4.createTranslation(pos);
            const angle = 20.0 * @as(f32, @floatFromInt(i));
            const rotation = math.Mat4.createAngleAxis(math.vec3(1.0, 0.3, 0.5), math.toRadians(angle));
            ourShader.setMat4("model", rotation.mul(model));

            gl.drawArrays(gl.PrimitiveType.triangles, 0, 36);
        }
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

    const cameraSpeed = 2.5 * deltaTime;
    if (window.getKey(glfw.Key.w) == glfw.Action.press) {
        cameraPos = cameraPos.add(cameraFront.scale(cameraSpeed));
    }
    if (window.getKey(glfw.Key.s) == glfw.Action.press) {
        cameraPos = cameraPos.sub(cameraFront.scale(cameraSpeed));
    }
    if (window.getKey(glfw.Key.a) == glfw.Action.press) {
        cameraPos = cameraPos.sub(cameraFront.cross(cameraUp).scale(cameraSpeed));
    }
    if (window.getKey(glfw.Key.d) == glfw.Action.press) {
        cameraPos = cameraPos.add(cameraFront.cross(cameraUp).scale(cameraSpeed));
    }
}
