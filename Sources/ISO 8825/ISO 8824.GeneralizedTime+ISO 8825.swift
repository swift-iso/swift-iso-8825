public import ISO_8824

extension ISO_8824.GeneralizedTime: ISO_8825.DER.ImplicitlyTaggable, ISO_8825.BER.ImplicitlyTaggable
{
    @inlinable
    public init(
        derEncoded node: ISO_8825.Node,
        withIdentifier identifier: ISO_8824.Identifier
    ) throws(ISO_8824.Error) {
        let content = try ISO_8824.OctetString(derEncoded: node, withIdentifier: identifier).bytes
        self = try ISO_8825.Time.generalizedTimeFromBytes(content)
    }

    @inlinable
    public init(
        berEncoded node: ISO_8825.Node,
        withIdentifier identifier: ISO_8824.Identifier
    ) throws(ISO_8824.Error) {

        let content = try ISO_8824.OctetString(berEncoded: node, withIdentifier: identifier).bytes
        self = try ISO_8825.Time.generalizedTimeFromBytes(content)
    }

    @inlinable
    public func serialize(
        into coder: inout ISO_8825.DER.Serializer,
        withIdentifier identifier: ISO_8824.Identifier
    ) throws(ISO_8824.Error) {
        coder.appendPrimitiveNode(identifier: identifier) { bytes in
            bytes.append(self)
        }
    }
}
