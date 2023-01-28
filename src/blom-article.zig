const std = @import("std");

const sqlite3c = @cImport({
    @cInclude("sqlite3.h");
});

const getopt = @import("getopt.zig");

const MAX_TAGS = 32;

pub fn int64_callback(
    result_opt: ?*anyopaque,
    col_count: c_int,
    col_texts_opt: ?[*:null]?[*:0]const u8,
    _: ?[*:null]?[*:0]u8,
) callconv(.C) c_int {
    if (result_opt) |result_opaque| {
        const col_texts = col_texts_opt orelse return 0;
        var i: usize = 0;
        while (i < col_count) : (i += 1) {
            var result = @ptrCast(*i64, @alignCast(@alignOf(i64), result_opaque));
            if (col_texts[i]) |cell| {
                result.* = std.fmt.parseInt(i64, std.mem.sliceTo(cell, 0), 10) catch 0;
            }
        }
    }

    return 0;
}

fn bind_text(db: *sqlite3c.sqlite3, stmt: ?*sqlite3c.sqlite3_stmt, param: c_int, x: []const u8) !void {
    if (sqlite3c.sqlite3_bind_text(stmt, param, @ptrCast([*c]const u8, x), @intCast(c_int, x.len), null) != 0) {
        std.debug.print("{s}\n", .{sqlite3c.sqlite3_errmsg(db)});
        return error.DatabaseBindError;
    }
}

fn bind_int64(db: *sqlite3c.sqlite3, stmt: ?*sqlite3c.sqlite3_stmt, param: c_int, x: i64) !void {
    if (sqlite3c.sqlite3_bind_int64(stmt, param, x) != 0) {
        std.debug.print("{s}\n", .{sqlite3c.sqlite3_errmsg(db)});
        return error.DatabaseBindError;
    }
}

fn step(db: *sqlite3c.sqlite3, stmt: ?*sqlite3c.sqlite3_stmt) !void {
    const step_result = sqlite3c.sqlite3_step(stmt);
    if (step_result != 101 and step_result != 100) {
        std.debug.print("{s}\n", .{sqlite3c.sqlite3_errmsg(db)});
        return error.DatabaseStepError;
    }
}

fn selectInt64(db: *sqlite3c.sqlite3, default: i64, query: []const u8) !i64 {
    var new_id: i64 = default;
    const new_id_err = sqlite3c.sqlite3_exec(db, query.ptr, int64_callback, &new_id, null);
    if (new_id_err != 0) {
        std.debug.print("{s}\n", .{sqlite3c.sqlite3_errmsg(db)});
        return error.DatabaseSelectInt64Error;
    }
    return new_id;
}

fn selectExists(db: *sqlite3c.sqlite3, text: []const u8, query: []const u8) !bool {
    var stmt: ?*sqlite3c.sqlite3_stmt = null;
    if (sqlite3c.sqlite3_prepare_v2(db, query.ptr, @intCast(c_int, query.len), &stmt, null) != 0) {
        std.debug.print("{s}\n", .{sqlite3c.sqlite3_errmsg(db)});
        return error.DatabasePrepareError;
    }
    defer _ = sqlite3c.sqlite3_finalize(stmt);

    try bind_text(db, stmt, 1, text);
    try step(db, stmt);

    const result = sqlite3c.sqlite3_column_int(stmt, 0);
    return result > 0;
}

