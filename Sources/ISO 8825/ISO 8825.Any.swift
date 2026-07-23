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

extension ISO_8825 {
    /// An ASN1 ANY represents...well, anything.
    ///
    /// In this case we store the ASN.1 ANY as a serialized representation. This is a bit limiting,
    /// but it's the only safe way to manage this data, as we cannot arbitrarily parse it.
    ///
    /// The only things users can do with ASN.1 ANYs is to try to decode them as something else,
    /// to create them from something else, or to serialize them.
    public struct `Any`: ISO_8825.DER.Parseable, ISO_8825.BER.Parseable, ISO_8825.DER.Serializable, ISO_8825.BER.Serializable, Hashable, Sendable {
        @usableFromInline
        var _serializedBytes: ArraySlice<UInt8>

        /// Create an ``ISO_8825/Any`` from a serializable ASN1 type.
        ///
        /// - parameters:
        ///     erasing: The type to be represented as an ASN1 ANY.
        @inlinable
        public init<ASN1Type: ISO_8825.DER.Serializable>(erasing: ASN1Type) throws(ISO_8824.Error) {
            var serializer = ISO_8825.DER.Serializer()
            try erasing.serialize(into: &serializer)
            self._serializedBytes = ArraySlice(serializer._serializedBytes)
        }

        /// Create an ``ISO_8825/Any`` from a serializable implicitly taggable ASN1 type.
        ///
        /// - parameters:
        ///     erasing: The type to be represented as an ASN1 ANY.
        ///     identifier: The tag to use with this node.
        @inlinable
        public init<ASN1Type: ISO_8825.DER.ImplicitlyTaggable>(erasing: ASN1Type, withIdentifier identifier: ISO_8824.Identifier) throws(ISO_8824.Error) {
            var serializer = ISO_8825.DER.Serializer()
            try erasing.serialize(into: &serializer, withIdentifier: identifier)
            self._serializedBytes = ArraySlice(serializer._serializedBytes)
        }

        @inlinable
        public init(derEncoded rootNode: ISO_8825.Node) {
            // This is a bit sad: we just re-serialize this data. In an ideal world
            // we'd update the parse representation so that all nodes can point at their
            // complete backing storage, but for now this is better.
            var serializer = ISO_8825.DER.Serializer()
            serializer.serialize(rootNode)
            self._serializedBytes = ArraySlice(serializer._serializedBytes)
        }

        @inlinable
        public init(berEncoded rootNode: ISO_8825.Node) {
            self = .init(derEncoded: rootNode)
        }

        @inlinable
        public func serialize(into coder: inout ISO_8825.DER.Serializer) throws(ISO_8824.Error) {
            // Dangerous to just reach in there like this, but it's the right way to serialize this.
            coder.serializeRawBytes(self._serializedBytes)
        }
    }
}

extension ISO_8825.`Any`: CustomStringConvertible {
    @inlinable
    public var description: String {
        "ISO_8825.`Any`(\(self._serializedBytes))"
    }
}

extension ISO_8825.DER.Parseable {
    /// Construct this node from an ASN.1 ANY object.
    ///
    /// This operation works by asking the type to decode itself from the serialized representation
    /// of this ASN.1 ANY node.
    ///
    /// - parameters:
    ///     asn1Any: The ASN.1 ANY object to reinterpret.
    @inlinable
    public init(asn1Any: ISO_8825.`Any`) throws(ISO_8824.Error) {
        try self.init(derEncoded: asn1Any._serializedBytes)
    }
}

extension ISO_8825.DER.ImplicitlyTaggable {
    /// Construct this node from an ASN.1 ANY object.
    ///
    /// This operation works by asking the type to decode itself from the serialized representation
    /// of this ASN.1 ANY node.
    ///
    /// - parameters:
    ///     asn1Any: The ASN.1 ANY object to reinterpret.
    ///     identifier: The tag to use with this node.
    @inlinable
    public init(asn1Any: ISO_8825.`Any`, withIdentifier identifier: ISO_8824.Identifier) throws(ISO_8824.Error) {
        try self.init(derEncoded: asn1Any._serializedBytes, withIdentifier: identifier)
    }
}

extension ISO_8825.BER.Parseable {
    /// Construct this node from an ASN.1 ANY object.
    ///
    /// This operation works by asking the type to decode itself from the serialized representation
    /// of this ASN.1 ANY node.
    ///
    /// - parameters:
    ///     berASN1Any: The ASN.1 ANY object to reinterpret.
    @inlinable
    public init(berASN1Any: ISO_8825.`Any`) throws(ISO_8824.Error) {
        try self.init(berEncoded: berASN1Any._serializedBytes)
    }
}

extension ISO_8825.BER.ImplicitlyTaggable {
    /// Construct this node from an ASN.1 ANY object.
    ///
    /// This operation works by asking the type to decode itself from the serialized representation
    /// of this ASN.1 ANY node.
    ///
    /// - parameters:
    ///     berASN1Any: The ASN.1 ANY object to reinterpret.
    ///     identifier: The tag to use with this node.
    @inlinable
    public init(berASN1Any: ISO_8825.`Any`, withIdentifier identifier: ISO_8824.Identifier) throws(ISO_8824.Error) {
        try self.init(berEncoded: berASN1Any._serializedBytes, withIdentifier: identifier)
    }
}
