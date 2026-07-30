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

// The X.690 §8.19 wire discipline for the X.680 OBJECT IDENTIFIER value type.
// The abstract value (packed subidentifier components, OID catalogs, dot
// representation) lives in ISO_8824; the content-octet extraction, encoded-form
// validation, and emission are X.690 wire law and are owned here.
//
// `defaultIdentifier` is declared publicly on the value type in ISO_8824 and
// witnesses the requirement from there; it is not re-declared in this extension.

extension ISO_8824.ObjectIdentifier: ISO_8825.DER.ImplicitlyTaggable, ISO_8825.BER.ImplicitlyTaggable {
    @inlinable
    public init(derEncoded node: ISO_8825.Node, withIdentifier identifier: ISO_8824.Identifier) throws(ISO_8824.Error) {
        guard node.identifier == identifier else {
            throw ISO_8824.Error.unexpectedFieldType(node.identifier)
        }

        guard case .primitive(let content) = node.content else {
            throw ISO_8824.Error.invalidASN1Object(reason: "OID encoded with constructed encoding")
        }

        try Self.validateObjectIdentifierInEncodedForm(content)

        try self.init(encodedForm: content)
    }

    @inlinable
    public init(berEncoded node: ISO_8825.Node, withIdentifier identiifer: ISO_8824.Identifier) throws(ISO_8824.Error) {
        self = try .init(derEncoded: node, withIdentifier: identiifer)
    }

    @inlinable
    public func serialize(into coder: inout ISO_8825.DER.Serializer, withIdentifier identifier: ISO_8824.Identifier) throws(ISO_8824.Error) {
        coder.appendPrimitiveNode(identifier: identifier) { bytes in
            bytes.append(contentsOf: self.bytes)
        }
    }

    /// Validates that content octets obey the X.690 §8.19 base-128 subidentifier
    /// wire discipline.
    ///
    /// ISO_8824 retains a package-scoped copy of this check as value law over its
    /// packed representation; this copy is the wire-side gate for decoded content
    /// octets and is invisible to it.
    @inlinable
    package static func validateObjectIdentifierInEncodedForm(_ content: ArraySlice<UInt8>) throws(ISO_8824.Error) {
        var content = content

        guard content.count >= 1 else {
            throw ISO_8824.Error.invalidASN1Object(reason: "Zero components in OID")
        }

        while content.count > 0 {
            _ = try content.readUIntUsing8BitBytesASN1Discipline()
        }
    }
}
