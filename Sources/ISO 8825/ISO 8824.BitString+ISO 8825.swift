public import ISO_8824

extension ISO_8824.BitString: ISO_8825.DER.ImplicitlyTaggable, ISO_8825.BER.ImplicitlyTaggable {
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
                reason: "BitString encoded with constructed encoding"
            )
        }

        guard let paddingBits = content.first, (0..<8).contains(paddingBits) else {
            throw ISO_8824.Error.invalidASN1Object(
                reason: "Unable to determine a valid number of padding bits for BitString"
            )
        }

        let bytes = content.dropFirst()

        if let finalByte = bytes.last {

            let mask = ~(UInt8.max << paddingBits)
            if (finalByte & mask) != 0 {
                throw ISO_8824.Error.invalidASN1Object(
                    reason:
                        "Invalid padding bits in BitString: \(paddingBits) of padding, \(finalByte) final byte"
                )
            }
        } else if paddingBits != 0 {

            throw ISO_8824.Error.invalidASN1Object(
                reason: "Invalid number of padding bits for BitString: \(paddingBits)"
            )
        }

        try self.init(bytes: bytes, paddingBits: Int(paddingBits))
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
        case .constructed:

            throw ISO_8824.Error.invalidASN1Object(
                reason: "Constructed encoding of BitString not yet supported"
            )

        case .primitive:
            self = try Self(derEncoded: node, withIdentifier: identifier)
        }
    }

    @inlinable
    public func serialize(
        into coder: inout ISO_8825.DER.Serializer,
        withIdentifier identifier: ISO_8824.Identifier
    ) throws(ISO_8824.Error) {
        coder.appendPrimitiveNode(identifier: identifier) { bytes in
            bytes.append(UInt8(truncatingIfNeeded: self.paddingBits))
            bytes.append(contentsOf: self.bytes)
        }
    }
}
