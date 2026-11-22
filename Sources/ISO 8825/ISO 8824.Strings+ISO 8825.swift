public import ISO_8824

extension ISO.`8824`.UTF8String: ISO.`8825`.DER.ImplicitlyTaggable, ISO.`8825`.BER.ImplicitlyTaggable {
    @inlinable
    public init(
        derEncoded node: ISO.`8825`.Node,
        withIdentifier identifier: ISO.`8824`.Identifier
    ) throws(ISO.`8824`.Error) {
        let content = try ISO.`8824`.OctetString(derEncoded: node, withIdentifier: identifier).bytes
        try self.init(contentBytes: content)
    }

    @inlinable
    public init(
        berEncoded node: ISO.`8825`.Node,
        withIdentifier identifier: ISO.`8824`.Identifier
    ) throws(ISO.`8824`.Error) {
        let content = try ISO.`8824`.OctetString(berEncoded: node, withIdentifier: identifier).bytes
        try self.init(contentBytes: content)
    }

    @inlinable
    public func serialize(
        into coder: inout ISO.`8825`.DER.Serializer,
        withIdentifier identifier: ISO.`8824`.Identifier
    ) throws(ISO.`8824`.Error) {
        let octet = ISO.`8824`.OctetString(contentBytes: self.bytes)
        try octet.serialize(into: &coder, withIdentifier: identifier)
    }
}

extension ISO.`8824`.TeletexString: ISO.`8825`.DER.ImplicitlyTaggable, ISO.`8825`.BER.ImplicitlyTaggable {
    @inlinable
    public init(
        derEncoded node: ISO.`8825`.Node,
        withIdentifier identifier: ISO.`8824`.Identifier
    ) throws(ISO.`8824`.Error) {
        self.init(
            contentBytes: try ISO.`8824`.OctetString(derEncoded: node, withIdentifier: identifier)
                .bytes
        )
    }

    @inlinable
    public init(
        berEncoded node: ISO.`8825`.Node,
        withIdentifier identifier: ISO.`8824`.Identifier
    ) throws(ISO.`8824`.Error) {
        self.init(
            contentBytes: try ISO.`8824`.OctetString(berEncoded: node, withIdentifier: identifier)
                .bytes
        )
    }

    @inlinable
    public func serialize(
        into coder: inout ISO.`8825`.DER.Serializer,
        withIdentifier identifier: ISO.`8824`.Identifier
    ) throws(ISO.`8824`.Error) {
        let octet = ISO.`8824`.OctetString(contentBytes: self.bytes)
        try octet.serialize(into: &coder, withIdentifier: identifier)
    }
}

extension ISO.`8824`.PrintableString: ISO.`8825`.DER.ImplicitlyTaggable, ISO.`8825`.BER.ImplicitlyTaggable {
    @inlinable
    public init(
        derEncoded node: ISO.`8825`.Node,
        withIdentifier identifier: ISO.`8824`.Identifier
    ) throws(ISO.`8824`.Error) {

        self = try Self(
            contentBytes: ISO.`8824`.OctetString(derEncoded: node, withIdentifier: identifier).bytes
        )
    }

    @inlinable
    public init(
        berEncoded node: ISO.`8825`.Node,
        withIdentifier identifier: ISO.`8824`.Identifier
    ) throws(ISO.`8824`.Error) {
        self = try Self(
            contentBytes: ISO.`8824`.OctetString(berEncoded: node, withIdentifier: identifier).bytes
        )
    }

    @inlinable
    public func serialize(
        into coder: inout ISO.`8825`.DER.Serializer,
        withIdentifier identifier: ISO.`8824`.Identifier
    ) throws(ISO.`8824`.Error) {
        let octet = ISO.`8824`.OctetString(contentBytes: self.bytes)
        try octet.serialize(into: &coder, withIdentifier: identifier)
    }
}

extension ISO.`8824`.VisibleString: ISO.`8825`.DER.ImplicitlyTaggable, ISO.`8825`.BER.ImplicitlyTaggable {
    @inlinable
    public init(
        derEncoded node: ISO.`8825`.Node,
        withIdentifier identifier: ISO.`8824`.Identifier
    ) throws(ISO.`8824`.Error) {
        self = try Self(
            contentBytes: ISO.`8824`.OctetString(derEncoded: node, withIdentifier: identifier).bytes
        )
    }

