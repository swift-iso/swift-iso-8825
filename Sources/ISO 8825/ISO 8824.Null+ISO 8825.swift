public import ISO_8824

extension ISO_8824.Null: ISO_8825.DER.ImplicitlyTaggable, ISO_8825.BER.ImplicitlyTaggable {
    @inlinable
    public init(
        derEncoded node: ISO_8825.Node,
        withIdentifier identifier: ISO_8824.Identifier
    ) throws(ISO_8824.Error) {
        guard node.identifier == identifier, case .primitive(let content) = node.content else {
            throw ISO_8824.Error.unexpectedFieldType(node.identifier)
        }

        guard content.count == 0 else {
            throw ISO_8824.Error.invalidASN1Object(
                reason: "Null must be empty, received \(content.count) bytes"
            )
        }

        self.init()
    }

    @inlinable
    public init(
        berEncoded node: ISO_8825.Node,
        withIdentifier identifier: ISO_8824.Identifier
    ) throws(ISO_8824.Error) {
        self = try .init(derEncoded: node, withIdentifier: identifier)
    }

    @inlinable
    public func serialize(
        into coder: inout ISO_8825.DER.Serializer,
        withIdentifier identifier: ISO_8824.Identifier
    ) {
        coder.appendPrimitiveNode(identifier: identifier, { _ in })
    }
}
