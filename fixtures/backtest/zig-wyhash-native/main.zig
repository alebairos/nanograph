const std = @import("std");
const Wyhash = @import("wyhash_impl.zig").Wyhash;

const PARTIAL_N: usize = 48;

const Packed = struct {
    inner: Wyhash,
    orig_seed: u64,
};

fn genByte(seed: u64, idx: u64) u8 {
    var x = seed ^ (idx *% 0x9e3779b97f4a7c15);
    x ^= x >> 33;
    x = x *% 0xff51afd7ed558ccd;
    return @truncate(x >> 56);
}

fn genBlock(seed: u64, off: u64, out: []u8) void {
    for (out, 0..) |*b, i| b.* = genByte(seed, off + @as(u64, @intCast(i)));
}

fn parseU64(s: []const u8) ?u64 {
    var n: u64 = 0;
    for (s) |c| {
        if (c < '0' or c > '9') return null;
        n = n * 10 + (c - '0');
    }
    return n;
}

fn printU64(n: u64) void {
    var buf: [32]u8 = undefined;
    var tmp: [32]u8 = undefined;
    var ti: usize = 0;
    var v = n;
    if (v == 0) {
        tmp[0] = '0';
        ti = 1;
    } else {
        while (v > 0) : (ti += 1) {
            tmp[ti] = @truncate('0' + (v % 10));
            v /= 10;
        }
    }
    var bi: usize = 0;
    while (ti > 0) {
        ti -= 1;
        buf[bi] = tmp[ti];
        bi += 1;
    }
    buf[bi] = '\n';
    bi += 1;
    _ = std.posix.write(1, buf[0..bi]) catch {};
}

fn putU20(out: []u8, pos: *usize, v: u64) void {
    var d: i32 = 19;
    while (d >= 0) : (d -= 1) {
        var div: u64 = 1;
        var e: i32 = 0;
        while (e < d) : (e += 1) div *= 10;
        if (pos.* + 1 >= out.len) return;
        out[pos.*] = @truncate('0' + (v / div) % 10);
        pos.* += 1;
    }
}

fn packToken(w: *const Wyhash, orig_seed: u64) void {
    var out: [512]u8 = undefined;
    var pos: usize = 0;
    out[pos] = '2';
    pos += 1;
    for (w.state) |s| putU20(out[0..], &pos, s);
    putU20(out[0..], &pos, w.a);
    putU20(out[0..], &pos, w.b);
    putU20(out[0..], &pos, @as(u64, @intCast(w.total_len)));
    putU20(out[0..], &pos, orig_seed);
    const bl = w.buf_len;
    out[pos] = @truncate('0' + (bl / 100) % 10);
    pos += 1;
    out[pos] = @truncate('0' + (bl / 10) % 10);
    pos += 1;
    out[pos] = @truncate('0' + bl % 10);
    pos += 1;
    for (w.buf[0..48]) |b| {
        out[pos] = @truncate('0' + (b / 100) % 10);
        pos += 1;
        out[pos] = @truncate('0' + (b / 10) % 10);
        pos += 1;
        out[pos] = @truncate('0' + b % 10);
        pos += 1;
    }
    out[pos] = '\n';
    pos += 1;
    _ = std.posix.write(1, out[0..pos]) catch {};
}

fn unpackToken(s: []const u8, w: *Wyhash, orig_seed: *u64) bool {
    if (s.len == 0 or s[0] != '2') return false;
    var i: usize = 1;
    for (&w.state) |*st| {
        var v: u64 = 0;
        var d: usize = 0;
        while (d < 20) : (d += 1) {
            if (i >= s.len or s[i] < '0' or s[i] > '9') return false;
            v = v * 10 + (s[i] - '0');
            i += 1;
        }
        st.* = v;
    }
    var total_tmp: u64 = 0;
    const fields = [_]*u64{ &w.a, &w.b, &total_tmp, orig_seed };
    for (fields) |fp| {
        var v: u64 = 0;
        var d: usize = 0;
        while (d < 20) : (d += 1) {
            if (i >= s.len or s[i] < '0' or s[i] > '9') return false;
            v = v * 10 + (s[i] - '0');
            i += 1;
        }
        fp.* = v;
    }
    w.total_len = @intCast(total_tmp);
    var bl: usize = 0;
    var d: usize = 0;
    while (d < 3) : (d += 1) {
        if (i >= s.len or s[i] < '0' or s[i] > '9') return false;
        bl = bl * 10 + (s[i] - '0');
        i += 1;
    }
    if (bl > 48) return false;
    w.buf_len = bl;
    for (&w.buf) |*b| {
        var bv: usize = 0;
        d = 0;
        while (d < 3) : (d += 1) {
            if (i >= s.len or s[i] < '0' or s[i] > '9') return false;
            bv = bv * 10 + (s[i] - '0');
            i += 1;
        }
        b.* = @truncate(bv);
    }
    return true;
}

fn wyhashBytes(seed: u64, len: usize) u64 {
    var w = Wyhash.init(seed);
    var block: [512]u8 = undefined;
    var off: usize = 0;
    while (off < len) {
        const chunk = @min(len - off, block.len);
        genBlock(seed, @as(u64, @intCast(off)), block[0..chunk]);
        w.update(block[0..chunk]);
        off += chunk;
    }
    return w.final();
}

fn flowPartial(len: usize, seed: u64) void {
    var w = Wyhash.init(seed);
    var block: [512]u8 = undefined;
    var off: usize = 0;
    while (off < len) {
        const chunk = @min(len - off, block.len);
        genBlock(seed, @as(u64, @intCast(off)), block[0..chunk]);
        w.update(block[0..chunk]);
        off += chunk;
    }
    packToken(&w, seed);
}

fn flowContinue(len: usize, token: []const u8) void {
    var w = Wyhash.init(0);
    var orig: u64 = 0;
    if (!unpackToken(token, &w, &orig)) std.process.exit(1);
    var block: [512]u8 = undefined;
    var off: usize = @intCast(w.total_len);
    const end = off + len;
    while (off < end) {
        const chunk = @min(end - off, block.len);
        genBlock(orig, @as(u64, @intCast(off)), block[0..chunk]);
        w.update(block[0..chunk]);
        off += chunk;
    }
    printU64(w.final());
}

pub fn main() void {
    var it = std.process.argsWithAllocator(std.heap.page_allocator) catch std.process.exit(1);
    defer it.deinit();
    if (!it.skip()) std.process.exit(1);
    const mode = it.next() orelse std.process.exit(1);
    const len_s = it.next() orelse std.process.exit(1);
    const arg = it.next() orelse std.process.exit(1);
    if (!std.mem.eql(u8, mode, "flow")) std.process.exit(1);
    const len = std.fmt.parseInt(usize, len_s, 10) catch std.process.exit(1);
    if (arg[0] == '2') {
        flowContinue(len, arg);
        return;
    }
    const seed = parseU64(arg) orelse std.process.exit(1);
    if (len == PARTIAL_N) {
        flowPartial(len, seed);
        return;
    }
    printU64(wyhashBytes(seed, len));
}
