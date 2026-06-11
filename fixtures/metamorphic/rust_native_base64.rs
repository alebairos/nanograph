// G56 native Rust lang-pack specimen. Freestanding x86_64 Linux ELF, no libc,
// no std. Faithful port of fixtures/metamorphic/rust_base64.c (marshallpierce
// rust-base64 decode_helper stage 4). Driver ABI:
//   dec <b64>   decode; print lowercase hex or REJECT
//   enc <hex>   canonical base64 or REJECT
// rev2: --cfg disable_invalid_last_check (parent accepts iYV= trailing bits).
#![no_std]
#![no_main]

use core::arch::{asm, global_asm};

const INVALID_VALUE: u8 = 255;
const INPUT_CHUNK_LEN: usize = 8;
const DECODED_CHUNK_LEN: usize = 6;

global_asm!(
    ".global _start",
    "_start:",
    "mov rdi, [rsp]",
    "lea rsi, [rsp + 8]",
    "and rsp, -16",
    "call real_start",
);

fn sys_write_ptr(ptr: *const u8, len: usize) {
    unsafe {
        asm!(
            "syscall",
            in("rax") 1usize,
            in("rdi") 1usize,
            in("rsi") ptr,
            in("rdx") len,
            out("rcx") _,
            out("r11") _,
            options(nostack),
        );
    }
}

fn sys_exit(code: i32) -> ! {
    unsafe {
        asm!(
            "syscall",
            in("rax") 60usize,
            in("rdi") code as usize,
            options(noreturn),
        );
    }
}

#[panic_handler]
fn panic(_: &core::panic::PanicInfo) -> ! {
    sys_exit(1)
}

fn cstr_len(p: *const u8) -> usize {
    let mut n = 0;
    unsafe {
        while *p.add(n) != 0 {
            n += 1;
        }
    }
    n
}

fn hex_nibble(c: u8) -> i32 {
    if c >= b'0' && c <= b'9' {
        return (c - b'0') as i32;
    }
    if c >= b'a' && c <= b'f' {
        return (c - b'a' + 10) as i32;
    }
    if c >= b'A' && c <= b'F' {
        return (c - b'A' + 10) as i32;
    }
    -1
}

fn parse_hex(s: *const u8, out: &mut [u8]) -> Option<usize> {
    let mut n = 0usize;
    let mut i = 0usize;
    unsafe {
        loop {
            let hi = hex_nibble(*s.add(i));
            let lo = hex_nibble(*s.add(i + 1));
            if hi < 0 || lo < 0 || n >= out.len() {
                return None;
            }
            out[n] = ((hi << 4) | lo) as u8;
            n += 1;
            i += 2;
            if *s.add(i) == 0 {
                break;
            }
        }
    }
    Some(n)
}

fn print_str(s: *const u8, len: usize) {
    sys_write_ptr(s, len);
}

fn print_hex_bytes_ptr(b: *const u8, n: usize) {
    const DIGITS: [u8; 16] = *b"0123456789abcdef";
    let mut buf = [0u8; 256];
    let mut i = 0usize;
    let mut k = 0usize;
    while k < n && i + 2 < buf.len() {
        let byte = unsafe { *b.add(k) };
        buf[i] = DIGITS[(byte >> 4) as usize];
        i += 1;
        buf[i] = DIGITS[(byte & 0xf) as usize];
        i += 1;
        k += 1;
    }
    buf[i] = b'\n';
    i += 1;
    sys_write_ptr(buf.as_ptr(), i);
}

const ENCODE_TABLE: [u8; 64] =
    *b"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

const fn make_decode_table() -> [u8; 256] {
    let mut t = [INVALID_VALUE; 256];
    let mut i = 0usize;
    while i < 64 {
        t[ENCODE_TABLE[i] as usize] = i as u8;
        i += 1;
    }
    t
}

static DECODE_TABLE: [u8; 256] = make_decode_table();

fn enc_value(v: u8) -> u8 {
    if v > 63 {
        b'='
    } else {
        ENCODE_TABLE[v as usize]
    }
}

fn b64_encode(in_ptr: *const u8, in_len: usize, out: &mut [u8]) -> Option<usize> {
    let mut o = 0usize;
    let mut i = 0usize;
    let n = in_len;
    while i + 3 <= n {
        let b0 = unsafe { *in_ptr.add(i) };
        let b1 = unsafe { *in_ptr.add(i + 1) };
        let b2 = unsafe { *in_ptr.add(i + 2) };
        let v = (b0 as u32) << 16 | (b1 as u32) << 8 | b2 as u32;
        if o + 4 > out.len() {
            return None;
        }
        out[o] = enc_value((v >> 18) as u8);
        o += 1;
        out[o] = enc_value(((v >> 12) & 0x3f) as u8);
        o += 1;
        out[o] = enc_value(((v >> 6) & 0x3f) as u8);
        o += 1;
        out[o] = enc_value((v & 0x3f) as u8);
        o += 1;
        i += 3;
    }
    if i < n {
        let mut v = (unsafe { *in_ptr.add(i) } as u32) << 16;
        if i + 1 < n {
            v |= (unsafe { *in_ptr.add(i + 1) } as u32) << 8;
        }
        if o + 4 > out.len() {
            return None;
        }
        out[o] = enc_value((v >> 18) as u8);
        o += 1;
        out[o] = enc_value(((v >> 12) & 0x3f) as u8);
        o += 1;
        if i + 1 < n {
            out[o] = enc_value(((v >> 6) & 0x3f) as u8);
        } else {
            out[o] = b'=';
        }
        o += 1;
        out[o] = b'=';
        o += 1;
    }
    if o >= out.len() {
        return None;
    }
    Some(o)
}