const parameters = struct {
    class: ?[]const u8,
    db_file: []const u8,
    tags: [MAX_TAGS]?[]const u8,
    tag_count: usize,
    md_file: ?[]const u8,
    published: ?[]const u8,
    title: ?[]const u8,
    url: []const u8,

    fn articleExists(self: parameters, db: *sqlite3c.sqlite3) !bool {
        return selectExists(db, self.url, "SELECT COUNT(*) FROM articles WHERE url = @url;");
    }

    fn createModeValidate(self: parameters) !void {
        if (self.tag_count == 0) {
            std.debug.print("Cannot create article without tags.\n", .{});
            return error.CannotCreateWithoutTags;
        }
        if (self.md_file == null) {
            std.debug.print("Cannot create article without Markdown content file.\n", .{});
            return error.CannotCreateWithoutContent;
        }
        if (self.title == null) {
            std.debug.print("Cannot create article without title.\n", .{});
            return error.CannotCreateWithoutTitle;
        }
    }

    fn getContent(self: parameters, mtime: *i64, ctime: *i64, md_allocator: std.mem.Allocator) ![]u8 {
        const md_file = try std.fs.cwd().openFile((self.md_file orelse unreachable), .{ .read = true });
        defer md_file.close();
        const md_stat = try md_file.stat();
        mtime.* = @intCast(i64, @divFloor(md_stat.mtime, 1_000_000_000));
        ctime.* = @intCast(i64, @divFloor(md_stat.ctime, 1_000_000_000));
        var md_buffer = try md_allocator.alloc(u8, md_stat.size);
        _ = try md_file.readAll(md_buffer);
        return md_buffer;
    }

    fn createNewArticle(self: parameters, db: *sqlite3c.sqlite3) !void {
        const new_id = try selectInt64(db, 1, "SELECT COALESCE(MAX(id),0) + 1 FROM articles;");

        const insert_query =
            \\INSERT INTO articles (id, url, title, date_modified, date_published, content_md)
            \\VALUES
            \\  (
            \\    @id,
            \\    @url,
            \\    @title,
            \\    STRFTIME('%Y-%m-%dT%H:%M:%f', @date_modified, 'unixepoch'),
            \\    STRFTIME('%Y-%m-%dT%H:%M:%f', @date_published, 'unixepoch'),
            \\    @content_md
            \\  )
            \\;
        ;
        var stmt: ?*sqlite3c.sqlite3_stmt = null;
        if (sqlite3c.sqlite3_prepare_v2(db, insert_query, insert_query.len, &stmt, null) != 0) {
            std.debug.print("{s}\n", .{sqlite3c.sqlite3_errmsg(db)});
            return error.DatabaseInsertPrepareError;
        }
        defer _ = sqlite3c.sqlite3_finalize(stmt);

        var mtime: i64 = 0;
        var ctime: i64 = 0;
        const md_allocator = std.heap.page_allocator; //suitable for an entire article.
        var md_buffer = try self.getContent(&mtime, &ctime, md_allocator);
        defer md_allocator.free(md_buffer);

        try bind_int64(db, stmt, 1, new_id);
        try bind_text(db, stmt, 2, self.url);
        try bind_text(db, stmt, 3, (self.title orelse unreachable));
        try bind_int64(db, stmt, 4, mtime);
        if (self.published) |published| {
            try bind_text(db, stmt, 5, published);
        } else {
            try bind_int64(db, stmt, 5, ctime);
        }
        try bind_text(db, stmt, 6, md_buffer);

        try step(db, stmt);
    }

    fn updateClass(self: parameters, db: *sqlite3c.sqlite3) !void {
        const class = self.class orelse return;
        const insert_query =
            \\UPDATE articles
            \\  SET class = @class
            \\WHERE url = @url;
        ;
        var stmt: ?*sqlite3c.sqlite3_stmt = null;
        if (sqlite3c.sqlite3_prepare_v2(db, insert_query, insert_query.len, &stmt, null) != 0) {
            std.debug.print("{s}\n", .{sqlite3c.sqlite3_errmsg(db)});
            return error.DatabaseInsertPrepareError;
        }
        try bind_text(db, stmt, 1, class);
        try bind_text(db, stmt, 2, self.url);
        try step(db, stmt);
    }

    fn updateTitle(self: parameters, db: *sqlite3c.sqlite3) !void {
        const title = self.title orelse return;
        const insert_query =
            \\UPDATE articles
            \\  SET title = @title
            \\WHERE url = @url;
        ;
        var stmt: ?*sqlite3c.sqlite3_stmt = null;
        if (sqlite3c.sqlite3_prepare_v2(db, insert_query, insert_query.len, &stmt, null) != 0) {
            std.debug.print("{s}\n", .{sqlite3c.sqlite3_errmsg(db)});
            return error.DatabaseInsertPrepareError;
        }
        try bind_text(db, stmt, 1, title);
        try bind_text(db, stmt, 2, self.url);
        try step(db, stmt);
    }

    fn updateModified(self: parameters, db: *sqlite3c.sqlite3) !void {
        const insert_query =
            \\UPDATE articles
            \\  SET date_modified = STRFTIME('%Y-%m-%dT%H:%M:%f')
            \\WHERE url = @url;
        ;
        var stmt: ?*sqlite3c.sqlite3_stmt = null;
        if (sqlite3c.sqlite3_prepare_v2(db, insert_query, insert_query.len, &stmt, null) != 0) {
            std.debug.print("{s}\n", .{sqlite3c.sqlite3_errmsg(db)});
            return error.DatabaseInsertPrepareError;
        }
        try bind_text(db, stmt, 1, self.url);
        try step(db, stmt);
    }

    fn updateContent(self: parameters, db: *sqlite3c.sqlite3) !void {
        if (self.md_file == null) {
            return;
        }
        const insert_query =
            \\UPDATE articles
            \\  SET content_md = @content_md
            \\WHERE url = @url;
        ;
        var stmt: ?*sqlite3c.sqlite3_stmt = null;
        if (sqlite3c.sqlite3_prepare_v2(db, insert_query, insert_query.len, &stmt, null) != 0) {
            std.debug.print("{s}\n", .{sqlite3c.sqlite3_errmsg(db)});
            return error.DatabaseInsertPrepareError;
        }

        var mtime: i64 = 0;
        var ctime: i64 = 0;
        const md_allocator = std.heap.page_allocator; //suitable for an entire article.
        var md_buffer = try self.getContent(&mtime, &ctime, md_allocator);
        defer md_allocator.free(md_buffer);

        try bind_text(db, stmt, 1, md_buffer);
        try bind_text(db, stmt, 2, self.url);

        try step(db, stmt);
    }

    fn updateTagsForArticle(self: parameters, db: *sqlite3c.sqlite3) !void {
        const delete_query =
            \\DELETE FROM article_tags
            \\WHERE article_id = (SELECT id FROM articles WHERE url = @url);
        ;
        var del_stmt: ?*sqlite3c.sqlite3_stmt = null;
        if (sqlite3c.sqlite3_prepare_v2(db, delete_query, delete_query.len, &del_stmt, null) != 0) {
            std.debug.print("{s}\n", .{sqlite3c.sqlite3_errmsg(db)});
            return error.DatabaseInsertPrepareError;
        }
        try bind_text(db, del_stmt, 1, self.url);
        try step(db, del_stmt);

        var tag_i: usize = 0;
        while (tag_i < self.tag_count) : (tag_i += 1) {
            const tag = self.tags[tag_i] orelse return error.MisingTag;

            const insert_query =
                \\INSERT INTO article_tags (article_id, tag_id)
                \\VALUES
                \\  (
                \\    (SELECT id FROM articles WHERE url = @url),
                \\    (SELECT id FROM tags WHERE name = @name)
                \\  )
                \\;
            ;
            var stmt: ?*sqlite3c.sqlite3_stmt = null;
            if (sqlite3c.sqlite3_prepare_v2(db, insert_query, insert_query.len, &stmt, null) != 0) {
                std.debug.print("{s}\n", .{sqlite3c.sqlite3_errmsg(db)});
                return error.DatabaseInsertPrepareError;
            }
            defer _ = sqlite3c.sqlite3_finalize(stmt);

            try bind_text(db, stmt, 1, self.url);
            try bind_text(db, stmt, 2, tag);
            try step(db, stmt);
        }
    }

    fn ensureTagsExist(self: parameters, db: *sqlite3c.sqlite3) !void {
        var tag_i: usize = 0;
        while (tag_i < self.tag_count) : (tag_i += 1) {
            const tag = self.tags[tag_i] orelse return error.MisingTag;
            const exist = try selectExists(db, tag, "SELECT COUNT(id) FROM tags WHERE name = @tag;");
            if (!exist) {
                var stdout = std.io.getStdOut().writer();
                try stdout.print("Adding tag '{s}'.\n", .{tag});

                const insert_query =
                    \\INSERT INTO tags (id, name)
                    \\VALUES
                    \\  ((SELECT COALESCE(MAX(id),0) + 1 FROM tags), @name)
                    \\;
                ;
                var stmt: ?*sqlite3c.sqlite3_stmt = null;
                if (sqlite3c.sqlite3_prepare_v2(db, insert_query, insert_query.len, &stmt, null) != 0) {
                    std.debug.print("{s}\n", .{sqlite3c.sqlite3_errmsg(db)});
                    return error.DatabaseInsertPrepareError;
                }
                defer _ = sqlite3c.sqlite3_finalize(stmt);

                try bind_text(db, stmt, 1, tag);
                try step(db, stmt);
            }
        }
    }

    fn updateTags(self: parameters, db: *sqlite3c.sqlite3) !void {
        if (self.tag_count > 0) {
            try self.ensureTagsExist(db);
            try self.updateTagsForArticle(db);
        }
    }
};

