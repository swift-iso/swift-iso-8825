public import ISO_8824

extension ISO.`8824`.UTCTime: ISO.`8825`.DER.ImplicitlyTaggable, ISO.`8825`.BER.ImplicitlyTaggable {
    @inlinable
    public init(
        derEncoded node: ISO.`8825`.Node,
        withIdentifier identifier: ISO.`8824`.Identifier
    ) throws(ISO.`8824`.Error) {
        let content = try ISO.`8824`.OctetString(derEncoded: node, withIdentifier: identifier).bytes
        self = try ISO.`8825`.Time.utcTimeFromBytes(content)
    }

    @inlinable
    public init(
        berEncoded node: ISO.`8825`.Node,
        withIdentifier identifier: ISO.`8824`.Identifier
    ) throws(ISO.`8824`.Error) {
        let content = try ISO.`8824`.OctetString(berEncoded: node, withIdentifier: identifier).bytes
        self = try ISO.`8825`.Time.utcTimeFromBytes(content)
    }

    @inlinable
    public func serialize(
        into coder: inout ISO.`8825`.DER.Serializer,
        withIdentifier identifier: ISO.`8824`.Identifier
    ) throws(ISO.`8824`.Error) {
        coder.appendPrimitiveNode(identifier: identifier) { bytes in
            bytes.append(self)
        }
    }
}
