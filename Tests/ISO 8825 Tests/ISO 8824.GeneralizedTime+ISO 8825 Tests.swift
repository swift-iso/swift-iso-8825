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

// The wire-facing halves of upstream GeneralizedTimeTests.swift: the DER
// string-vector parse + round-trip table, truncation/junk-suffix rejection,
// and tag enforcement on `init(derEncoded:)`. The value-facing halves
// (component bounds, comparisons) live in swift-iso-8824.
extension ISO_8824.GeneralizedTime {
    @Suite
    struct Test {}
}

extension ISO_8824.GeneralizedTime.Test {
    private func assertRoundTrips<
        ASN1Object: ISO_8825.DER.Parseable & ISO_8825.DER.Serializable & Equatable
    >(_ value: ASN1Object) throws(ISO_8824.Error) {
        var serializer = ISO_8825.DER.Serializer()
        try serializer.serialize(value)
        let parsed = try ASN1Object(derEncoded: serializer.serializedBytes)
        #expect(parsed == value)
    }

    @Test
    func `simple generalized time test vectors`() throws {
        // This is a small set of generalized time test vectors derived from the ASN.1 docs.
        // We store the byte payload here as a string.
        let vectors: [(String, ISO_8824.GeneralizedTime?)] = [
            // Valid representations
            (
                "19920521000000Z",
                try .init(
                    year: 1992,
                    month: 5,
                    day: 21,
                    hours: 0,
                    minutes: 0,
                    seconds: 0,
                    fractionalSeconds: 0
                )
            ),
            (
                "19920521000000Z",
                try .init(
                    year: 1992,
                    month: 5,
                    day: 21,
                    hours: 0,
                    minutes: 0,
                    seconds: 0,
                    rawFractionalSeconds: ArraySlice<UInt8>()
                )
            ),
            (
                "19920622123421Z",
                try .init(
                    year: 1992,
                    month: 6,
                    day: 22,
                    hours: 12,
                    minutes: 34,
                    seconds: 21,
                    fractionalSeconds: 0
                )
            ),
            (
                "19920622123421Z",
                try .init(
                    year: 1992,
                    month: 6,
                    day: 22,
                    hours: 12,
                    minutes: 34,
                    seconds: 21,
                    rawFractionalSeconds: ArraySlice<UInt8>()
                )
            ),
            (
                "19920722132100.3Z",
                try .init(
                    year: 1992,
                    month: 7,
                    day: 22,
                    hours: 13,
                    minutes: 21,
                    seconds: 0,
                    fractionalSeconds: 0.3
                )
            ),
            (
                "19920722132100.3Z",
                try .init(
                    year: 1992,
                    month: 7,
                    day: 22,
                    hours: 13,
                    minutes: 21,
                    seconds: 0,
                    rawFractionalSeconds: ArraySlice<UInt8>([51])
                )
            ),
            (
                "19851106210627.3Z",
                try .init(
                    year: 1985,
                    month: 11,
                    day: 6,
                    hours: 21,
                    minutes: 6,
                    seconds: 27,
                    fractionalSeconds: 0.3
                )
            ),
            (
                "19851106210627.3Z",
                try .init(
                    year: 1985,
                    month: 11,
                    day: 6,
                    hours: 21,
                    minutes: 6,
                    seconds: 27,
                    rawFractionalSeconds: ArraySlice<UInt8>([51])
                )
            ),
            (
                "19851106210627.14159Z",
                try .init(
                    year: 1985,
                    month: 11,
                    day: 6,
                    hours: 21,
                    minutes: 6,
                    seconds: 27,
                    fractionalSeconds: 0.14159
                )
            ),
            (
                "19851106210627.14159Z",
                try .init(
                    year: 1985,
                    month: 11,
                    day: 6,
                    hours: 21,
                    minutes: 6,
                    seconds: 27,
                    rawFractionalSeconds: ArraySlice<UInt8>([49, 52, 49, 53, 57])
                )
            ),
            (
                "20210131000000Z",
                try .init(
                    year: 2021,
                    month: 1,
                    day: 31,
                    hours: 0,
                    minutes: 0,
                    seconds: 0,
                    fractionalSeconds: 0
                )
            ),
            (
                "20210131000000Z",
                try .init(
                    year: 2021,
                    month: 1,
                    day: 31,
                    hours: 0,
                    minutes: 0,
                    seconds: 0,
                    rawFractionalSeconds: ArraySlice<UInt8>()
                )
            ),  // only 31 days in January
            (
                "20210228000000Z",
                try .init(
                    year: 2021,
                    month: 2,
                    day: 28,
                    hours: 0,
                    minutes: 0,
                    seconds: 0,
                    fractionalSeconds: 0
                )
            ),
            (
                "20210228000000Z",
                try .init(
                    year: 2021,
                    month: 2,
                    day: 28,
                    hours: 0,
                    minutes: 0,
                    seconds: 0,
                    rawFractionalSeconds: ArraySlice<UInt8>()
                )
            ),  // only 28 days in February 2021
            (
                "20200229000000Z",
                try .init(
                    year: 2020,
                    month: 2,
                    day: 29,
                    hours: 0,
                    minutes: 0,
                    seconds: 0,
                    fractionalSeconds: 0
                )
            ),
            (
                "20200229000000Z",
                try .init(
                    year: 2020,
                    month: 2,
                    day: 29,
                    hours: 0,
                    minutes: 0,
                    seconds: 0,
                    rawFractionalSeconds: ArraySlice<UInt8>()
                )
            ),  // only 29 days in February 2020
            (
                "21000228000000Z",
                try .init(
                    year: 2100,
                    month: 2,
                    day: 28,
                    hours: 0,
                    minutes: 0,
                    seconds: 0,
                    fractionalSeconds: 0
                )
            ),
            (
                "21000228000000Z",
                try .init(
                    year: 2100,
                    month: 2,
                    day: 28,
                    hours: 0,
                    minutes: 0,
                    seconds: 0,
                    rawFractionalSeconds: ArraySlice<UInt8>()
                )
            ),  // only 28 days in February 2100
            (
                "20000229000000Z",
                try .init(
                    year: 2000,
                    month: 2,
                    day: 29,
                    hours: 0,
                    minutes: 0,
                    seconds: 0,
                    fractionalSeconds: 0
                )
            ),
            (
                "20000229000000Z",
                try .init(
                    year: 2000,
                    month: 2,
                    day: 29,
                    hours: 0,
                    minutes: 0,
                    seconds: 0,
                    rawFractionalSeconds: ArraySlice<UInt8>()
                )
            ),  // only 29 days in February 2000
            (
                "20210331000000Z",
                try .init(
                    year: 2021,
                    month: 3,
                    day: 31,
                    hours: 0,
                    minutes: 0,
                    seconds: 0,
                    fractionalSeconds: 0
                )
            ),
            (
                "20210331000000Z",
                try .init(
                    year: 2021,
                    month: 3,
                    day: 31,
                    hours: 0,
                    minutes: 0,
                    seconds: 0,
                    rawFractionalSeconds: ArraySlice<UInt8>()
                )
            ),  // only 31 days in March
            (
                "20210430000000Z",
                try .init(
                    year: 2021,
                    month: 4,
                    day: 30,
                    hours: 0,
                    minutes: 0,
                    seconds: 0,
                    fractionalSeconds: 0
                )
            ),
            (
                "20210430000000Z",
                try .init(
                    year: 2021,
                    month: 4,
                    day: 30,
                    hours: 0,
                    minutes: 0,
                    seconds: 0,
                    rawFractionalSeconds: ArraySlice<UInt8>()
                )
            ),  // only 30 days in April
            (
                "20210531000000Z",
                try .init(
                    year: 2021,
                    month: 5,
                    day: 31,
                    hours: 0,
                    minutes: 0,
                    seconds: 0,
                    fractionalSeconds: 0
                )
            ),
            (
                "20210531000000Z",
                try .init(
                    year: 2021,
                    month: 5,
                    day: 31,
                    hours: 0,
                    minutes: 0,
                    seconds: 0,
                    rawFractionalSeconds: ArraySlice<UInt8>()
                )
            ),  // only 31 days in May
            (
                "20210630000000Z",
                try .init(
                    year: 2021,
                    month: 6,
                    day: 30,
                    hours: 0,
                    minutes: 0,
                    seconds: 0,
                    fractionalSeconds: 0
                )
            ),
            (
                "20210630000000Z",
                try .init(
                    year: 2021,
                    month: 6,
                    day: 30,
                    hours: 0,
                    minutes: 0,
                    seconds: 0,
                    rawFractionalSeconds: ArraySlice<UInt8>()
                )
            ),  // only 30 days in June
            (
                "20210731000000Z",
                try .init(
                    year: 2021,
                    month: 7,
                    day: 31,
                    hours: 0,
                    minutes: 0,
                    seconds: 0,
                    fractionalSeconds: 0
                )
            ),
            (
                "20210731000000Z",
                try .init(
                    year: 2021,
                    month: 7,
                    day: 31,
                    hours: 0,
                    minutes: 0,
                    seconds: 0,
                    rawFractionalSeconds: ArraySlice<UInt8>()
                )
            ),  // only 31 days in July
            (
                "20210831000000Z",
                try .init(
                    year: 2021,
                    month: 8,
                    day: 31,
                    hours: 0,
                    minutes: 0,
                    seconds: 0,
                    fractionalSeconds: 0
                )
            ),
            (
                "20210831000000Z",
                try .init(
                    year: 2021,
                    month: 8,
                    day: 31,
                    hours: 0,
                    minutes: 0,
                    seconds: 0,
                    rawFractionalSeconds: ArraySlice<UInt8>()
                )
            ),  // only 31 days in August
            (
                "20210930000000Z",
                try .init(
                    year: 2021,
                    month: 9,
                    day: 30,
                    hours: 0,
                    minutes: 0,
                    seconds: 0,
                    fractionalSeconds: 0
                )
            ),
            (
                "20210930000000Z",
                try .init(
                    year: 2021,
                    month: 9,
                    day: 30,
                    hours: 0,
                    minutes: 0,
                    seconds: 0,
                    rawFractionalSeconds: ArraySlice<UInt8>()
                )
            ),  // only 30 days in September
            (
                "20211031000000Z",
                try .init(
                    year: 2021,
                    month: 10,
                    day: 31,
                    hours: 0,
                    minutes: 0,
                    seconds: 0,
                    fractionalSeconds: 0
                )
            ),
            (
                "20211031000000Z",
                try .init(
                    year: 2021,
                    month: 10,
                    day: 31,
                    hours: 0,
                    minutes: 0,
                    seconds: 0,
                    rawFractionalSeconds: ArraySlice<UInt8>()
                )
            ),  // only 31 days in October
            (
                "20211130000000Z",
                try .init(
                    year: 2021,
                    month: 11,
                    day: 30,
                    hours: 0,
                    minutes: 0,
                    seconds: 0,
                    fractionalSeconds: 0
                )
            ),
            (
                "20211130000000Z",
                try .init(
                    year: 2021,
                    month: 11,
                    day: 30,
                    hours: 0,
                    minutes: 0,
                    seconds: 0,
                    rawFractionalSeconds: ArraySlice<UInt8>()
                )
            ),  // only 30 days in November
            (
                "20211231000000Z",
                try .init(
                    year: 2021,
                    month: 12,
                    day: 31,
                    hours: 0,
                    minutes: 0,
                    seconds: 0,
                    fractionalSeconds: 0
                )
            ),
            (
                "20211231000000Z",
                try .init(
                    year: 2021,
                    month: 12,
                    day: 31,
                    hours: 0,
                    minutes: 0,
                    seconds: 0,
                    rawFractionalSeconds: ArraySlice<UInt8>()
                )
            ),  // only 31 days in December
            (
                "19851106210627.10000000000000001Z",
                try .init(
                    year: 1985,
                    month: 11,
                    day: 6,
                    hours: 21,
                    minutes: 6,
                    seconds: 27,
                    rawFractionalSeconds: ArraySlice<UInt8>([
                        49, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 48, 49,
                    ])
                )
                // `fractionalSeconds` loses precision and becomes 0.1 rather than
                // 0.10000000000000001, but the preserved raw value still round-trips.
            ),

            // Invalid representations
            ("19920520240000Z", nil),  // midnight may not be 2400000
            ("19920622123421.0Z", nil),  // spurious trailing zeros
            ("19920722132100.30Z", nil),  // spurious trailing zeros
            ("19851106210627,3Z", nil),  // comma as decimal separator
            ("1985110621.14159Z", nil),  // missing minutes and seconds
            ("198511062106.14159Z", nil),  // missing seconds
            ("19851106210627.3", nil),  // missing trailing Z
            ("19851106210627.3-0500", nil),  // explicit time zone
            ("20211300000000Z", nil),  // there is no 13th month
            ("20210000000000Z", nil),  // there is no zeroth month
            ("20210100000000Z", nil),  // there is no zeroth day
            ("20210101000062Z", nil),  // 62nd second is not allowed
            ("20210101236000Z", nil),  // 60th minute is not allowed
            ("20210132000000Z", nil),  // only 31 days in January
            ("20210229000000Z", nil),  // only 28 days in February 2021
            ("20200230000000Z", nil),  // only 29 days in February 2020
            ("21000229000000Z", nil),  // only 28 days in February 2100
            ("20000230000000Z", nil),  // only 29 days in February 2000
            ("20210332000000Z", nil),  // only 31 days in March
            ("20210431000000Z", nil),  // only 30 days in April
            ("20210532000000Z", nil),  // only 31 days in May
            ("20210631000000Z", nil),  // only 30 days in June
            ("20210732000000Z", nil),  // only 31 days in July
            ("20210832000000Z", nil),  // only 31 days in August
            ("20210931000000Z", nil),  // only 30 days in September
            ("20211032000000Z", nil),  // only 31 days in October
            ("20211131000000Z", nil),  // only 30 days in November
            ("19920521000000.", nil),  // invalid fractional seconds and missing trailing Z
            ("19920521000000.Z", nil),  // invalid fractional seconds

        ]

        for (stringRepresentation, expectedResult) in vectors {
            var serialized = [UInt8]()
            serialized.writeIdentifier(ISO_8824.Identifier.generalizedTime, constructed: false)
            serialized.append(UInt8(stringRepresentation.utf8.count))
            serialized.append(contentsOf: stringRepresentation.utf8)

            let result: ISO_8824.GeneralizedTime?
            do throws(ISO_8824.Error) {
                result = try ISO_8824.GeneralizedTime(derEncoded: serialized)
            } catch { result = nil }
            #expect(result == expectedResult)

            if let expected = expectedResult {
                try self.assertRoundTrips(expected)
            }
        }
    }

