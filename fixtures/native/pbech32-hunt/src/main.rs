use pbech32::{RawBech32, Scheme};
use std::env;

fn b32raw(addr: &str) -> String {
    match RawBech32::new(addr, None) {
        Ok(b) => {
            let scheme = match b.scheme {
                Scheme::Bech32 => "b32",
                Scheme::Bech32m => "b32m",
            };
            let data: String = b.data.iter().map(|f| format!("{f:02x}")).collect();
            format!("{}:{}:{}", scheme, b.hrp.0, data)
        }
        Err(_) => "REJECT".into(),
    }
}

fn main() {
    let args: Vec<String> = env::args().collect();
    let mode = args.get(1).cloned().unwrap_or_default();
    let val = args.get(2).cloned().unwrap_or_default();
    println!("{}", if mode == "b32raw" { b32raw(&val) } else { "REJECT".into() });
}
