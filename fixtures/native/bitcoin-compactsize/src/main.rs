use bitcoin::consensus::encode::{deserialize_hex, serialize_hex, VarInt};
use std::env;

fn main() {
    let mode = env::args().nth(1).unwrap_or_default();
    let val = env::args().nth(2).unwrap_or_default();
    let out = match mode.as_str() {
        "csdec" => match deserialize_hex::<VarInt>(&val) {
            Ok(v) => v.0.to_string(),
            Err(_) => "REJECT".to_string(),
        },
        "csenc" => match val.parse::<u64>() {
            Ok(n) => serialize_hex(&VarInt(n)),
            Err(_) => "REJECT".to_string(),
        },
        _ => "REJECT".to_string(),
    };
    println!("{out}");
}
