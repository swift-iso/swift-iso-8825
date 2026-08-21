public import ISO_8824

extension ISO_8824.UTF8String: ISO_8825.DER.ImplicitlyTaggable, ISO_8825.BER.ImplicitlyTaggable {
    @inlinable
    public init(
        derEncoded node: ISO_8825.Node,
        withIdentifier identifier: ISO_8824.Identifier
    ) throws(ISO_8824.Error) {
        self.init(
            contentBytes: try ISO_8824.OctetString(derEncoded: node, withIdentifier: identifier)
                .bytes
        )
    }

    @inlinable
    public init(
        berEncoded node: ISO_8825.Node,
        withIdentifier identifier: ISO_8824.Identifier
    ) throws(ISO_8824.Error) {
        self.init(
            contentBytes: try ISO_8824.OctetString(berEncoded: node, withIdentifier: identifier)
                .bytes
        )
    }

    @inlinable
    public func serialize(
        into coder: inout ISO_8825.DER.Serializer,
        withIdentifier identifier: ISO_8824.Identifier
    ) throws(ISO_8824.Error) {
        let octet = ISO_8824.OctetString(contentBytes: self.bytes)
        try octet.serialize(into: &coder, withIdentifier: identifier)
    }
}

extension ISO_8824.TeletexString: ISO_8825.DER.ImplicitlyTaggable, ISO_8825.BER.ImplicitlyTaggable {
    @inlinable
    public init(
        derEncoded node: ISO_8825.Node,
        withIdentifier identifier: ISO_8824.Identifier
    ) throws(ISO_8824.Error) {
        self.init(
            contentBytes: try ISO_8824.OctetString(derEncoded: node, withIdentifier: identifier)
                .bytes
        )
    }

    @inlinable
    public init(
        berEncoded node: ISO_8825.Node,
        withIdentifier identifier: ISO_8824.Identifier
    ) throws(ISO_8824.Error) {
        self.init(
            contentBytes: try ISO_8824.OctetString(berEncoded: node, withIdentifier: identifier)
                .bytes
        )
    }

    @inlinable
    public func serialize(
        into coder: inout ISO_8825.DER.Serializer,
        withIdentifier identifier: ISO_8824.Identifier
    ) throws(ISO_8824.Error) {
        let octet = ISO_8824.OctetString(contentBytes: self.bytes)
        try octet.serialize(into: &coder, withIdentifier: identifier)
    }
}

extension ISO_8824.PrintableString: ISO_8825.DER.ImplicitlyTaggable, ISO_8825.BER.ImplicitlyTaggable
{
    @inlinable
    public init(
        derEncoded node: ISO_8825.Node,
        withIdentifier identifier: ISO_8824.Identifier
    ) throws(ISO_8824.Error) {

        self = try Self(
            contentBytes: ISO_8824.OctetString(derEncoded: node, withIdentifier: identifier).bytes
        )
    }

    @inlinable
    public init(
        berEncoded node: ISO_8825.Node,
        withIdentifier identifier: ISO_8824.Identifier
    ) throws(ISO_8824.Error) {
        self = try Self(
            contentBytes: ISO_8824.OctetString(berEncoded: node, withIdentifier: identifier).bytes
        )
    }

    @inlinable
    public func serialize(
        into coder: inout ISO_8825.DER.Serializer,
        withIdentifier identifier: ISO_8824.Identifier
    ) throws(ISO_8824.Error) {
        let octet = ISO_8824.OctetString(contentBytes: self.bytes)
        try octet.serialize(into: &coder, withIdentifier: identifier)
    }
}

extension ISO_8824.VisibleString: ISO_8825.DER.ImplicitlyTaggable, ISO_8825.BER.ImplicitlyTaggable {
    @inlinable
    public init(
        derEncoded node: ISO_8825.Node,
        withIdentifier identifier: ISO_8824.Identifier
    ) throws(ISO_8824.Error) {
        self = try Self(
            contentBytes: ISO_8824.OctetString(derEncoded: node, withIdentifier: identifier).bytes
        )
    }

