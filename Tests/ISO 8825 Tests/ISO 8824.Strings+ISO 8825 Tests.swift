//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftASN1 open source project
//
// Copyright (c) 2021 Apple Inc. and the SwiftASN1 project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftASN1 project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Testing

import ISO_8824
@testable import ISO_8825

// The wire-facing halves of upstream ASN1StringTests.swift: per-type DER
// byte-vector assertions, round-trips through the DER serializer, the
// BMPString literal test's serialized-bytes assertions, and the
// `derEncoded:` rejection legs of the character sweeps. The value-facing
// halves (contiguous-bytes views, String round-trips, content validation on
// construction) live in swift-iso-8824.
private func assertRoundTrips<ASN1Object: ISO_8825.DER.Parseable & ISO_8825.DER.Serializable & Equatable>(_ value: ASN1Object) throws(ISO_8824.Error) {
    var serializer = ISO_8825.DER.Serializer()
    try serializer.serialize(value)
    let parsed = try ASN1Object(derEncoded: serializer.serializedBytes)
    #expect(parsed == value)
}

extension ISO_8824.UTF8String {
    @Suite
    struct Test {}
}

extension ISO_8824.UTF8String.Test {
    @Test
    func `encodes to the DER byte vector`() throws {
        var serializer = ISO_8825.DER.Serializer()
        let originalString = ISO_8824.UTF8String(contentBytes: [1, 2, 3, 4])
        try serializer.serialize(originalString)
        #expect(serializer.serializedBytes == [12, 4, 1, 2, 3, 4])
    }

    @Test
    func `round-trips through the DER serializer`() throws {
        try assertRoundTrips(ISO_8824.UTF8String(contentBytes: [1, 2, 3, 4]))
    }
}

extension ISO_8824.TeletexString {
    @Suite
    struct Test {}
}

extension ISO_8824.TeletexString.Test {
    @Test
    func `encodes to the DER byte vector`() throws {
        var serializer = ISO_8825.DER.Serializer()
        let originalString = ISO_8824.TeletexString(contentBytes: [1, 2, 3, 4])
        try serializer.serialize(originalString)
        #expect(serializer.serializedBytes == [20, 4, 1, 2, 3, 4])
    }

    @Test
    func `round-trips through the DER serializer`() throws {
        try assertRoundTrips(ISO_8824.TeletexString(contentBytes: [1, 2, 3, 4]))
    }
}

extension ISO_8824.PrintableString {
    @Suite
    struct Test {}
}

extension ISO_8824.PrintableString.Test {
    @Test
    func `encodes to the DER byte vector`() throws {
        var serializer = ISO_8825.DER.Serializer()
        let originalString = try ISO_8824.PrintableString(contentBytes: [0x54, 0x65, 0x73, 0x74])
        try serializer.serialize(originalString)
        #expect(serializer.serializedBytes == [19, 4, 0x54, 0x65, 0x73, 0x74])
    }

    @Test
    func `round-trips through the DER serializer`() throws {
        try assertRoundTrips(try ISO_8824.PrintableString(contentBytes: [0x54, 0x65, 0x73, 0x74]))
    }

    @Test
    func `rejects invalid characters on the DER parse leg`() {
        let allBytes = (UInt8(0)...UInt8.max)

        let invalidBytes = (UInt8(0)...UInt8(255)).filter {
            switch $0 {
            case UInt8(ascii: "a")...UInt8(ascii: "z"),
                UInt8(ascii: "A")...UInt8(ascii: "Z"),
                UInt8(ascii: "0")...UInt8(ascii: "9"),
                UInt8(ascii: "'"), UInt8(ascii: "("),
                UInt8(ascii: ")"), UInt8(ascii: "+"),
                UInt8(ascii: "-"), UInt8(ascii: "?"),
                UInt8(ascii: ":"), UInt8(ascii: "/"),
                UInt8(ascii: "="), UInt8(ascii: " "),
                UInt8(ascii: ","), UInt8(ascii: "."):
                return false
            default:
                return true
            }
        }

        let validBytes = allBytes.filter { !invalidBytes.contains($0) }

        for byte in invalidBytes {
            #expect(throws: ISO_8824.Error.self) { try ISO_8824.PrintableString(derEncoded: [0x13, 1, byte]) }
        }

        for byte in validBytes {
            #expect(throws: Never.self) { try ISO_8824.PrintableString(derEncoded: [0x13, 1, byte]) }
        }
    }
}