fn getParameters() !parameters {
    var c: ?[]const u8 = null;
    var d: ?[]const u8 = null;
    var g: [MAX_TAGS]?[]const u8 = [_]?[]const u8{null} ** MAX_TAGS;
    var g_count: usize = 0;
    var m: ?[]const u8 = null;
    var t: ?[]const u8 = null;
    var u: ?[]const u8 = null;
    var p: ?[]const u8 = null;
    var opts = getopt.getopt("c:d:g:m:p:t:u:");
    while (opts.next()) |maybe_opt| {
        if (maybe_opt) |opt| {
            switch (opt.opt) {
                'c' => {
                    c = opt.arg.?;
                },
                'd' => {
                    d = opt.arg.?;
                },
                'g' => {
                    g[g_count] = opt.arg.?;
                    g_count += 1;
                },
                'm' => {
                    m = opt.arg.?;
                },
                'p' => {
                    p = opt.arg.?;
                },
                't' => {
                    t = opt.arg.?;
                },
                'u' => {
                    u = opt.arg.?;
                },
                else => unreachable,
            }
        } else break;
    } else |err| {
        switch (err) {
            getopt.Error.InvalidOption => std.debug.print("Invalid option: {c}\n", .{opts.optopt}),
            getopt.Error.MissingArgument => std.debug.print("Option requires an argument: {c}\n", .{opts.optopt}),
        }
        return err;
    }

    var result: parameters = undefined;
    result.class = c;
    result.db_file = d orelse {
        std.debug.print("No database file specified.\n", .{});
        return error.NoDatabaseFileSpecified;
    };
    std.mem.copy(?[]const u8, result.tags[0..], g[0..]);
    result.tag_count = g_count;
    result.md_file = m;
    result.published = p;
    result.title = t;
    result.url = u orelse {
        std.debug.print("No article URL specified.\n", .{});
        return error.NoUrlSpecified;
    };
    return result;
}

pub fn main() !void {
    const params = try getParameters();

    var db_opt: ?*sqlite3c.sqlite3 = null;
    const open_error = sqlite3c.sqlite3_open(@ptrCast([*:0]const u8, params.db_file), &db_opt);
    defer _ = sqlite3c.sqlite3_close(db_opt);
    const db = db_opt orelse {
        return error.DatabaseOpenError;
    };
    if (open_error != 0) {
        std.debug.print("{s}\n", .{sqlite3c.sqlite3_errmsg(db)});
        return error.DatabaseOpenError;
    }

    var stdout = std.io.getStdOut().writer();
    const article_exists = try params.articleExists(db);
    if (article_exists) {
        try stdout.print("Editing pre-existing article with URL '{s}'.\n", .{params.url});
        try params.updateTitle(db);
        try params.updateContent(db);
        try params.updateClass(db);
        try params.updateTags(db);
        try params.updateModified(db);
    } else {
        try stdout.print("Creating new article with URL '{s}'.\n", .{params.url});
        try params.createModeValidate();
        try params.createNewArticle(db);
        try params.updateClass(db);
        try params.updateTags(db);
    }
}
