use bech32::primitives::decode::SegwitHrpstring;
use std::env;

fn program_hex(segwit: &SegwitHrpstring<'_>) -> String {
    segwit.byte_iter().map(|b| format!("{b:02x}")).collect()
}

fn b32mdec(addr: &str) -> String {
    match SegwitHrpstring::new(addr) {
        Ok(segwit) => format!("{}:{}", segwit.witness_version().to_u8(), program_hex(&segwit)),
        Err(_) => "REJECT".into(),
    }
}

fn main() {
    let mode = env::args().nth(1).unwrap_or_default();
    let val = env::args().nth(2).unwrap_or_default();
    let out = if mode == "b32mdec" {
        b32mdec(&val)
    } else {
        "REJECT".into()
    };
    println!("{out}");
}
