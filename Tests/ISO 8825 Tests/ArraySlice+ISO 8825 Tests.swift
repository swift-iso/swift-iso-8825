// ===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftASN1 open source project
//
// Copyright (c) 2019-2020 Apple Inc. and the SwiftASN1 project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftASN1 project authors
//
// SPDX-License-Identifier: Apache-2.0
//
// ===----------------------------------------------------------------------===//

import ISO_8824
import Testing

@testable import ISO_8825

// Coverage for the @retroactive cross-package conformance
// `ArraySlice: ISO_8824.Integer.Representable` and its typed
// `withBigEndianIntegerBytes(_:)` witness: the serialize leg drives the
// witness through the INTEGER wire discipline, the parse leg drives
// `init(derIntegerBytes:)`.
extension ISO_8825.Integer {
    @Suite
    struct Test {}
}

extension ISO_8825.Integer.Test {
    @Test
    func `ArraySlice round-trips as INTEGER content bytes`() throws {
        // Wider than UInt64: only representable through the "bigint" slice path.
        let integerBytes: ArraySlice<UInt8> = [0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A]

        var serializer = ISO_8825.DER.Serializer()
        try serializer.serialize(integerBytes)
        #expect(serializer.serializedBytes == [0x02, 0x0A] + integerBytes)

        let parsed = try ISO_8825.DER.parse(serializer.serializedBytes)
        let roundTripped = try ArraySlice<UInt8>(derEncoded: parsed)
        #expect(roundTripped == integerBytes)
    }

    @Test
    func `ArraySlice INTEGER gains a leading zero octet when the top bit is set`() throws {
        // isSigned == false for the slice bigint, so a set top bit forces the
        // X.690 §8.3 leading-zero pad on the serialize leg, which the parse
        // leg then strips.
        let integerBytes: ArraySlice<UInt8> = [0xFF, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A]

        var serializer = ISO_8825.DER.Serializer()
        try serializer.serialize(integerBytes)
        #expect(serializer.serializedBytes == [0x02, 0x0B, 0x00] + integerBytes)

        let parsed = try ISO_8825.DER.parse(serializer.serializedBytes)
        let roundTripped = try ArraySlice<UInt8>(derEncoded: parsed)
        #expect(roundTripped == integerBytes)
    }
}