    @inlinable
    public init(
        berEncoded node: ISO.`8825`.Node,
        withIdentifier identifier: ISO.`8824`.Identifier
    ) throws(ISO.`8824`.Error) {
        self = try Self(
            contentBytes: ISO.`8824`.OctetString(berEncoded: node, withIdentifier: identifier).bytes
        )
    }

    @inlinable
    public func serialize(
        into coder: inout ISO.`8825`.DER.Serializer,
        withIdentifier identifier: ISO.`8824`.Identifier
    ) throws(ISO.`8824`.Error) {
        let octet = ISO.`8824`.OctetString(contentBytes: self.bytes)
        try octet.serialize(into: &coder, withIdentifier: identifier)
    }
}

extension ISO.`8824`.UniversalString: ISO.`8825`.DER.ImplicitlyTaggable, ISO.`8825`.BER.ImplicitlyTaggable {
    @inlinable
    public init(
        derEncoded node: ISO.`8825`.Node,
        withIdentifier identifier: ISO.`8824`.Identifier
    ) throws(ISO.`8824`.Error) {
        self.init(
            contentBytes: try ISO.`8824`.OctetString(derEncoded: node, withIdentifier: identifier)
                .bytes
        )
    }

    @inlinable
    public init(
        berEncoded node: ISO.`8825`.Node,
        withIdentifier identifier: ISO.`8824`.Identifier
    ) throws(ISO.`8824`.Error) {
        self.init(
            contentBytes: try ISO.`8824`.OctetString(berEncoded: node, withIdentifier: identifier)
                .bytes
        )
    }

    @inlinable
    public func serialize(
        into coder: inout ISO.`8825`.DER.Serializer,
        withIdentifier identifier: ISO.`8824`.Identifier
    ) throws(ISO.`8824`.Error) {
        let octet = ISO.`8824`.OctetString(contentBytes: self.bytes)
        try octet.serialize(into: &coder, withIdentifier: identifier)
    }
}

extension ISO.`8824`.BMPString: ISO.`8825`.DER.ImplicitlyTaggable, ISO.`8825`.BER.ImplicitlyTaggable {
    @inlinable
    public init(
        derEncoded node: ISO.`8825`.Node,
        withIdentifier identifier: ISO.`8824`.Identifier
    ) throws(ISO.`8824`.Error) {
        self.init(
            contentBytes: try ISO.`8824`.OctetString(derEncoded: node, withIdentifier: identifier)
                .bytes
        )
    }

    @inlinable
    public init(
        berEncoded node: ISO.`8825`.Node,
        withIdentifier identifier: ISO.`8824`.Identifier
    ) throws(ISO.`8824`.Error) {
        self.init(
            contentBytes: try ISO.`8824`.OctetString(berEncoded: node, withIdentifier: identifier)
                .bytes
        )
    }

    @inlinable
    public func serialize(
        into coder: inout ISO.`8825`.DER.Serializer,
        withIdentifier identifier: ISO.`8824`.Identifier
    ) throws(ISO.`8824`.Error) {
        let octet = ISO.`8824`.OctetString(contentBytes: self.bytes)
        try octet.serialize(into: &coder, withIdentifier: identifier)
    }
}

extension ISO.`8824`.IA5String: ISO.`8825`.DER.ImplicitlyTaggable, ISO.`8825`.BER.ImplicitlyTaggable {
    @inlinable
    public init(
        derEncoded node: ISO.`8825`.Node,
        withIdentifier identifier: ISO.`8824`.Identifier
    ) throws(ISO.`8824`.Error) {
        self = try Self(
            contentBytes: ISO.`8824`.OctetString(derEncoded: node, withIdentifier: identifier).bytes
        )
    }

    @inlinable
    public init(
        berEncoded node: ISO.`8825`.Node,
        withIdentifier identifier: ISO.`8824`.Identifier
    ) throws(ISO.`8824`.Error) {
        self = try Self(
            contentBytes: ISO.`8824`.OctetString(berEncoded: node, withIdentifier: identifier).bytes
        )
    }

    @inlinable
    public func serialize(
        into coder: inout ISO.`8825`.DER.Serializer,
        withIdentifier identifier: ISO.`8824`.Identifier
    ) throws(ISO.`8824`.Error) {
        let octet = ISO.`8824`.OctetString(contentBytes: self.bytes)
        try octet.serialize(into: &coder, withIdentifier: identifier)
    }
}