    @inlinable
    public init(
        berEncoded node: ISO_8825.Node,
        withIdentifier identifier: ISO_8824.Identifier
    ) throws(ISO_8824.Error) {
        self = try Self(
            contentBytes: ISO_8824.OctetString(berEncoded: node, withIdentifier: identifier).bytes
        )
    }

    @inlinable
    public func serialize(
        into coder: inout ISO_8825.DER.Serializer,
        withIdentifier identifier: ISO_8824.Identifier
    ) throws(ISO_8824.Error) {
        let octet = ISO_8824.OctetString(contentBytes: self.bytes)
        try octet.serialize(into: &coder, withIdentifier: identifier)
    }
}

extension ISO_8824.UniversalString: ISO_8825.DER.ImplicitlyTaggable, ISO_8825.BER.ImplicitlyTaggable
{
    @inlinable
    public init(
        derEncoded node: ISO_8825.Node,
        withIdentifier identifier: ISO_8824.Identifier
    ) throws(ISO_8824.Error) {
        self.init(
            contentBytes: try ISO_8824.OctetString(derEncoded: node, withIdentifier: identifier)
                .bytes
        )
    }

    @inlinable
    public init(
        berEncoded node: ISO_8825.Node,
        withIdentifier identifier: ISO_8824.Identifier
    ) throws(ISO_8824.Error) {
        self.init(
            contentBytes: try ISO_8824.OctetString(berEncoded: node, withIdentifier: identifier)
                .bytes
        )
    }

    @inlinable
    public func serialize(
        into coder: inout ISO_8825.DER.Serializer,
        withIdentifier identifier: ISO_8824.Identifier
    ) throws(ISO_8824.Error) {
        let octet = ISO_8824.OctetString(contentBytes: self.bytes)
        try octet.serialize(into: &coder, withIdentifier: identifier)
    }
}

extension ISO_8824.BMPString: ISO_8825.DER.ImplicitlyTaggable, ISO_8825.BER.ImplicitlyTaggable {
    @inlinable
    public init(
        derEncoded node: ISO_8825.Node,
        withIdentifier identifier: ISO_8824.Identifier
    ) throws(ISO_8824.Error) {
        self.init(
            contentBytes: try ISO_8824.OctetString(derEncoded: node, withIdentifier: identifier)
                .bytes
        )
    }

    @inlinable
    public init(
        berEncoded node: ISO_8825.Node,
        withIdentifier identifier: ISO_8824.Identifier
    ) throws(ISO_8824.Error) {
        self.init(
            contentBytes: try ISO_8824.OctetString(berEncoded: node, withIdentifier: identifier)
                .bytes
        )
    }

    @inlinable
    public func serialize(
        into coder: inout ISO_8825.DER.Serializer,
        withIdentifier identifier: ISO_8824.Identifier
    ) throws(ISO_8824.Error) {
        let octet = ISO_8824.OctetString(contentBytes: self.bytes)
        try octet.serialize(into: &coder, withIdentifier: identifier)
    }
}

extension ISO_8824.IA5String: ISO_8825.DER.ImplicitlyTaggable, ISO_8825.BER.ImplicitlyTaggable {
    @inlinable
    public init(
        derEncoded node: ISO_8825.Node,
        withIdentifier identifier: ISO_8824.Identifier
    ) throws(ISO_8824.Error) {
        self = try Self(
            contentBytes: ISO_8824.OctetString(derEncoded: node, withIdentifier: identifier).bytes
        )
    }

    @inlinable
    public init(
        berEncoded node: ISO_8825.Node,
        withIdentifier identifier: ISO_8824.Identifier
    ) throws(ISO_8824.Error) {
        self = try Self(
            contentBytes: ISO_8824.OctetString(berEncoded: node, withIdentifier: identifier).bytes
        )
    }

    @inlinable
    public func serialize(
        into coder: inout ISO_8825.DER.Serializer,
        withIdentifier identifier: ISO_8824.Identifier
    ) throws(ISO_8824.Error) {
        let octet = ISO_8824.OctetString(contentBytes: self.bytes)
        try octet.serialize(into: &coder, withIdentifier: identifier)
    }
}
