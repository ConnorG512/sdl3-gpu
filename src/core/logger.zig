const std = @import("std");

pub const LogType = enum {
    Info,
    Warning,
    Error,
};

pub const Logger = struct {

    log_file: std.fs.File = undefined,

    pub fn createLog(self: *Logger) !void {
         self.log_file = try std.fs.cwd().createFileZ("debug.log", std.fs.File.CreateFlags{ .read = false, .truncate = true });
    }

    pub fn writeLog(self: *Logger, log_type: LogType, message: []const u8) !void {
        switch (log_type) {
            .Info => {
                std.log.debug("Info Logging.", .{});
                _ = try self.log_file.write("INFO: ");
                _ = try self.log_file.write(message);
            },
            .Warning => {
                std.log.debug("Warning Logging.", .{});
                _ = try self.log_file.write("WARNING: ");
                _ = try self.log_file.write(message);

            },
            .Error => {
                std.log.debug("Error Logging.", .{});
                _ = try self.log_file.write("ERROR: ");
                _ = try self.log_file.write(message);

            },
        }
    }
};