    @Test
    func `truncated representations rejected`() throws {
        func mustNotDeserialize(_ stringRepresentation: Substring) {
            var serialized = [UInt8]()
            serialized.writeIdentifier(ISO_8824.Identifier.generalizedTime, constructed: false)
            serialized.append(UInt8(stringRepresentation.utf8.count))
            serialized.append(contentsOf: stringRepresentation.utf8)

            #expect(throws: ISO_8824.Error.self) {
                try ISO_8824.GeneralizedTime(derEncoded: serialized)
            }
        }

        func deserializes(_ stringRepresentation: Substring) {
            var serialized = [UInt8]()
            serialized.writeIdentifier(ISO_8824.Identifier.generalizedTime, constructed: false)
            serialized.append(UInt8(stringRepresentation.utf8.count))
            serialized.append(contentsOf: stringRepresentation.utf8)

            #expect(throws: Never.self) { try ISO_8824.GeneralizedTime(derEncoded: serialized) }
        }

        // Anything that doesn't end up in a Z must fail to deserialize.
        let string = Substring("19851106210627.14159Z")
        for distance in 0..<string.count {
            let sliced = string.prefix(distance)
            mustNotDeserialize(sliced)
        }

        deserializes(string)

        // Adding some excess data should fail too.
        for junkByteCount in 1...string.count {
            let junked = string + string.prefix(junkByteCount)
            mustNotDeserialize(junked)
        }
    }

    @Test
    func `requires appropriate tag`() throws {
        let rawValue = "19920521000000Z".utf8
        var invalidBytes = [UInt8]()
        // GeneralizedTime is not an integer.
        invalidBytes.writeIdentifier(ISO_8824.Identifier.integer, constructed: false)
        invalidBytes.append(UInt8(rawValue.count))
        invalidBytes.append(contentsOf: rawValue)

        #expect(throws: ISO_8824.Error.self) {
            try ISO_8824.GeneralizedTime(derEncoded: invalidBytes)
        }
    }
}
