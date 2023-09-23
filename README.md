# Zig LearnOpenGL!

This is an implementation in Pure zig [^1] of the *Getting Started* Chapter in [LearnOpenGL](https://learnopengl.com/Getting-started/Hello-Window).
It might be helpful for somebody trying to learn Zig and OpenGL at the same time!

## How to run

- Install the zig module dependencies with `zigmod fetch`
- Make sure you have OpenGL properly setup on your system and `glfw` installed

## See also

- [Zigatari](https://github.com/flecart/zigatari) a zig implementation of Atari, still work in progress (checked on 23 September 2023)

## Notes

Currently this project depends on `zigimg` in order to read the textures, it still doesn´t  support `JPEG` formats but it' looking for contributors!


[^1]: this repo depends on some wrappers on OpenGL, so you need that installed on your system