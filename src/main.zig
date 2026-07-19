const std = @import("std");
var stdin_buffer: [1024]u8 = undefined;
var stdout_buffer: [1024]u8 = undefined;
var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
var stdin_reader = std.fs.File.stdin().reader(&stdin_buffer);
const stdin = &stdin_reader.interface;
const stdout = &stdout_writer.interface;
const char_map = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    const allocator = gpa.allocator();
    try stdout.writeAll("Type your string: \n");
    try stdout.flush();

    const str = try stdin.takeDelimiterExclusive('\n');

    const encoded_str = try base64Encode(str, allocator);
    const decoded_str = try base64Decode(encoded_str, allocator);

    try stdout.print("Encoded string: {s}\n", .{encoded_str});
    try stdout.flush();
    try stdout.print("Encoded string: {s}\n", .{decoded_str});
    try stdout.flush();

    allocator.free(encoded_str);
    allocator.free(decoded_str);
}

fn binToChar(i: u8) u8 {
    return char_map[i];
}

fn charToBin(c: u8) u8 {
    for (char_map, 0..) |char, i| {
        if (char == c) {
            return @truncate(i);
        }
    }

    return 0;
}

fn base64Encode(str: []const u8, allocator: std.mem.Allocator) ![]u8 {
    const len = ((str.len + 2) / 3) * 4;
    const res = try allocator.alloc(u8, len);

    var i: usize = 0;
    while (i < str.len) {
        if (i + 2 < str.len) {
            var num_val: u32 = (@as(u32, str[i]) << 16) + (@as(u32, str[i + 1]) << 8) + str[i + 2];
            var j: u8 = 0;
            const base_index = (i * 4) / 3;
            while (num_val > 0) {
                res[base_index + 3 - j] = binToChar(@truncate(num_val % (1 << 6)));
                num_val = num_val >> 6;
                j += 1;
            }
        } else if (i + 1 < str.len) {
            var num_val: u32 = (@as(u32, str[i]) << 10) + (@as(u32, str[i + 1]) << 2);
            var j: u8 = 0;
            const base_index = (i * 4) / 3;
            res[base_index + 3] = '=';
            while (num_val > 0) {
                res[base_index + 2 - j] = binToChar(@truncate(num_val % (1 << 6)));
                num_val = num_val >> 6;
                j += 1;
            }
        } else {
            var num_val: u32 = @as(u32, str[i]) << 4;
            var j: u8 = 0;
            const base_index = (i * 4) / 3;
            res[base_index + 3] = '=';
            res[base_index + 2] = '=';
            while (num_val > 0) {
                res[base_index + 1 - j] = binToChar(@truncate(num_val % (1 << 6)));
                num_val = num_val >> 6;
                j += 1;
            }
        }
        i += 3;
    }

    return res;
}

fn base64Decode(str: []const u8, allocator: std.mem.Allocator) ![]u8 {
    var len: usize = (str.len * 3) / 4;
    if (str[str.len - 2] == '=') {
        len -= 2;
    } else if (str[str.len - 1] == '=') {
        len -= 1;
    }

    const res = try allocator.alloc(u8, len);

    var i: usize = 0;
    while (i < str.len) {
        const base_index = (i * 3) / 4;
        if (str[i + 2] == '=') {
            const num_val = @as(u32, (@as(u32, charToBin(str[i])) << 6) + charToBin(str[i + 1])) >> 4;
            res[base_index] = @truncate(num_val);
        } else if (str[i + 3] == '=') {
            var num_val: u32 = @as(u32, (@as(u32, charToBin(str[i])) << 12) + (@as(u32, charToBin(str[i + 1])) << 6) + charToBin(str[i + 2])) >> 2;
            res[base_index + 1] = @truncate(num_val % (1 << 8));
            num_val = num_val >> 8;
            res[base_index] = @truncate(num_val % (1 << 8));
        } else {
            var num_val: u32 = (@as(u32, charToBin(str[i])) << 18) + (@as(u32, charToBin(str[i + 1])) << 12) + (@as(u32, charToBin(str[i + 2])) << 6) + charToBin(str[i + 3]);
            res[base_index + 2] = @truncate(num_val % (1 << 8));
            num_val = num_val >> 8;
            res[base_index + 1] = @truncate(num_val % (1 << 8));
            num_val = num_val >> 8;
            res[base_index] = @truncate(num_val % (1 << 8));
        }
        i += 4;
    }

    return res;
}
