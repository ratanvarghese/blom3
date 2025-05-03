const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const feed_exe = b.addExecutable(.{
        .name = "blom-feed",
        .root_source_file = b.path("src/blom-feed.zig"),
        .target = target,
        .optimize = optimize,
    });
    feed_exe.linkSystemLibrary("mxml");
    feed_exe.linkSystemLibrary("pthread");
    feed_exe.linkLibC();
    b.installArtifact(feed_exe);

    const article_exe = b.addExecutable(.{
        .name = "blom-article",
        .root_source_file = b.path("src/blom-article.zig"),
        .target = target,
        .optimize = optimize,
    });
    article_exe.linkSystemLibrary("sqlite3");
    article_exe.linkSystemLibrary("pthread");
    article_exe.linkLibC();
    b.installArtifact(article_exe);
}
