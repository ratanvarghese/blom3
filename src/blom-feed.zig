const std = @import("std");

const timec = @cImport({
    @cDefine("_XOPEN_SOURCE", "1");
    @cInclude("time.h");
});

const mxmlc = @cImport({
    @cInclude("mxml.h");
});

const jsfItem = struct {
    id: []u8,
    url: []u8,
    title: []u8,
    content_html: []u8,
    date_published: []u8,
    date_modified: []u8,
    //ignore tags
    //ignore attachments
};

const jsfMain = struct {
    version: []u8,
    title: []u8,
    home_page_url: []u8,
    items: []jsfItem,
};

const before_open0 = "";
const before_open1 = "\n  ";
const before_open2 = "\n    ";
const before_open3 = "\n      ";
const before_open4 = "\n        ";
const newline_repl = " ";

fn getOpenWhitespace(start: *mxmlc.mxml_node_t) [*c]const u8 {
    var res_idx: c_uint = 0;
    var n = start;
    while (mxmlc.mxmlGetParent(n)) |parent| {
        n = parent;
        res_idx += 1;
    }
    return switch (res_idx) {
        0 => before_open0,
        1 => before_open1,
        2 => before_open2,
        3 => before_open3,
        else => before_open4,
    };
}

fn hasCloseWhitespace(start: *mxmlc.mxml_node_t) bool {
    return mxmlc.mxmlGetText(start, null) == null;
}

fn whitespaceCallback(raw_node: ?*mxmlc.mxml_node_t, where: c_int) callconv(.C) [*c]const u8 {
    const node = raw_node orelse return null;

    if (where == mxmlc.MXML_WS_BEFORE_OPEN) {
        return getOpenWhitespace(node);
    }
    if (where == mxmlc.MXML_WS_BEFORE_CLOSE and hasCloseWhitespace(node)) {
        return getOpenWhitespace(node);
    } else {
        return null;
    }
}

fn addTextNode(parent: ?*mxmlc.mxml_node_t, name: []const u8, content: []u8, allocator: anytype) !?*mxmlc.mxml_node_t {
    var el = mxmlc.mxmlNewElement(parent, @ptrCast(*const u8, name));

    // const memory = try std.cstr.addNullByte(allocator, content);
    // defer allocator.free(memory);
    // _ = mxmlc.mxmlNewText(el, 0, @ptrCast(*u8, memory));

    var start_idx: usize = 0;
    for (content) |c, i| {
        if (c == '\n') {
            const line = try std.cstr.addNullByte(allocator, content[start_idx..i]);
            _ = mxmlc.mxmlNewText(el, 0, @ptrCast(*const u8, line));
            _ = mxmlc.mxmlNewText(el, 0, @ptrCast(*const u8, newline_repl));
            allocator.free(line);
            start_idx = i + 1;
        }
    }
    if (start_idx < content.len) {
        const line = try std.cstr.addNullByte(allocator, content[start_idx..]);
        _ = mxmlc.mxmlNewText(el, 0, @ptrCast(*const u8, line));
        allocator.free(line);
    }

    return el;
}

fn atomFeedEntry(atom_feed: ?*mxmlc.mxml_node_t, json_item: jsfItem, allocator: anytype) !void {
    var entry = mxmlc.mxmlNewElement(atom_feed, "entry");

    _ = try addTextNode(entry, "title", json_item.title, allocator);
    _ = try addTextNode(entry, "updated", json_item.date_modified, allocator);
    var id = try addTextNode(entry, "id", json_item.id, allocator);
    var content = try addTextNode(entry, "content", json_item.content_html, allocator);
    mxmlc.mxmlElementSetAttr(content, "type", "html");

    var link = try addTextNode(entry, "link", "", allocator);
    mxmlc.mxmlElementSetAttr(link, "href", mxmlc.mxmlGetText(id, null));
}

