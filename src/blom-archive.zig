const std = @import("std");
const mon13c = @cImport({
    @cInclude("mon13.h");
});

const JsfItem = struct { url: []u8, title: []u8, date_published: []u8 };

fn line_to_mjd(line: []const u8) !i32 {
    var mjd: i32 = 0;
    const res = mon13c.mon13_parse(&mon13c.mon13_gregorian, null, "%Y-%m-%d", line[0..10], 10, &mjd);
    if (res < 0) {
        return error.Mon13MjdFromYmdFailed;
    } else {
        return mjd;
    }
}

fn hippocratesOrAldrin(m: u8, d: u8) bool {
    return m == 8 or (m == 0 and d == 2);
}

fn seperator(mjd1: i32, mjd2: i32, leading_newline: bool, writer: anytype) !void {
    var tqYear1: i32 = 0;
    var tqMonth1: u8 = 0;
    var tqDay1: u8 = 0;
    const ymdRes1 = mon13c.mon13_mjdToYmd(
        mjd1,
        &mon13c.mon13_tranquility,
        &tqYear1,
        &tqMonth1,
        &tqDay1,
    );

    var tqYear2: i32 = 0;
    var tqMonth2: u8 = 0;
    var tqDay2: u8 = 0;
    const ymdRes2 = mon13c.mon13_mjdToYmd(
        mjd2,
        &mon13c.mon13_tranquility,
        &tqYear2,
        &tqMonth2,
        &tqDay2,
    );
    if (ymdRes2 < 0 and ymdRes1 < 0) {
        return error.Mon13MjdToYmdFailed;
    }

    const isSpecialDay = tqMonth2 == 0;
    const sameYear = tqYear1 == tqYear2;
    const sameMonth = tqMonth1 == tqMonth2;
    const sameDay = tqDay1 == tqDay2;

    if (!sameYear or !sameMonth or (isSpecialDay and (!sameDay))) {
        const hoa1 = hippocratesOrAldrin(tqMonth1, tqDay1);
        const hoa2 = hippocratesOrAldrin(tqMonth2, tqDay2);

        if (hoa1 and hoa2 and sameYear) {
            return;
        }

        if (leading_newline) {
            try writer.print("\n", .{});
        }

        if (hoa2) {
            try writer.print("### Hippocrates & Aldrin Day, {d} AT\n", .{tqYear2});
        } else {
            var buf = [_]u8{0} ** 100;
            const sequence = "### %B, %Y AT\n";
            const fmt_res = mon13c.mon13_format(
                mjd2,
                &mon13c.mon13_tranquility,
                &mon13c.mon13_names_en_US_tranquility,
                &sequence[0],
                &buf[0],
                @intCast(i32, buf.len),
            );
            if (fmt_res < 0) {
                return error.Mon13FormatFailed;
            } else {
                try writer.print("{s}", .{buf[0..@intCast(usize, fmt_res)]});
            }
        }
    }
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const stdin = std.io.getStdIn().reader();
    const stdout = std.io.getStdOut().writer();

    const input = try stdin.readAllAlloc(allocator, 1000000);

    var stream = std.json.TokenStream.init(input[0..]);
    const items = try std.json.parse([]JsfItem, &stream, .{
        .allocator = allocator,
        .ignore_unknown_fields = true,
    });

    var mjd1: i32 = 0;
    for (items) |item, i| {
        const mjd2 = try line_to_mjd(item.date_published);

        try seperator(mjd1, mjd2, i > 0, stdout);

        try stdout.print("+ [{s}](/{s}), short URL: [{s}/{d}](/{d})\n", .{
            item.title,
            item.url,
            "r3n.me",
            items.len - i,
            items.len - i,
        });

        mjd1 = mjd2;
    }
}
