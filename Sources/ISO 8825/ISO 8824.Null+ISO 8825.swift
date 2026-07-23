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

public import ISO_8824

// The X.690 §8.8 wire discipline for the X.680 NULL value type. The abstract
// value lives in ISO_8824; the empty-content codec is X.690 wire law and is
// owned here.
//
// `defaultIdentifier` is declared publicly on the value type in ISO_8824 and
// witnesses the requirement from there; it is not re-declared in this extension.

extension ISO_8824.Null: ISO_8825.DER.ImplicitlyTaggable, ISO_8825.BER.ImplicitlyTaggable {
    @inlinable
    public init(derEncoded node: ISO_8825.Node, withIdentifier identifier: ISO_8824.Identifier) throws(ISO_8824.Error) {
        guard node.identifier == identifier, case .primitive(let content) = node.content else {
            throw ISO_8824.Error.unexpectedFieldType(node.identifier)
        }

        guard content.count == 0 else {
            throw ISO_8824.Error.invalidASN1Object(reason: "Null must be empty, received \(content.count) bytes")
        }

        self.init()
    }

    @inlinable
    public init(berEncoded node: ISO_8825.Node, withIdentifier identifier: ISO_8824.Identifier) throws(ISO_8824.Error) {
        self = try .init(derEncoded: node, withIdentifier: identifier)
    }

    @inlinable
    public func serialize(into coder: inout ISO_8825.DER.Serializer, withIdentifier identifier: ISO_8824.Identifier) {
        coder.appendPrimitiveNode(identifier: identifier, { _ in })
    }
}
