public import ISO_8824

extension ISO_8825 {

    public enum Integer {}
}

@available(*, unavailable)
extension ISO_8825.Integer: Sendable {}

extension ISO_8825.Integer {

    public protocol Representable: ISO_8824.Integer.Representable, ISO_8825.DER.ImplicitlyTaggable,
        ISO_8825.BER.ImplicitlyTaggable
    {

        init(derIntegerBytes: ArraySlice<UInt8>) throws(ISO_8824.Error)

        init(berIntegerBytes: ArraySlice<UInt8>) throws(ISO_8824.Error)
    }
}

extension ISO_8825.Integer.Representable {
    @inlinable
    public static var defaultIdentifier: ISO_8824.Identifier {
        .integer
    }

    @inlinable
    public init(
        derEncoded node: ISO_8825.Node,
        withIdentifier identifier: ISO_8824.Identifier
    ) throws(ISO_8824.Error) {
        guard node.identifier == identifier else {
            throw ISO_8824.Error.unexpectedFieldType(node.identifier)
        }

        guard case .primitive(var dataBytes) = node.content else {
            throw ISO_8824.Error.invalidASN1Object(
                reason: "INTEGER encoded with constructed encoding"
            )
        }

        guard dataBytes.count > 0 else {
            throw ISO_8824.Error.invalidASN1IntegerEncoding(
                reason: "INTEGER encoded with zero bytes"
            )
        }

        if let first = dataBytes.first, let second = dataBytes.dropFirst().first {
            if (first == 0xFF) && second._topBitSet || (first == 0x00) && !second._topBitSet {
                throw ISO_8824.Error.invalidASN1IntegerEncoding(
                    reason: "INTEGER not encoded in fewest number of octets"
                )
            }
        }

        if !Self.isSigned, let first = dataBytes.first {
            if first == 0x00 {
                dataBytes = dataBytes.dropFirst()
            } else if first & 0x80 == 0x80 {
                throw ISO_8824.Error.invalidASN1IntegerEncoding(
                    reason: "INTEGER encoded with top bit set!"
                )
            }
        }

        self = try Self(derIntegerBytes: dataBytes)
    }

    @inlinable
    public init(
        berEncoded node: ISO_8825.Node,
        withIdentifier identifier: ISO_8824.Identifier
    ) throws(ISO_8824.Error) {
        guard node.identifier == identifier else {
            throw ISO_8824.Error.unexpectedFieldType(node.identifier)
        }

        guard case .primitive(var dataBytes) = node.content else {
            throw ISO_8824.Error.invalidASN1Object(
                reason: "INTEGER encoded with constructed encoding"
            )
        }

        guard dataBytes.count > 0 else {
            throw ISO_8824.Error.invalidASN1IntegerEncoding(
                reason: "INTEGER encoded with zero bytes"
            )
        }

        if !Self.isSigned, let first = dataBytes.first {
            if first == 0x00 {
                dataBytes = dataBytes.dropFirst()
            } else if first & 0x80 == 0x80 {
                throw ISO_8824.Error.invalidASN1IntegerEncoding(
                    reason: "INTEGER encoded with top bit set!"
                )
            }
        }

        self = try Self(berIntegerBytes: dataBytes)
    }

    @inlinable
    public func serialize(
        into coder: inout ISO_8825.DER.Serializer,
        withIdentifier identifier: ISO_8824.Identifier
    ) throws(ISO_8824.Error) {
        coder.appendPrimitiveNode(identifier: identifier) { bytes in
            self.withBigEndianIntegerBytes { integerBytes in

                if integerBytes.count == 0 {
                    bytes.append(0)
                    return
                }

                if !Self.isSigned, let topByte = integerBytes.first, topByte._topBitSet {
                    bytes.append(0)
                    bytes.append(contentsOf: integerBytes)
                } else {

                    bytes.append(contentsOf: integerBytes._trimLeadingExcessBytes())
                }
            }
        }
    }
}

extension ISO_8825.Integer.Representable where Self: FixedWidthInteger {
    @inlinable
    public init(derIntegerBytes bytes: ArraySlice<UInt8>) throws(ISO_8824.Error) {

        self = try Self(bigEndianBytes: bytes)

        if Self.isSigned, let first = bytes.first, first._topBitSet {
            for shift in stride(
                from: self.bitWidth - self.leadingZeroBitCount,
                to: self.bitWidth,
                by: 8
            ) {
                self |= 0xFF << shift
            }
        }
    }

    @inlinable
    public init(berIntegerBytes bytes: ArraySlice<UInt8>) throws(ISO_8824.Error) {
        self = try .init(derIntegerBytes: bytes)
    }

}

extension Int8: ISO_8825.Integer.Representable {}

extension UInt8: ISO_8825.Integer.Representable {}

extension Int16: ISO_8825.Integer.Representable {}

extension UInt16: ISO_8825.Integer.Representable {}

extension Int32: ISO_8825.Integer.Representable {}

extension UInt32: ISO_8825.Integer.Representable {}

extension Int64: ISO_8825.Integer.Representable {}

extension UInt64: ISO_8825.Integer.Representable {}

extension Int: ISO_8825.Integer.Representable {}

extension UInt: ISO_8825.Integer.Representable {}

extension RandomAccessCollection where Element == UInt8 {
    @inlinable
    package func _trimLeadingExcessBytes() -> SubSequence {
        var slice = self[...]
        guard let first = slice.first else {

            return slice
        }

        let wholeByte: UInt8

        switch first {
        case 0:
            wholeByte = 0

        case 0xFF:
            wholeByte = 0xFF

        default:

            return slice
        }

        while slice.count > 1 {

            if slice.first != wholeByte {
                break
            }

            guard let second = slice.dropFirst().first else {
                preconditionFailure("Loop condition violated: must be at least two bytes left")
            }

            if second & 0x80 != wholeByte & 0x80 {

                break
            }

            slice = slice.dropFirst()
        }

        return slice
    }
}

extension UInt8 {
    @inlinable
    package var _topBitSet: Bool {
        return (self & 0x80) != 0
    }
}
