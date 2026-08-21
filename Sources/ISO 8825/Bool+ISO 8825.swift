public import ISO_8824

extension Bool: ISO_8825.DER.ImplicitlyTaggable, ISO_8825.BER.ImplicitlyTaggable {
    @inlinable
    public static var defaultIdentifier: ISO_8824.Identifier {
        .boolean
    }

    @inlinable
    public init(
        derEncoded node: ISO_8825.Node,
        withIdentifier identifier: ISO_8824.Identifier
    ) throws(ISO_8824.Error) {
        guard node.identifier == identifier else {
            throw ISO_8824.Error.unexpectedFieldType(node.identifier)
        }

        guard case .primitive(let bytes) = node.content, bytes.count == 1 else {
            throw ISO_8824.Error.invalidASN1Object(reason: "Invalid content for ASN1Bool")
        }

        switch bytes[bytes.startIndex] {
        case 0:

            self = false

        case 0xff:

            self = true

        case let byte:

            throw ISO_8824.Error.invalidASN1Object(reason: "Invalid byte for ASN1Bool: \(byte)")
        }
    }

    @inlinable
    public init(
        berEncoded node: ISO_8825.Node,
        withIdentifier identifier: ISO_8824.Identifier
    ) throws(ISO_8824.Error) {
        guard node.identifier == identifier else {
            throw ISO_8824.Error.unexpectedFieldType(node.identifier)
        }

        guard case .primitive(let bytes) = node.content, bytes.count == 1 else {
            throw ISO_8824.Error.invalidASN1Object(reason: "Invalid content for ASN1Bool")
        }

        switch bytes[bytes.startIndex] {
        case 0:

            self = false

        default:

            self = true
        }
    }

    @inlinable
    public func serialize(
        into coder: inout ISO_8825.DER.Serializer,
        withIdentifier identifier: ISO_8824.Identifier
    ) throws(ISO_8824.Error) {
        coder.appendPrimitiveNode(identifier: identifier) { bytes in
            if self {
                bytes.append(0xff)
            } else {
                bytes.append(0)
            }
        }
    }
}
