//===----------------------------------------------------------------------===//
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
//===----------------------------------------------------------------------===//

public import ISO_8824

extension ISO_8825 {
    /// ``ISO_8825/Integer`` is the namespace for the INTEGER wire discipline:
    /// the X.690 §8.3 content-octet encoding and the protocol that integer
    /// types adopt to participate in it.
    public enum Integer {}
}

@available(*, unavailable)
extension ISO_8825.Integer: Sendable {}

extension ISO_8825.Integer {
    /// The codec-facing refinement of ``ISO_8824/Integer/Representable``.
    ///
    /// The value-facing half of the protocol (`isSigned`, `IntegerBytes`,
    /// `withBigEndianIntegerBytes(_:)`) lives in ISO_8824; this refinement adds
    /// the X.690 §8.3 content-octet decode requirements and the wire
    /// conformances.
    ///
    /// This protocol exists to allow users to handle the possibility of decoding integers that cannot fit into
    /// UInt64 or Int64. While both of those types conform by default, users can conform their preferred
    /// arbitrary-width integer type as well, or use `ArraySlice<UInt8>` to store the raw bytes of the
    /// integer directly.
    public protocol Representable: ISO_8824.Integer.Representable, ISO_8825.DER.ImplicitlyTaggable, ISO_8825.BER.ImplicitlyTaggable {
        /// Construct the integer value from the integer bytes. These will be big-endian, and encoded
        /// according to DER requirements.
        // -> Byte discipline: deferred ([API-BYTE-004]); see lead notes.
        init(derIntegerBytes: ArraySlice<UInt8>) throws(ISO_8824.Error)

        /// Construct the integer value form the integer bytes. These will be big-endian, and encoded
        /// accroding to BER requirements.
        init(berIntegerBytes: ArraySlice<UInt8>) throws(ISO_8824.Error)
    }
}

extension ISO_8825.Integer.Representable {
    @inlinable
    public static var defaultIdentifier: ISO_8824.Identifier {
        .integer
    }

    @inlinable
    public init(derEncoded node: ISO_8825.Node, withIdentifier identifier: ISO_8824.Identifier) throws(ISO_8824.Error) {
        guard node.identifier == identifier else {
            throw ISO_8824.Error.unexpectedFieldType(node.identifier)
        }

        guard case .primitive(var dataBytes) = node.content else {
            throw ISO_8824.Error.invalidASN1Object(reason: "INTEGER encoded with constructed encoding")
        }

        // Zero bytes of integer is not an acceptable encoding.
        guard dataBytes.count > 0 else {
            throw ISO_8824.Error.invalidASN1IntegerEncoding(reason: "INTEGER encoded with zero bytes")
        }

        // 8.3.2 If the contents octets of an integer value encoding consist of more than one octet, then the bits of the first octet and bit 8 of the second octet:
        //
        // a) shall not all be ones; and
        // b) shall not all be zero.
        //
        // NOTE – These rules ensure that an integer value is always encoded in the smallest possible number of octets.
        if let first = dataBytes.first, let second = dataBytes.dropFirst().first {
            if (first == 0xFF) && second._topBitSet || (first == 0x00) && !second._topBitSet {
                throw ISO_8824.Error.invalidASN1IntegerEncoding(reason: "INTEGER not encoded in fewest number of octets")
            }
        }

        // If the type we're trying to decode is unsigned, and the top byte is zero, we should strip it.
        // If the top bit is set, however, this is an invalid conversion: the number needs to be positive!
        if !Self.isSigned, let first = dataBytes.first {
            if first == 0x00 {
                dataBytes = dataBytes.dropFirst()
            } else if first & 0x80 == 0x80 {
                throw ISO_8824.Error.invalidASN1IntegerEncoding(reason: "INTEGER encoded with top bit set!")
            }
        }

        self = try Self(derIntegerBytes: dataBytes)
    }

    @inlinable
    public init(berEncoded node: ISO_8825.Node, withIdentifier identifier: ISO_8824.Identifier) throws(ISO_8824.Error) {
        guard node.identifier == identifier else {
            throw ISO_8824.Error.unexpectedFieldType(node.identifier)
        }

        guard case .primitive(var dataBytes) = node.content else {
            throw ISO_8824.Error.invalidASN1Object(reason: "INTEGER encoded with constructed encoding")
        }

        // Zero bytes of integer is not an acceptable encoding.
        guard dataBytes.count > 0 else {
            throw ISO_8824.Error.invalidASN1IntegerEncoding(reason: "INTEGER encoded with zero bytes")
        }

        // If the type we're trying to decode is unsigned, and the top byte is zero, we should strip it.
        // If the top bit is set, however, this is an invalid conversion: the number needs to be positive!
        if !Self.isSigned, let first = dataBytes.first {
            if first == 0x00 {
                dataBytes = dataBytes.dropFirst()
            } else if first & 0x80 == 0x80 {
                throw ISO_8824.Error.invalidASN1IntegerEncoding(reason: "INTEGER encoded with top bit set!")
            }
        }

        self = try Self(berIntegerBytes: dataBytes)
    }

