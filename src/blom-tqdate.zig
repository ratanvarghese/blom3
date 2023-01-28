const std = @import("std");
const mon13c = @cImport({
    @cInclude("mon13.h");
});

var diary_month_list = [_:null]?[*:0]u8{
    "A",
    "B",
    "C",
    "D",
    "E",
    "F",
    "G",
    "H",
    "I",
    "J",
    "K",
    "L",
    "M",
};

var diary_era_list = [_:null]?[*:0]u8{
    "BT",
    "AT",
};

var diary_intercalary = [_:null]?[*:0]u8{
    "ARM",
    "ALD",
};

var diary_alt_intercalary = [_:null]?[*:0]u8{
    "MLD",
    "",
};

var diary_weekday_list = [_:null]?[*:0]u8{
    "Mon",
    "Tue",
    "Wed",
    "Thu",
    "Fri",
    "Sat",
    "Sun",
};

const NAME = "TQ";
var name_var: [NAME.len:0]u8 = NAME.*;

pub const names_diary = mon13c.mon13_NameList{
    .month_list = @ptrCast([*:null]?[*:0]u8, &diary_month_list),
    .weekday_list = @ptrCast([*:null]?[*:0]u8, &diary_weekday_list),
    .era_list = @ptrCast([*:null]?[*:0]u8, &diary_era_list),
    .intercalary_list = @ptrCast([*:null]?[*:0]u8, &diary_intercalary),
    .alt_intercalary_list = @ptrCast([*:null]?[*:0]u8, &diary_alt_intercalary),
    .calendar_name = @ptrCast([*:0]u8, &name_var),
};

fn next_line(reader: anytype, allocator: std.mem.Allocator) !?[]const u8 {
    return try reader.readUntilDelimiterOrEofAlloc(
        allocator,
        '\n',
        256,
    );
}

fn line_to_mjd(line: []const u8) !i32 {
    const expected_len = 10;
    if (line.len < expected_len) {
        return error.BadGregorianDate;
    }

    var mjd: i32 = 0;
    const res = mon13c.mon13_parse(&mon13c.mon13_gregorian, null, "%Y-%m-%d", line[0..expected_len], expected_len, &mjd);
    if (res < 0) {
        return error.Mon13MjdFromYmdFailed;
    } else {
        return mjd;
    }
}

fn mjd_to_line(mjd: i32, buf: []u8) !c_int {
    const sequence = "%Y-%B%d";
    const fmt_res = mon13c.mon13_format(
        mjd,
        &mon13c.mon13_tranquility,
        &names_diary,
        &sequence[0],
        &buf[0],
        @intCast(i32, buf.len),
    );
    if (fmt_res < 0) {
        return error.Mon13FormatFailed;
    }
    return fmt_res;
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    var stdout = std.io.getStdOut().writer();

    if (args.len < 2) {
        return error.InsufficientArguments;
    }

    const mjd = try line_to_mjd(args[1]);
    var buf = [_]u8{0} ** 100;
    const bytes = try mjd_to_line(mjd, buf[0..]);
    try stdout.print("{s}", .{buf[0..@intCast(usize, bytes)]});
}
