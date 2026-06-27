use bech32::primitives::decode::{CheckedHrpstring, SegwitHrpstring, UncheckedHrpstring};
use bech32::primitives::segwit::VERSION_0;
use bech32::{Bech32, Bech32m};
use std::env;

fn program_hex(segwit: &SegwitHrpstring<'_>) -> String {
    segwit.byte_iter().map(|b| format!("{b:02x}")).collect()
}

fn b32mdec(addr: &str) -> String {
    let unchecked = match UncheckedHrpstring::new(addr) {
        Ok(u) => u,
        Err(_) => return "REJECT".into(),
    };
    let data_part = unchecked.data_part_ascii();
    if data_part.is_empty() {
        return "REJECT".into();
    }
    let witness_version = match bech32::Fe32::from_char(data_part[0].into()) {
        Ok(v) => v,
        Err(_) => return "REJECT".into(),
    };
    let checked: CheckedHrpstring<'_> = match witness_version {
        VERSION_0 => match unchecked.validate_and_remove_checksum::<Bech32>() {
            Ok(c) => c,
            Err(_) => return "REJECT".into(),
        },
        _ => match unchecked.validate_and_remove_checksum::<Bech32m>() {
            Ok(c) => c,
            Err(_) => return "REJECT".into(),
        },
    };
    match checked.validate_segwit() {
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
