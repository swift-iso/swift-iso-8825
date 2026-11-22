public import ISO_8824

extension ISO.`8825` {

    public struct `Any`: ISO.`8825`.DER.Parseable, ISO.`8825`.BER.Parseable, ISO.`8825`.DER.Serializable,
        ISO.`8825`.BER.Serializable, Hashable, Sendable
    {
        @usableFromInline
        var _serializedBytes: ArraySlice<UInt8>

        @inlinable
        public init<ASN1Type: ISO.`8825`.DER.Serializable>(erasing: ASN1Type) throws(ISO.`8824`.Error) {
            var serializer = ISO.`8825`.DER.Serializer()
            try erasing.serialize(into: &serializer)
            self._serializedBytes = ArraySlice(serializer._serializedBytes)
        }

        @inlinable
        public init<ASN1Type: ISO.`8825`.DER.ImplicitlyTaggable>(
            erasing: ASN1Type,
            withIdentifier identifier: ISO.`8824`.Identifier
        ) throws(ISO.`8824`.Error) {
            var serializer = ISO.`8825`.DER.Serializer()
            try erasing.serialize(into: &serializer, withIdentifier: identifier)
            self._serializedBytes = ArraySlice(serializer._serializedBytes)
        }

        @inlinable
        public init(derEncoded rootNode: ISO.`8825`.Node) {

            var serializer = ISO.`8825`.DER.Serializer()
            serializer.serialize(rootNode)
            self._serializedBytes = ArraySlice(serializer._serializedBytes)
        }

        @inlinable
        public init(berEncoded rootNode: ISO.`8825`.Node) {
            self = .init(derEncoded: rootNode)
        }
    }
}

extension ISO.`8825`.`Any`: CustomStringConvertible {
    @inlinable
    public var description: String {
        "ISO.8825.`Any`(\(self._serializedBytes))"
    }
}

extension ISO.`8825`.DER.Parseable {

    @inlinable
    public init(asn1Any: ISO.`8825`.`Any`) throws(ISO.`8824`.Error) {
        try self.init(derEncoded: asn1Any._serializedBytes)
    }
}

extension ISO.`8825`.DER.ImplicitlyTaggable {

    @inlinable
    public init(
        asn1Any: ISO.`8825`.`Any`,
        withIdentifier identifier: ISO.`8824`.Identifier
    ) throws(ISO.`8824`.Error) {
        try self.init(derEncoded: asn1Any._serializedBytes, withIdentifier: identifier)
    }
}

extension ISO.`8825`.BER.Parseable {

    @inlinable
    public init(berASN1Any: ISO.`8825`.`Any`) throws(ISO.`8824`.Error) {
        try self.init(berEncoded: berASN1Any._serializedBytes)
    }
}

extension ISO.`8825`.BER.ImplicitlyTaggable {

    @inlinable
    public init(
        berASN1Any: ISO.`8825`.`Any`,
        withIdentifier identifier: ISO.`8824`.Identifier
    ) throws(ISO.`8824`.Error) {
        try self.init(berEncoded: berASN1Any._serializedBytes, withIdentifier: identifier)
    }
}

extension ISO.`8825`.`Any` {
    @inlinable
    public func serialize(into coder: inout ISO.`8825`.DER.Serializer) throws(ISO.`8824`.Error) {

        coder.serializeRawBytes(self._serializedBytes)
    }
}
