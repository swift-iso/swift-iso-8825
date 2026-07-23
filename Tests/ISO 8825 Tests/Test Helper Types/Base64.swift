//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-iso-8825 open source project
//
// Copyright (c) 2026 Coen ten Thije Boonkkamp and the swift-iso-8825 project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

// Foundation-free RFC 4648 base64 decoding for test fixtures. Replaces the
// upstream tests' `Array(Data(base64Encoded:)!)` (core targets and their tests
// remain Foundation-free).

extension Array where Element == UInt8 {
    /// Decodes a standard base64 string (padding required, no line breaks).
    /// Traps on invalid input, matching the upstream force-unwrap fixture style.
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