fn decode_chunk_precise(input: *const u8, output: *mut u8) -> bool {
    let mut accum: u64 = 0;
    for i in 0..8 {
        let m = DECODE_TABLE[unsafe { *input.add(i) } as usize];
        if m == INVALID_VALUE {
            return false;
        }
        accum |= (m as u64) << (58 - i * 6);
    }
    unsafe {
        *output.add(0) = (accum >> 58) as u8;
        *output.add(1) = (accum >> 52) as u8;
        *output.add(2) = (accum >> 46) as u8;
        *output.add(3) = (accum >> 40) as u8;
        *output.add(4) = (accum >> 34) as u8;
        *output.add(5) = (accum >> 28) as u8;
    }
    true
}

#[inline(never)]
fn decode_helper(input: *const u8, len: usize, output: *mut u8, cap: usize) -> Option<usize> {
    if len == 0 {
        return Some(0);
    }
    if len % 4 == 1 {
        return None;
    }

    let num_chunks = (len + INPUT_CHUNK_LEN - 1) / INPUT_CHUNK_LEN;
    let mut input_index = 0usize;
    let mut output_index = 0usize;

    for _c in 1..num_chunks {
        if input_index + INPUT_CHUNK_LEN > len || output_index + DECODED_CHUNK_LEN > cap {
            return None;
        }
        if !decode_chunk_precise(
            unsafe { input.add(input_index) },
            unsafe { output.add(output_index) },
        ) {
            return None;
        }
        input_index += INPUT_CHUNK_LEN;
        output_index += DECODED_CHUNK_LEN;
    }

    let mut leftover_bits: u64 = 0;
    let mut morsels_in_leftover = 0usize;
    let mut padding_bytes = 0usize;
    let start_of_leftovers = input_index;

    let mut i = 0usize;
    while start_of_leftovers + i < len {
        let b = unsafe { *input.add(start_of_leftovers + i) };
        if b == b'=' {
            if i % 4 < 2 {
                return None;
            }
            if padding_bytes == 0 {
                let _first_padding_index = i;
            }
            padding_bytes += 1;
            i += 1;
            continue;
        }
        if padding_bytes > 0 {
            return None;
        }
        let shift = 64 - (morsels_in_leftover + 1) * 6;
        let morsel = DECODE_TABLE[b as usize];
        if morsel == INVALID_VALUE {
            return None;
        }
        leftover_bits |= (morsel as u64) << shift;
        morsels_in_leftover += 1;
        i += 1;
    }

    let leftover_bits_ready_to_append = match morsels_in_leftover {
        0 => 0,
        2 => 8,
        3 => 16,
        4 => 24,
        6 => 32,
        7 => 40,
        8 => 48,
        _ => return None,
    };

    #[cfg(not(disable_invalid_last_check))]
    {
        let mask = !0u64 >> leftover_bits_ready_to_append;
        if (leftover_bits & mask) != 0 {
            return None;
        }
    }

    let mut leftover_bits_appended_to_buf = 0usize;
    while leftover_bits_appended_to_buf < leftover_bits_ready_to_append {
        if output_index >= cap {
            return None;
        }
        let selected_bits =
            (leftover_bits >> (56 - leftover_bits_appended_to_buf)) as u8;
        unsafe {
            *output.add(output_index) = selected_bits;
        }
        output_index += 1;
        leftover_bits_appended_to_buf += 8;
    }

    Some(output_index)
}

fn b64_decode(in_ptr: *const u8, in_len: usize) -> bool {
    let mut buf = [0u8; 128];
    match decode_helper(in_ptr, in_len, buf.as_mut_ptr(), buf.len()) {
        Some(n) => {
            print_hex_bytes_ptr(buf.as_ptr(), n);
            true
        }
        None => false,
    }
}

#[no_mangle]
extern "C" fn real_start(argc: i64, argv: *const *const u8) -> ! {
    if argc < 3 {
        sys_exit(1);
    }
    unsafe {
        let mode = *argv.add(1);
        let operand = *argv.add(2);
        let mode0 = *mode;
        if mode0 == b'd' {
            let n = cstr_len(operand);
            if n > 256 {
                print_str(b"REJECT\n".as_ptr(), 7);
                sys_exit(0);
            }
            if !b64_decode(operand, n) {
                print_str(b"REJECT\n".as_ptr(), 7);
            }
        } else if mode0 == b'e' {
            let mut buf = [0u8; 128];
            let mut out = [0u8; 256];
            match parse_hex(operand, &mut buf) {
                Some(n) => match b64_encode(buf.as_ptr(), n, &mut out) {
                    Some(o) => sys_write_ptr(out.as_ptr(), o),
                    None => print_str(b"REJECT\n".as_ptr(), 7),
                },
                None => print_str(b"REJECT\n".as_ptr(), 7),
            }
        } else {
            sys_exit(1);
        }
    }
    sys_exit(0)
}
