const std = @import("std");
const zigimg = @import("zigimg");

pub fn main() !void {
    var allocator = std.heap.page_allocator;

    // print current cwd

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    std.log.info("cwd: {s}", .{
        try std.fs.cwd().realpathAlloc(alloc, "."),
    });

    var file = try std.fs.cwd().openFile("./textures/container.png", .{});
    defer file.close();

    var image =  try zigimg.Image.fromFile(allocator, &file);

    std.debug.print("Image: {d}, {d}\n", .{image.width, image.height});
}