fn atomFeedHead(xml: ?*mxmlc.mxml_node_t, json_feed: jsfMain, allocator: anytype) !void {
    var atom_feed = mxmlc.mxmlNewElement(xml, "feed");
    mxmlc.mxmlElementSetAttr(atom_feed, "xmlns", "http://www.w3.org/2005/Atom");

    const time_sec = timec.time(null);
    const time_split = timec.localtime(&time_sec);
    const memory = try allocator.alloc(u8, 30);
    defer allocator.free(memory);
    _ = timec.strftime(@ptrCast(*u8, memory), memory.len, "%Y-%m-%dT%H:%M:%S-04:00", time_split);

    _ = try addTextNode(atom_feed, "title", json_feed.title, allocator);
    _ = try addTextNode(atom_feed, "id", json_feed.home_page_url, allocator);
    _ = try addTextNode(atom_feed, "updated", memory, allocator);
    var link = try addTextNode(atom_feed, "link", "", allocator);
    mxmlc.mxmlElementSetAttr(link, "href", @ptrCast(*u8, json_feed.home_page_url));

    for (json_feed.items) |json_item| {
        try atomFeedEntry(atom_feed, json_item, allocator);
    }
}

fn rssFeedEntry(channel: ?*mxmlc.mxml_node_t, json_item: jsfItem, allocator: anytype) !void {
    var item = mxmlc.mxmlNewElement(channel, "item");

    const js_date = try std.cstr.addNullByte(allocator, json_item.date_published);
    defer allocator.free(js_date);
    var time_split: timec.tm = undefined;
    const tp_result = timec.strptime(js_date, "%Y-%m-%dT%H:%M:%S", &time_split);
    if (tp_result == null) {
        std.debug.print("Error parsing date: {s}\n", .{js_date});
        return error.TimeParseError;
    }
    const memory = try allocator.alloc(u8, 50);
    defer allocator.free(memory);
    const tf_result = timec.strftime(@ptrCast(*u8, memory), memory.len, "%a, %d %b %Y %H:%M:%S -04:00", &time_split);
    if (tf_result == 0) {
        return error.TimeFormatError;
    }

    _ = try addTextNode(item, "title", json_item.title, allocator);
    _ = try addTextNode(item, "link", json_item.url, allocator);
    _ = try addTextNode(item, "description", json_item.content_html, allocator);
    _ = try addTextNode(item, "guid", json_item.id, allocator);
    _ = try addTextNode(item, "pubDate", memory, allocator);
}

fn rssFeedHead(xml: ?*mxmlc.mxml_node_t, json_feed: jsfMain, allocator: anytype) !void {
    var rss_feed = mxmlc.mxmlNewElement(xml, "rss");
    mxmlc.mxmlElementSetAttr(rss_feed, "version", "2.0");

    var channel = mxmlc.mxmlNewElement(rss_feed, "channel");

    const time_sec = timec.time(null);
    const time_split = timec.localtime(&time_sec);
    const memory = try allocator.alloc(u8, 50);
    defer allocator.free(memory);
    _ = timec.strftime(@ptrCast(*u8, memory), memory.len, "%a, %d %b %Y %H:%M:%S -04:00", time_split);

    _ = try addTextNode(channel, "title", json_feed.title, allocator);
    _ = try addTextNode(channel, "link", json_feed.home_page_url, allocator);
    _ = try addTextNode(channel, "pubDate", memory, allocator);
    _ = mxmlc.mxmlNewElement(channel, "description");

    for (json_feed.items) |json_item| {
        try rssFeedEntry(channel, json_item, allocator);
    }
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const stdin = std.io.getStdIn().reader();

    const input = try stdin.readAllAlloc(allocator, 100000000);
    var stream = std.json.TokenStream.init(input[0..]);
    const jsonFeed = try std.json.parse(jsfMain, &stream, .{
        .allocator = allocator,
        .ignore_unknown_fields = true,
    });

    var xml: ?*mxmlc.mxml_node_t = null;

    xml = mxmlc.mxmlNewXML("1.0");

    if (std.os.argv.len > 1) {
        const arg1 = std.mem.span(std.os.argv[1]);
        if (std.mem.eql(u8, arg1, "--atom")) {
            try atomFeedHead(xml, jsonFeed, allocator);
        } else if (std.mem.eql(u8, arg1, "--rss")) {
            try rssFeedHead(xml, jsonFeed, allocator);
        }
    }

    _ = mxmlc.mxmlSaveFile(xml, mxmlc.stdout, whitespaceCallback);

    mxmlc.mxmlDelete(xml);
}
