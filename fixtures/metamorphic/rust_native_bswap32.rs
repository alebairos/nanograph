// G75 native Rust lang-pack specimen. Freestanding x86_64 Linux ELF, no libc,
// no std. Reads argv[1] as an unsigned 32-bit value; prints bswap32(x) in
// decimal. Same driver ABI as fixtures/metamorphic/bswap32.c so the unchanged
// verifier checks it under bswap32.req (relation=involution).
#![no_std]
#![no_main]

use core::arch::{asm, global_asm};

// The kernel leaves rsp 16-aligned at entry; the call gives real_start the
// C-ABI 8-byte skew (the G36 trampoline pattern).
global_asm!(
    ".global _start",
    "_start:",
    "mov rdi, [rsp]",
    "lea rsi, [rsp + 8]",
    "and rsp, -16",
    "call real_start",
);

fn sys_write(buf: &[u8]) {
    unsafe {
        asm!(
            "syscall",
            in("rax") 1usize,
            in("rdi") 1usize,
            in("rsi") buf.as_ptr(),
            in("rdx") buf.len(),
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

unsafe fn parse_u(mut p: *const u8) -> u64 {
    let mut n: u64 = 0;
    while *p >= b'0' && *p <= b'9' {
        n = n * 10 + (*p - b'0') as u64;
        p = p.add(1);
    }
    n
}

fn print_u(mut n: u64) {
    let mut tmp = [0u8; 32];
    let mut buf = [0u8; 32];
    let mut j = 0;
    if n == 0 {
        tmp[j] = b'0';
        j += 1;
    }
    while n > 0 {
        tmp[j] = b'0' + (n % 10) as u8;
        n /= 10;
        j += 1;
    }
    let mut i = 0;
    while j > 0 {
        j -= 1;
        buf[i] = tmp[j];
        i += 1;
    }
    buf[i] = b'\n';
    i += 1;
    sys_write(&buf[..i]);
}

#[no_mangle]
extern "C" fn real_start(argc: i64, argv: *const *const u8) -> ! {
    if argc < 2 {
        sys_exit(2);
    }
    let x = unsafe { parse_u(*argv.add(1)) } as u32;
    print_u(x.swap_bytes() as u64);
    sys_exit(0)
}
