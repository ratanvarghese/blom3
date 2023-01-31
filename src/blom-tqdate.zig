const std = @import("std");
const mon13c = @cImport({
    @cInclude("mon13.h");
});

const MONTHS_C = "A\x00B\x00C\x00D\x00E\x00F\x00G\x00H\x00I\x00J\x00K\x00L\x00M";
var MONTHS: [MONTHS_C.len:0]u8 = MONTHS_C.*;
var diary_month_list = [13:null]?[*:0]u8{ null, null, null, null, null, null, null, null, null, null, null, null, null };

const DIARY_ERA_LIST_C = "BT\x00AT";
var DIARY_ERA_LIST: [DIARY_ERA_LIST_C.len:0]u8 = DIARY_ERA_LIST_C.*;
var diary_era_list = [2:null]?[*:0]u8{ null, null };

const DIARY_INTERCALARY_C = "ARM\x00ALD";
var DIARY_INTERCALARY: [DIARY_INTERCALARY_C.len:0]u8 = DIARY_INTERCALARY_C.*;
var diary_intercalary = [2:null]?[*:0]u8{ null, null };

const DIARY_ALT_INTERCALARY_C = "MLD\x00\x00";
var DIARY_ALT_INTERCALARY: [DIARY_ALT_INTERCALARY_C.len:0]u8 = DIARY_ALT_INTERCALARY_C.*;
var diary_alt_intercalary = [2:null]?[*:0]u8{ null, null };

const DIARY_WEEKDAY_LIST_C = "Mon\x00Tue\x00Wed\x00Thu\x00Fri\x00Sat\x00Sun";
var DIARY_WEEKDAY_LIST: [DIARY_WEEKDAY_LIST_C.len:0]u8 = DIARY_WEEKDAY_LIST_C.*;
var diary_weekday_list = [7:null]?[*:0]u8{ null, null, null, null, null, null, null };

const NAME = "TQ";
var name_var: [NAME.len:0]u8 = NAME.*;

var names_diary: mon13c.mon13_NameList = undefined;
//  = {
//     .month_list = @ptrCast([*:null]?[*:0]u8, &diary_month_list),
//     .weekday_list = @ptrCast([*:null]?[*:0]u8, &diary_weekday_list),
//     .era_list = @ptrCast([*:null]?[*:0]u8, &diary_era_list),
//     .intercalary_list = @ptrCast([*:null]?[*:0]u8, &diary_intercalary),
//     .alt_intercalary_list = @ptrCast([*:null]?[*:0]u8, &diary_alt_intercalary),
//     .calendar_name = @ptrCast([*:0]u8, &name_var),
// };

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
        //&mon13c.mon13_names_en_US_tranquility,
        &sequence[0],
        &buf[0],
        @intCast(i32, buf.len),
    );
    if (fmt_res < 0) {
        return error.Mon13FormatFailed;
    }
    return fmt_res;
}

fn setup_diary() !void {
    var dmi: usize = 0;
    while (dmi < diary_month_list.len) : (dmi += 1) {
        diary_month_list[dmi] = @ptrCast(?[*:0]u8, &MONTHS[dmi * 2]);
    }
    diary_era_list[0] = @ptrCast(?[*:0]u8, &DIARY_ERA_LIST[0]);
    diary_era_list[1] = @ptrCast(?[*:0]u8, &DIARY_ERA_LIST[3]);
    diary_intercalary[0] = @ptrCast(?[*:0]u8, &DIARY_INTERCALARY[0]);
    diary_intercalary[1] = @ptrCast(?[*:0]u8, &DIARY_INTERCALARY[4]);
    diary_alt_intercalary[0] = @ptrCast(?[*:0]u8, &DIARY_ALT_INTERCALARY[0]);
    diary_alt_intercalary[1] = @ptrCast(?[*:0]u8, &DIARY_ALT_INTERCALARY[4]);
    var dwi: usize = 0;
    while (dwi < diary_weekday_list.len) : (dwi += 1) {
        diary_weekday_list[dwi] = @ptrCast(?[*:0]u8, &DIARY_WEEKDAY_LIST[dwi * 4]);
    }
    names_diary.calendar_name = &name_var;
    names_diary.month_list = @ptrCast([*:null]?[*:0]u8, &diary_month_list);
    names_diary.era_list = @ptrCast([*:null]?[*:0]u8, &diary_era_list);
    names_diary.intercalary_list = @ptrCast([*:null]?[*:0]u8, &diary_intercalary);
    names_diary.alt_intercalary_list = @ptrCast([*:null]?[*:0]u8, &diary_alt_intercalary);
    names_diary.weekday_list = @ptrCast([*:null]?[*:0]u8, &diary_weekday_list);
    if (mon13c.mon13_validNameList(&mon13c.mon13_tranquility, &names_diary) == 0) {
        return error.FailedToSetupNameList;
    }
}

pub fn main() !void {
    try setup_diary();

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
