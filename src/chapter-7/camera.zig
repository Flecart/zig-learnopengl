const zlm = @import("zlm");
const glfw = @import("math-glfw");
const std = @import("std");

pub const CameraMovement = enum {
    forward,
    backward,
    left,
    right
};

const YAW: f32 = -90.0;
const PITCH: f32 = 0.0;
const SPEED: f32 = 2.5;
const SENSITIVITY: f32 = 0.1;
const ZOOM: f32 = 45.0;

pub const Camera = struct {
    const Self = @This();

    // camera attributes
    position: zlm.Vec3,
    front: zlm.Vec3,
    up: zlm.Vec3,
    right: zlm.Vec3,
    worldUp: zlm.Vec3,

    // euler angles
    yaw: f32,
    pitch: f32,

    // camera options
    movementSpeed: f32,
    mouseSensitivity: f32,
    zoom: f32,

    pub const default = Self.init(zlm.vec3(0, 0, 0), zlm.vec3(0, 1, 0), YAW, PITCH);

    pub fn init(position: zlm.Vec3, worldUp: zlm.Vec3, yaw: f32, pitch: f32) Self {
        var front = zlm.Vec3.zero;
        front.x = @cos(zlm.toRadians(yaw)) * @cos(zlm.toRadians(pitch));
        front.y = @sin(zlm.toRadians(pitch));
        front.z = @sin(zlm.toRadians(yaw)) * @cos(zlm.toRadians(pitch));
        front = front.normalize();

        const right = front.cross(worldUp).normalize();
        const up = right.cross(front).normalize();

        return Self {
            .position = position,
            .worldUp = worldUp,
            .yaw = yaw,
            .pitch = pitch,
            .front = front,
            .right = right,
            .up = up,
            .movementSpeed = SPEED,
            .mouseSensitivity = SENSITIVITY,
            .zoom = ZOOM,
        };
    }

    pub fn initXYZ(positionX: f32, positionY: f32, positionZ: f32, upX: f32, upY: f32, upZ: f32, yaw: f32, pitch: f32) Self {
        return Self.init(zlm.vec3(positionX, positionY, positionZ), zlm.vec3(upX, upY, upZ), yaw, pitch);
    }

    pub fn getViewMatrix(self: Self) zlm.Mat4 {
        return zlm.Mat4.createLook(self.position, self.front, self.up);
    }

    pub fn processKeyboard(self: *Self, direction: CameraMovement, deltaTime: f32) void {
        const velocity: f32 = self.movementSpeed * deltaTime;
        if (direction == CameraMovement.forward) {
            self.position = self.position.add(self.front.scale(velocity));
        }
        if (direction == CameraMovement.backward) {
            self.position = self.position.sub(self.front.scale(velocity));
        }
        if (direction == CameraMovement.left) {
            self.position = self.position.sub(self.right.scale(velocity));
        }
        if (direction == CameraMovement.right) {
            self.position = self.position.add(self.right.scale(velocity));
        }
    }

    pub fn processMouseMovement(self: *Self, xoffset: f32, yoffset: f32, constrainPitch: bool) void {
        const new_xoffset = xoffset * self.mouseSensitivity;
        const new_yoffset = yoffset * self.mouseSensitivity;

        self.yaw += new_xoffset;
        self.pitch += new_yoffset;

        // make sure that when pitch is out of bounds, screen doesn't get flipped
        if (constrainPitch) {
            if (self.pitch > 89.0) {
                self.pitch = 89.0;
            }
            if (self.pitch < -89.0) {
                self.pitch = -89.0;
            }
        }

        // update front, right and up Vectors using the updated Euler angles
        self.updateCameraVectors();
    }

    pub fn processMouseMovementWithConstrain(self: *Self, xoffset: f32, yoffset: f32) void {
        self.processMouseMovement(xoffset, yoffset, true);
    }

    pub fn processMouseScroll(self: *Self, yoffset: f32) void {
        self.zoom -= yoffset;
        if (self.zoom < 1.0) {
            self.zoom = 1.0;
        }
        if (self.zoom > 45.0) {
            self.zoom = 45.0;
        }
    }

    /// calculates the front vector from the Camera's (updated) Euler Angles
    fn updateCameraVectors(self: *Self) void {
        var front = zlm.Vec3.zero;
        front.x = @cos(zlm.toRadians(self.yaw)) * @cos(zlm.toRadians(self.pitch));
        front.y = @sin(zlm.toRadians(self.pitch));
        front.z = @sin(zlm.toRadians(self.yaw)) * @cos(zlm.toRadians(self.pitch));
        self.front = front.normalize();

        // also re-calculate the right and up vector
        self.right = self.front.cross(self.worldUp).normalize();
        self.up = self.right.cross(self.front).normalize();
    }
};
