public import ISO_8824

extension ISO.`8824`.ObjectIdentifier: ISO.`8825`.DER.ImplicitlyTaggable, ISO.`8825`.BER
        .ImplicitlyTaggable
{
    @inlinable
    public init(
        derEncoded node: ISO.`8825`.Node,
        withIdentifier identifier: ISO.`8824`.Identifier
    ) throws(ISO.`8824`.Error) {
        guard node.identifier == identifier else {
            throw ISO.`8824`.Error.unexpectedFieldType(node.identifier)
        }

        guard case .primitive(let content) = node.content else {
            throw ISO.`8824`.Error.invalidASN1Object(reason: "OID encoded with constructed encoding")
        }

        try Self.validateObjectIdentifierInEncodedForm(content)

        try self.init(encodedForm: content)
    }

    @inlinable
    public init(
        berEncoded node: ISO.`8825`.Node,
        withIdentifier identiifer: ISO.`8824`.Identifier
    ) throws(ISO.`8824`.Error) {
        self = try .init(derEncoded: node, withIdentifier: identiifer)
    }

    @inlinable
    public func serialize(
        into coder: inout ISO.`8825`.DER.Serializer,
        withIdentifier identifier: ISO.`8824`.Identifier
    ) throws(ISO.`8824`.Error) {
        coder.appendPrimitiveNode(identifier: identifier) { bytes in
            bytes.append(contentsOf: self.bytes)
        }
    }

    @inlinable
    package static func validateObjectIdentifierInEncodedForm(
        _ content: ArraySlice<UInt8>
    ) throws(ISO.`8824`.Error) {
        var content = content

        guard content.count >= 1 else {
            throw ISO.`8824`.Error.invalidASN1Object(reason: "Zero components in OID")
        }

        while content.count > 0 {
            _ = try content.readUIntUsing8BitBytesASN1Discipline()
        }
    }
}
