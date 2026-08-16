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

// The X.690 §8.7 wire discipline for the X.680 OCTET STRING value type. The
// abstract value (the octets) lives in ISO_8824; the primitive content-octet
// codec and the BER constructed-segment flattening are X.690 wire law and are
// owned here.
//
// `defaultIdentifier` is declared publicly on the value type in ISO_8824 and
// witnesses the requirement from there; it is not re-declared in this extension.

extension ISO_8824.OctetString: ISO_8825.DER.ImplicitlyTaggable, ISO_8825.BER.ImplicitlyTaggable {
    @inlinable
    public init(
        derEncoded node: ISO_8825.Node,
        withIdentifier identifier: ISO_8824.Identifier
    ) throws(ISO_8824.Error) {
        guard node.identifier == identifier else {
            throw ISO_8824.Error.unexpectedFieldType(node.identifier)
        }

        guard case .primitive(let content) = node.content else {
            throw ISO_8824.Error.invalidASN1Object(
                reason: "OctetString encoded with constructed encoding"
            )
        }

        self.init(contentBytes: content)
    }

    @inlinable
    public init(
        berEncoded node: ISO_8825.Node,
        withIdentifier identifier: ISO_8824.Identifier
    ) throws(ISO_8824.Error) {
        guard node.identifier == identifier else {
            throw ISO_8824.Error.unexpectedFieldType(node.identifier)
        }

        switch node.content {
        case .constructed(let nodes):
            // BER allows constructed OCTET STRINGs, that is, an OCTET STRING that is represented
            // by a composition of many individual recursively encoded (primitive or constructed)
            // OCTET STRINGs.

            // We have to allocate here, since we need to flatten all of the sub octet-strings into a contiguous view
            // Maybe it's possible in the future something like [chain](https://github.com/apple/swift-algorithms/blob/main/Guides/Chain.md)
            // could be used to eliminate allocations, but we need an ArraySlice
            let (count, maxLength) = nodes.reduce((0, 0)) { acc, elem in
                let (countAcc, lenAcc) = acc
                return (countAcc + 1, lenAcc + elem.encodedBytes.count)
            }

            if count == 0 {
                self.init(contentBytes: [])
                return
            }

            if count == 1 {
                // this recursive call might allocate if the inner string is also constructed, which means the recursive portions have returned a flattened view.
                for node in nodes {
                    let substring = try ISO_8824.OctetString(berEncoded: node)
                    self.init(contentBytes: substring.bytes)
                    return
                }
            }

            var flattened: [UInt8] = []
            // we are going to reserve capacity a bit over what reality will be, since we are hinting the allocation based on the entire encoded bytes, which includes tags and sizes
            flattened.reserveCapacity(maxLength)
            for node in nodes {
                let substring = try ISO_8824.OctetString(berEncoded: node)
                flattened += substring.bytes
            }

            self.init(contentBytes: flattened[...])

        case .primitive(let content):
            self.init(contentBytes: content)
        }
    }

    @inlinable
    public func serialize(
        into coder: inout ISO_8825.DER.Serializer,
        withIdentifier identifier: ISO_8824.Identifier
    ) throws(ISO_8824.Error) {
        coder.appendPrimitiveNode(identifier: identifier) { bytes in
            bytes.append(contentsOf: self.bytes)
        }
    }
}
