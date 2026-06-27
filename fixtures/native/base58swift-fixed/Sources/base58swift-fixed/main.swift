import Foundation
import Base58Swift

let args = CommandLine.arguments
guard args.count >= 3 else {
    print("REJECT")
    exit(0)
}

let mode = args[1]
let val = args[2]

if mode == "b58dec" {
    if let decoded = Base58.base58CheckDecode(val) {
        print(decoded.map { String(format: "%02x", $0) }.joined())
    } else {
        print("REJECT")
    }
} else if mode == "b58enc" {
    let s = val
    guard !s.isEmpty, s.count % 2 == 0 else {
        print("REJECT")
        exit(0)
    }
    var bytes: [UInt8] = []
    var i = s.startIndex
    while i < s.endIndex {
        let j = s.index(i, offsetBy: 2)
        guard let byte = UInt8(s[i..<j], radix: 16) else {
            print("REJECT")
            exit(0)
        }
        bytes.append(byte)
        i = j
    }
    print(Base58.base58CheckEncode(bytes))
} else {
    print("REJECT")
}
