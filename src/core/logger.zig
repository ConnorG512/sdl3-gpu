const std = @import("std");

pub const Logger = struct {

    const LogType = enum {
        Info,
        Warning,
        Error,
    };

    pub fn createLog() !std.fs.File {

        return try std.fs.cwd().createFileZ("debug.log", std.fs.File.CreateFlags{ .read = false, .truncate = true });
    }
};