    @inlinable
    public func serialize(into coder: inout ISO_8825.DER.Serializer, withIdentifier identifier: ISO_8824.Identifier) throws(ISO_8824.Error) {
        coder.appendPrimitiveNode(identifier: identifier) { bytes in
            self.withBigEndianIntegerBytes { integerBytes in
                // If the number of bytes is 0, we're encoding a zero. That actually _does_ require one byte.
                if integerBytes.count == 0 {
                    bytes.append(0)
                    return
                }

                // If self is unsigned and the first byte has the top bit set, we need to prepend a 0 byte.
                if !Self.isSigned, let topByte = integerBytes.first, topByte._topBitSet {
                    bytes.append(0)
                    bytes.append(contentsOf: integerBytes)
                } else {
                    // Either self is signed, or the top bit isn't set. Either way, trim to make sure the representation is minimal.
                    bytes.append(contentsOf: integerBytes._trimLeadingExcessBytes())
                }
            }
        }
    }
}

// MARK: - Auto-conformance for FixedWidthInteger with fixed width magnitude.
extension ISO_8825.Integer.Representable where Self: FixedWidthInteger {
    @inlinable
    public init(derIntegerBytes bytes: ArraySlice<UInt8>) throws(ISO_8824.Error) {
        // Defer to the FixedWidthInteger constructor.
        // There's a wrinkle here: if this is a signed integer, and the top bit of the data bytes was set,
        // then we need to 1-extend the bytes. This is because ASN.1 tries to delete redundant bytes that
        // are all 1.
        self = try Self(bigEndianBytes: bytes)

        if Self.isSigned, let first = bytes.first, first._topBitSet {
            for shift in stride(from: self.bitWidth - self.leadingZeroBitCount, to: self.bitWidth, by: 8) {
                self |= 0xFF << shift
            }
        }
    }

    @inlinable
    public init(berIntegerBytes bytes: ArraySlice<UInt8>) throws(ISO_8824.Error) {
        self = try .init(derIntegerBytes: bytes)
    }

    // `withBigEndianIntegerBytes(_:)` for FixedWidthInteger is provided by the
    // base protocol's extension in ISO_8824 (via ISO_8824.Integer.Bytes).
}

// The big-endian integer-bytes collection (upstream `IntegerBytesCollection`)
// lives in ISO_8824 as `ISO_8824.Integer.Bytes` — value law, not wire law.

extension Int8: ISO_8825.Integer.Representable {}

extension UInt8: ISO_8825.Integer.Representable {}

extension Int16: ISO_8825.Integer.Representable {}

extension UInt16: ISO_8825.Integer.Representable {}

extension Int32: ISO_8825.Integer.Representable {}

extension UInt32: ISO_8825.Integer.Representable {}

extension Int64: ISO_8825.Integer.Representable {}

extension UInt64: ISO_8825.Integer.Representable {}

extension Int: ISO_8825.Integer.Representable {}

extension UInt: ISO_8825.Integer.Representable {}

extension RandomAccessCollection where Element == UInt8 {
    @inlinable
    func _trimLeadingExcessBytes() -> SubSequence {
        var slice = self[...]
        guard let first = slice.first else {
            // Easy case, empty.
            return slice
        }

        let wholeByte: UInt8

        switch first {
        case 0:
            wholeByte = 0
        case 0xFF:
            wholeByte = 0xFF
        default:
            // We're already fine, this is maximally compact. We need the whole thing.
            return slice
        }

        // We never trim this to less than one byte, as that's always the smallest representation.
        while slice.count > 1 {
            // If the first byte is equal to our original first byte, and the top bit
            // of the next byte is also equal to that, then we need to drop the byte and
            // go again.
            if slice.first != wholeByte {
                break
            }

            guard let second = slice.dropFirst().first else {
                preconditionFailure("Loop condition violated: must be at least two bytes left")
            }

            if second & 0x80 != wholeByte & 0x80 {
                // Different top bit, we need the leading byte.
                break
            }

            // Both the first byte and the top bit of the next are all zero or all 1, drop the leading
            // byte.
            slice = slice.dropFirst()
        }

        return slice
    }
}

extension UInt8 {
    @inlinable
    var _topBitSet: Bool {
        return (self & 0x80) != 0
    }
}
