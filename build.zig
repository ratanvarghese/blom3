const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const archive_exe = b.addExecutable("blom-archive", "src/blom-archive.zig");
    archive_exe.setTarget(target);
    archive_exe.setBuildMode(mode);
    archive_exe.linkSystemLibraryName("mon13");
    archive_exe.linkSystemLibraryName("pthread");
    archive_exe.linkLibC();
    archive_exe.install();

    const tqdate_exe = b.addExecutable("blom-tqdate", "src/blom-tqdate.zig");
    tqdate_exe.setTarget(target);
    tqdate_exe.setBuildMode(mode);
    tqdate_exe.linkSystemLibraryName("mon13");
    tqdate_exe.linkSystemLibraryName("pthread");
    tqdate_exe.linkLibC();
    tqdate_exe.install();

    const feed_exe = b.addExecutable("blom-feed", "src/blom-feed.zig");
    feed_exe.setTarget(target);
    feed_exe.setBuildMode(mode);
    feed_exe.linkSystemLibraryName("mxml");
    feed_exe.linkSystemLibraryName("pthread");
    feed_exe.linkLibC();
    feed_exe.install();

    const article_exe = b.addExecutable("blom-article", "src/blom-article.zig");
    article_exe.setTarget(target);
    article_exe.setBuildMode(mode);
    article_exe.linkSystemLibraryName("sqlite3");
    article_exe.linkSystemLibraryName("pthread");
    article_exe.linkLibC();
    article_exe.install();
}
