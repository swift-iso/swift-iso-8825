public import ISO_8824

extension ISO_8825 {

    public struct `Any`: ISO_8825.DER.Parseable, ISO_8825.BER.Parseable, ISO_8825.DER.Serializable,
        ISO_8825.BER.Serializable, Hashable, Sendable
    {
        @usableFromInline
        var _serializedBytes: ArraySlice<UInt8>

        @inlinable
        public init<ASN1Type: ISO_8825.DER.Serializable>(erasing: ASN1Type) throws(ISO_8824.Error) {
            var serializer = ISO_8825.DER.Serializer()
            try erasing.serialize(into: &serializer)
            self._serializedBytes = ArraySlice(serializer._serializedBytes)
        }

        @inlinable
        public init<ASN1Type: ISO_8825.DER.ImplicitlyTaggable>(
            erasing: ASN1Type,
            withIdentifier identifier: ISO_8824.Identifier
        ) throws(ISO_8824.Error) {
            var serializer = ISO_8825.DER.Serializer()
            try erasing.serialize(into: &serializer, withIdentifier: identifier)
            self._serializedBytes = ArraySlice(serializer._serializedBytes)
        }

        @inlinable
        public init(derEncoded rootNode: ISO_8825.Node) {

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

    @inlinable
    public init(asn1Any: ISO_8825.`Any`) throws(ISO_8824.Error) {
        try self.init(derEncoded: asn1Any._serializedBytes)
    }
}

extension ISO_8825.DER.ImplicitlyTaggable {

    @inlinable
    public init(
        asn1Any: ISO_8825.`Any`,
        withIdentifier identifier: ISO_8824.Identifier
    ) throws(ISO_8824.Error) {
        try self.init(derEncoded: asn1Any._serializedBytes, withIdentifier: identifier)
    }
}

extension ISO_8825.BER.Parseable {

    @inlinable
    public init(berASN1Any: ISO_8825.`Any`) throws(ISO_8824.Error) {
        try self.init(berEncoded: berASN1Any._serializedBytes)
    }
}

extension ISO_8825.BER.ImplicitlyTaggable {

    @inlinable
    public init(
        berASN1Any: ISO_8825.`Any`,
        withIdentifier identifier: ISO_8824.Identifier
    ) throws(ISO_8824.Error) {
        try self.init(berEncoded: berASN1Any._serializedBytes, withIdentifier: identifier)
    }
}
