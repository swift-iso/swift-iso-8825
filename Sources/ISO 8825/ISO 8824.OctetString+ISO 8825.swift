public import ISO_8824

extension ISO_8824.OctetString: ISO_8825.DER.ImplicitlyTaggable, ISO_8825.BER.ImplicitlyTaggable {
    @inlinable
    public init(
        derEncoded node: ISO_8825.Node,
        withIdentifier identifier: ISO_8824.Identifier
    ) throws(ISO_8824.Error) {
        guard node.identifier == identifier else {
            throw ISO_8824.Error.unexpectedFieldType(node.identifier)
        }

        guard case .primitive(let content) = node.content else {
            throw ISO_8824.Error.invalidASN1Object(
                reason: "OctetString encoded with constructed encoding"
            )
        }

        self.init(contentBytes: content)
    }

    @inlinable
    public init(
        berEncoded node: ISO_8825.Node,
        withIdentifier identifier: ISO_8824.Identifier
    ) throws(ISO_8824.Error) {
        guard node.identifier == identifier else {
            throw ISO_8824.Error.unexpectedFieldType(node.identifier)
        }

        switch node.content {
        case .constructed(let nodes):

            let (count, maxLength) = nodes.reduce((0, 0)) { acc, elem in
                let (countAcc, lenAcc) = acc
                return (countAcc + 1, lenAcc + elem.encodedBytes.count)
            }

            if count == 0 {
                self.init(contentBytes: [])
                return
            }

            if count == 1 {

                for node in nodes {
                    let substring = try ISO_8824.OctetString(berEncoded: node)
                    self.init(contentBytes: substring.bytes)
                    return
                }
            }

            var flattened: [UInt8] = []

            flattened.reserveCapacity(maxLength)
            for node in nodes {
                let substring = try ISO_8824.OctetString(berEncoded: node)
                flattened += substring.bytes
            }

            self.init(contentBytes: flattened[...])

        case .primitive(let content):
            self.init(contentBytes: content)
        }
    }

    @inlinable
    public func serialize(
        into coder: inout ISO_8825.DER.Serializer,
        withIdentifier identifier: ISO_8824.Identifier
    ) throws(ISO_8824.Error) {
        coder.appendPrimitiveNode(identifier: identifier) { bytes in
            bytes.append(contentsOf: self.bytes)
        }
    }
}