extension ISO_8824.VisibleString {
    @Suite
    struct Test {}
}

extension ISO_8824.VisibleString.Test {
    @Test
    func `encodes to the DER byte vector`() throws {
        var serializer = ISO_8825.DER.Serializer()
        let originalString = try ISO_8824.VisibleString(contentBytes: [0x20, 0x30, 0x7a, 0x7e])
        try serializer.serialize(originalString)
        #expect(serializer.serializedBytes == [26, 4, 0x20, 0x30, 0x7a, 0x7e])
    }

    @Test
    func `round-trips through the DER serializer`() throws {
        try assertRoundTrips(try ISO_8824.VisibleString(contentBytes: [0x20, 0x30, 0x7a, 0x7e]))
    }

    @Test
    func `rejects invalid characters on the DER parse leg`() {
        let allBytes = (UInt8(0)...UInt8.max)
        let invalidBytes = [(UInt8(0)...UInt8(31)), (UInt8(127)...(UInt8.max))].joined()
        let validBytes = allBytes.filter { !invalidBytes.contains($0) }

        for byte in invalidBytes {
            #expect(throws: ISO_8824.Error.self) { try ISO_8824.VisibleString(derEncoded: [0x1a, 1, byte]) }
        }

        for byte in validBytes {
            #expect(throws: Never.self) { try ISO_8824.VisibleString(derEncoded: [0x1a, 1, byte]) }
        }
    }
}

extension ISO_8824.IA5String {
    @Suite
    struct Test {}
}

extension ISO_8824.IA5String.Test {
    @Test
    func `rejects invalid characters on the DER parse leg`() {
        let invalidBytes = (UInt8(128)...(UInt8.max))
        let validBytes = (UInt8(0)..<UInt8(128))

        for byte in invalidBytes {
            #expect(throws: ISO_8824.Error.self) { try ISO_8824.IA5String(derEncoded: [0x16, 1, byte]) }
        }

        for byte in validBytes {
            #expect(throws: Never.self) { try ISO_8824.IA5String(derEncoded: [0x16, 1, byte]) }
        }
    }
}

extension ISO_8824.UniversalString {
    @Suite
    struct Test {}
}

extension ISO_8824.UniversalString.Test {
    @Test
    func `encodes to the DER byte vector`() throws {
        var serializer = ISO_8825.DER.Serializer()
        let originalString = ISO_8824.UniversalString(contentBytes: [1, 2, 3, 4])
        try serializer.serialize(originalString)
        #expect(serializer.serializedBytes == [28, 4, 1, 2, 3, 4])
    }

    @Test
    func `round-trips through the DER serializer`() throws {
        try assertRoundTrips(ISO_8824.UniversalString(contentBytes: [1, 2, 3, 4]))
    }
}

extension ISO_8824.BMPString {
    @Suite
    struct Test {}
}

extension ISO_8824.BMPString.Test {
    @Test
    func `encodes to the DER byte vector`() throws {
        var serializer = ISO_8825.DER.Serializer()
        let originalString = ISO_8824.BMPString(contentBytes: [1, 2, 3, 4])
        try serializer.serialize(originalString)
        #expect(serializer.serializedBytes == [30, 4, 1, 2, 3, 4])
    }

    @Test
    func `round-trips through the DER serializer`() throws {
        try assertRoundTrips(ISO_8824.BMPString(contentBytes: [1, 2, 3, 4]))
    }

    @Test
    func `string literals serialize to the DER byte vector`() throws {
        typealias TestCase = (literal: String, asn1: [UInt8])

        // The UTF-16 content-byte assertions of the upstream literal test are
        // value law and live in swift-iso-8824; the serialized-form assertions
        // are the wire half.
        let testCases: [TestCase] = [
            TestCase(
                "Test",
                [30, 8, 0, 84, 0, 101, 0, 115, 0, 116]
            ),
            TestCase(
                "Tests",
                [30, 10, 0, 84, 0, 101, 0, 115, 0, 116, 0, 115]
            ),
            TestCase(
                "中文",
                [30, 4, 78, 45, 101, 135]
            ),
        ]

        for testCase in testCases {
            let string = ISO_8824.BMPString(stringLiteral: testCase.literal)

            var serializer = ISO_8825.DER.Serializer()
            try serializer.serialize(string)
            #expect(serializer.serializedBytes == testCase.asn1)
        }
    }
}
