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

public import ISO_8824

// The X.690 §8.6 wire discipline for the X.680 BIT STRING value type. The
// abstract value (bytes + paddingBits and their invariants) lives in ISO_8824;
// the leading padding-octet encoding and its decode-side canonicity checks are
// X.690 wire law and are owned here.
//
// `defaultIdentifier` is declared publicly on the value type in ISO_8824 and
// witnesses the requirement from there; it is not re-declared in this extension.

extension ISO_8824.BitString: ISO_8825.DER.ImplicitlyTaggable, ISO_8825.BER.ImplicitlyTaggable {
    @inlinable
    public init(derEncoded node: ISO_8825.Node, withIdentifier identifier: ISO_8824.Identifier) throws(ISO_8824.Error) {
        guard node.identifier == identifier else {
            throw ISO_8824.Error.unexpectedFieldType(node.identifier)
        }

        guard case .primitive(let content) = node.content else {
            throw ISO_8824.Error.invalidASN1Object(reason: "BitString encoded with constructed encoding")
        }

        // The initial octet explains how many of the bits in the _final_ octet are not part of the bitstring.
        guard let paddingBits = content.first, (0..<8).contains(paddingBits) else {
            throw ISO_8824.Error.invalidASN1Object(
                reason: "Unable to determine a valid number of padding bits for BitString"
            )
        }

        let bytes = content.dropFirst()

        // Decode-side canonicity checks (X.690 §8.6.2.3 and §11.2.1): these must
        // throw rather than rely on the value initializer's invariant validation,
        // so they run here before delegating to the value initializer in ISO_8824.
        if let finalByte = bytes.last {
            // This mask sets the bottom `paddingBits` bits to 1.
            let mask = ~(UInt8.max << paddingBits)
            if (finalByte & mask) != 0 {
                throw ISO_8824.Error.invalidASN1Object(
                    reason: "Invalid padding bits in BitString: \(paddingBits) of padding, \(finalByte) final byte"
                )
            }
        } else if paddingBits != 0 {
            // If there are no bytes, there must be no padding bits.
            throw ISO_8824.Error.invalidASN1Object(
                reason: "Invalid number of padding bits for BitString: \(paddingBits)"
            )
        }

        try self.init(bytes: bytes, paddingBits: Int(paddingBits))
    }

    @inlinable
    public init(berEncoded node: ISO_8825.Node, withIdentifier identifier: ISO_8824.Identifier) throws(ISO_8824.Error) {
        guard node.identifier == identifier else {
            throw ISO_8824.Error.unexpectedFieldType(node.identifier)
        }

        switch node.content {
        case .constructed:
            // BER allows constructed ASN1 BitStrings, that is, you can construct a BitString that is represented by a composition of many individual Primitive (non-constructed) BitStrings
            throw ISO_8824.Error.invalidASN1Object(reason: "Constructed encoding of BitString not yet supported")

        case .primitive:
            self = try Self(derEncoded: node, withIdentifier: identifier)
        }
    }

    @inlinable
    public func serialize(into coder: inout ISO_8825.DER.Serializer, withIdentifier identifier: ISO_8824.Identifier) throws(ISO_8824.Error) {
        coder.appendPrimitiveNode(identifier: identifier) { bytes in
            bytes.append(UInt8(truncatingIfNeeded: self.paddingBits))
            bytes.append(contentsOf: self.bytes)
        }
    }
}
