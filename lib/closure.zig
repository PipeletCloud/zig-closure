const std = @import("std");

pub fn ImplClosure(comptime T: type) type {
    return struct {
        const Self = @This();

        args: Arguments,
        func: *const T,

        pub const Arguments = blk: {
            const params = @typeInfo(T).@"fn".params;

            var fields: [params.len]std.builtin.Type.StructField = undefined;
            for (params, &fields, 0..) |p, *field, i| {
                @setEvalBranchQuota(10_000);
                var num_buf: [128]u8 = undefined;
                field.* = .{
                    .name = std.fmt.bufPrintZ(&num_buf, "{d}", .{i}) catch unreachable,
                    .type = p.type orelse unreachable,
                    .default_value_ptr = null,
                    .alignment = 0,
                    .is_comptime = false,
                };
            }

            break :blk @Type(.{ .@"struct" = .{
                .layout = .auto,
                .decls = &.{},
                .fields = &fields,
                .is_tuple = true,
            } });
        };

        pub const Result = @typeInfo(T).@"fn".return_type orelse unreachable;

        pub fn run(self: *const Self) Result {
            return @call(.auto, self.func, self.args);
        }
    };
}

pub fn FixedClosure(comptime Function: anytype) type {
    return struct {
        const Self = @This();
        const T = @TypeOf(Function);

        args: Arguments,

        pub const Arguments = blk: {
            const params = @typeInfo(T).@"fn".params;

            var fields: [params.len]std.builtin.Type.StructField = undefined;
            for (params, &fields, 0..) |p, *field, i| {
                @setEvalBranchQuota(10_000);
                var num_buf: [128]u8 = undefined;
                field.* = .{
                    .name = std.fmt.bufPrintZ(&num_buf, "{d}", .{i}) catch unreachable,
                    .type = p.type orelse unreachable,
                    .default_value_ptr = null,
                    .alignment = 0,
                    .is_comptime = false,
                };
            }

            break :blk @Type(.{ .@"struct" = .{
                .layout = .auto,
                .decls = &.{},
                .fields = &fields,
                .is_tuple = true,
            } });
        };

        pub const Result = @typeInfo(T).@"fn".return_type orelse unreachable;

        pub fn run(self: *const Self) Result {
            return @call(.auto, Function, self.args);
        }
    };
}

pub fn implClosure(comptime func: anytype, args: anytype) ImplClosure(@TypeOf(func)) {
    return ImplClosure(@TypeOf(func)){ .args = args, .func = func };
}

pub fn fixedClosure(comptime Function: anytype, args: anytype) FixedClosure(Function) {
    return FixedClosure(Function){ .args = args };
}

test {
    const TestFunctions = struct {
        pub fn add(a: u8, b: u8) u8 {
            return a + b;
        }

        pub fn sub(a: u8, b: u8) u8 {
            return a - b;
        }

        pub fn doError() !void {
            return error.Unexpected;
        }
    };

    try std.testing.expectEqual(@as(u8, 19), implClosure(TestFunctions.add, .{ 9, 10 }).run());
    try std.testing.expectEqual(@as(u8, 9), implClosure(TestFunctions.sub, .{ 19, 10 }).run());
    try std.testing.expectError(error.Unexpected, implClosure(TestFunctions.doError, .{}).run());

    try std.testing.expectEqual(@as(u8, 19), fixedClosure(TestFunctions.add, .{ 9, 10 }).run());
    try std.testing.expectEqual(@as(u8, 9), fixedClosure(TestFunctions.sub, .{ 19, 10 }).run());
    try std.testing.expectError(error.Unexpected, fixedClosure(TestFunctions.doError, .{}).run());
}
