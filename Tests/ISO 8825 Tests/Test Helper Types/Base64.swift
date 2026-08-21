extension Array where Element == UInt8 {

    init(base64Decoding string: String) {
        var table = [Int8](repeating: -1, count: 256)
        let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
        for (index, scalar) in alphabet.utf8.enumerated() {
            table[Int(scalar)] = Int8(index)
        }

        var out = [UInt8]()
        out.reserveCapacity((string.utf8.count / 4) * 3)

        var accumulator = 0
        var bits = 0
        for byte in string.utf8 {
            if byte == UInt8(ascii: "=") {
                break
            }
            let value = table[Int(byte)]
            precondition(value >= 0, "Invalid base64 character in test fixture")
            accumulator = (accumulator << 6) | Int(value)
            bits += 6
            if bits >= 8 {
                bits -= 8
                out.append(UInt8(truncatingIfNeeded: accumulator >> bits))
            }
        }

        self = out
    }
}
