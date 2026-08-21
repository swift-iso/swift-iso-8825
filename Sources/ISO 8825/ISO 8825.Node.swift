public import ISO_8824

extension ISO_8825 {
    @usableFromInline
    enum EncodingRules: Sendable {
        case basic

        case distinguished
    }
}

extension ISO_8825.EncodingRules {
    @inlinable
    var indefiniteLengthAllowed: Bool { self == .basic }

    @inlinable
    var nonMinimalEncodedLengthsAllowed: Bool { self == .basic }

    @inlinable
    var constructedBitStringAllowed: Bool { self == .basic }

    @inlinable
    var relaxedTimestampsAllowed: Bool { self == .basic }

    @inlinable
    var defaultEncodableSequenceAllowed: Bool { self == .basic }

    @inlinable
    var defaultEncodableSETAllowed: Bool { self == .basic }

    @inlinable
    var unsortedSETAllowed: Bool { self == .basic }

    @inlinable
    var unsortedSETOFAllowed: Bool { self == .basic }
}

extension ISO_8825 {

    @usableFromInline
    struct TLV {

        @usableFromInline
        var identifier: ISO_8824.Identifier

        @usableFromInline
        var depth: Int

        @usableFromInline
        var isConstructed: Bool

        @usableFromInline
        var encodedBytes: ArraySlice<UInt8>

        @usableFromInline
        var dataBytes: ArraySlice<UInt8>?

        @inlinable
        init(
            identifier: ISO_8824.Identifier,
            depth: Int,
            isConstructed: Bool,
            encodedBytes: ArraySlice<UInt8>,
            dataBytes: ArraySlice<UInt8>? = nil
        ) {
            self.identifier = identifier
            self.depth = depth
            self.isConstructed = isConstructed
            self.encodedBytes = encodedBytes
            self.dataBytes = dataBytes
        }
    }
}

extension ISO_8825.TLV: Hashable {}

extension ISO_8825.TLV: Sendable {}

extension ISO_8825.TLV: CustomStringConvertible {
    @inlinable
    var description: String {
        return
            "ISO_8825.TLV(identifier: \(self.identifier), depth: \(self.depth), dataBytes: \(self.dataBytes?.count ?? 0))"
    }
}

extension ISO_8825.TLV {
    @inlinable
    var isEndMarker: Bool {
        self.identifier.tagClass == .universal
            && self.identifier.tagNumber == 0
            && self.isConstructed == false
            && self.encodedBytes.elementsEqual([0x00, 0x00])
    }
}

extension ISO_8825.TLV {
    @usableFromInline
    struct Parser: Sendable {
        @inlinable
        static var _maximumNodeDepth: Int { 50 }

        @usableFromInline
        var nodes: ArraySlice<ISO_8825.TLV>

        @inlinable
        init(_ nodes: ArraySlice<ISO_8825.TLV>) {
            self.nodes = nodes
        }

        @inlinable
        static func parse(
            _ data: ArraySlice<UInt8>,
            encoding rules: ISO_8825.EncodingRules
        ) throws(ISO_8824.Error) -> Parser {
            var data = data
            var nodes = [ISO_8825.TLV]()
            nodes.reserveCapacity(16)
            try _parseNode(from: &data, encoding: rules, depth: 1, into: &nodes)
            guard data.count == 0 else {
                throw ISO_8824.Error.invalidASN1Object(reason: "Trailing unparsed data is present")
            }
            return Parser(nodes[...])
        }

        @inlinable
        static func _parseNode(
            from data: inout ArraySlice<UInt8>,
            encoding rules: ISO_8825.EncodingRules,
            depth: Int,
            into nodes: inout [ISO_8825.TLV]
        ) throws(ISO_8824.Error) {
            guard depth <= Parser._maximumNodeDepth else {
                throw ISO_8824.Error.invalidASN1Object(reason: "Excessive stack depth was reached")
            }

            let originalData = data

            guard let rawIdentifier = data.popFirst() else {
                throw ISO_8824.Error.truncatedASN1Field()
            }

            let constructed = (rawIdentifier & 0x20) != 0
            let identifier: ISO_8824.Identifier
            if (rawIdentifier & 0x1f) == 0x1f {
                let tagClass = ISO_8824.Identifier.Class(topByteInWireFormat: rawIdentifier)

                let tagNumber = try data.readUIntUsing8BitBytesASN1Discipline()

                guard tagNumber >= 0x1f else {
                    throw ISO_8824.Error.invalidASN1Object(
                        reason: "ASN.1 tag incorrectly encoded in long form: \(tagNumber)"
                    )
                }
                identifier = ISO_8824.Identifier(tagWithNumber: tagNumber, tagClass: tagClass)
            } else {
                identifier = ISO_8824.Identifier(shortIdentifier: rawIdentifier)
            }

            guard let wideLength = try data._readLength(!rules.nonMinimalEncodedLengthsAllowed)
            else {
                throw ISO_8824.Error.truncatedASN1Field()
            }

            switch wideLength {
            case .definite(let wideLength):
                guard let length = Int(exactly: wideLength) else {
                    throw ISO_8824.Error.invalidASN1Object(
                        reason: "Excessively large field: \(wideLength)"
                    )
                }

                var subData = data.prefix(length)
                data = data.dropFirst(length)

                guard subData.count == length else {
                    throw ISO_8824.Error.truncatedASN1Field()
                }

                let encodedBytes = originalData[..<subData.endIndex]

                if constructed {
                    nodes.append(
                        ISO_8825.TLV(
                            identifier: identifier,
                            depth: depth,
                            isConstructed: true,
                            encodedBytes: encodedBytes
                        )
                    )
                    while subData.count > 0 {
                        try _parseNode(
                            from: &subData,
                            encoding: rules,
                            depth: depth + 1,
                            into: &nodes
                        )
                    }
                } else {
                    nodes.append(
                        ISO_8825.TLV(
                            identifier: identifier,
                            depth: depth,
                            isConstructed: false,
                            encodedBytes: encodedBytes,
                            dataBytes: subData
                        )
                    )
                }

            case .indefinite:
                guard rules.indefiniteLengthAllowed == true else {

                    throw ISO_8824.Error.unsupportedFieldLength(
                        reason: "Indefinite form of field length not supported in DER."
                    )
                }

                guard constructed == true else {
                    throw ISO_8824.Error.unsupportedFieldLength(
                        reason: "Indefinite-length field must have constructed identifier"
                    )
                }

                nodes.append(
                    ISO_8825.TLV(
                        identifier: identifier,
                        depth: depth,
                        isConstructed: true,
                        encodedBytes: []
                    )
                )
                let lastIndex = nodes.endIndex - 1
                repeat {
                    try _parseNode(from: &data, encoding: rules, depth: depth + 1, into: &nodes)
                } while data.count > 0 && nodes.last!.isEndMarker == false
                let endMarker = nodes.popLast()!
                let encodedBytes = originalData[..<endMarker.encodedBytes.endIndex]
                nodes[lastIndex].encodedBytes = encodedBytes
            }
        }
    }
}

extension ISO_8825.TLV.Parser: Hashable {}

extension ISO_8825 {

    public struct LazySetOfSequence<T>: Sequence {
        public typealias Element = Result<T, ISO_8824.Error>

        @usableFromInline
        package typealias Wrapped = LazyMapSequence<
            LazySequence<(ISO_8825.Node.Collection)>.Elements, Result<T, ISO_8824.Error>
        >

        public struct Iterator: IteratorProtocol {
            @usableFromInline
            var wrapped: Wrapped.Iterator

            @inlinable
            public mutating func next() -> Element? {
                wrapped.next()
            }

            @inlinable
            package init(_ wrapped: Wrapped.Iterator) {
                self.wrapped = wrapped
            }
        }

        @usableFromInline
        var wrapped: Wrapped

        @inlinable
        package init(_ wrapped: Wrapped) {
            self.wrapped = wrapped
        }

        @inlinable
        public func makeIterator() -> Iterator {
            .init(wrapped.makeIterator())
        }
    }
}

@available(*, unavailable)
extension ISO_8825.LazySetOfSequence: Sendable {}

@available(*, unavailable)
extension ISO_8825.LazySetOfSequence.Iterator: Sendable {}

extension ISO_8825.Node {
    public struct Collection {
        @usableFromInline var _nodes: ArraySlice<ISO_8825.TLV>

        @usableFromInline var _depth: Int

        @inlinable

        init(nodes: ArraySlice<ISO_8825.TLV>, depth: Int) {
            self._nodes = nodes
            self._depth = depth

            precondition(self._nodes.allSatisfy({ $0.depth > depth }))
            if let firstDepth = self._nodes.first?.depth {
                precondition(firstDepth == depth + 1)
            }
        }
    }
}

extension ISO_8825.Node.Collection: Hashable {}

extension ISO_8825.Node.Collection: Sendable {}

extension ISO_8825.Node.Collection: Sequence {

    public struct Iterator: IteratorProtocol, Sendable {
        @usableFromInline
        var _nodes: ArraySlice<ISO_8825.TLV>

        @usableFromInline
        var _depth: Int

        @inlinable

        init(nodes: ArraySlice<ISO_8825.TLV>, depth: Int) {
            self._nodes = nodes
            self._depth = depth
        }

        @inlinable
        public mutating func next() -> ISO_8825.Node? {
            guard let nextNode = self._nodes.popFirst() else {
                return nil
            }

            assert(nextNode.depth == self._depth + 1)
            guard nextNode.isConstructed else {

                return ISO_8825.Node(
                    identifier: nextNode.identifier,
                    content: .primitive(nextNode.dataBytes!),
                    encodedBytes: nextNode.encodedBytes
                )
            }

            let nodeCollection = self._nodes.prefix { $0.depth > nextNode.depth }
            self._nodes = self._nodes.dropFirst(nodeCollection.count)
            return ISO_8825.Node(
                identifier: nextNode.identifier,
                content: .constructed(.init(nodes: nodeCollection, depth: nextNode.depth)),
                encodedBytes: nextNode.encodedBytes
            )
        }
    }

    @inlinable
    public func makeIterator() -> Iterator {
        return Iterator(nodes: self._nodes, depth: self._depth)
    }
}

extension ISO_8825 {
    public struct Node: Hashable, Sendable {

        public var identifier: ISO_8824.Identifier

        public var content: Content

        public var encodedBytes: ArraySlice<UInt8>

        @inlinable
        package init(
            identifier: ISO_8824.Identifier,
            content: ISO_8825.Node.Content,
            encodedBytes: ArraySlice<UInt8>
        ) {
            self.identifier = identifier
            self.content = content
            self.encodedBytes = encodedBytes
        }
    }
}

extension ISO_8825.Node {

    public enum Content: Hashable, Sendable {

        case constructed(ISO_8825.Node.Collection)

        case primitive(ArraySlice<UInt8>)
    }
}

extension ArraySlice where Element == UInt8 {
    @usableFromInline
    package enum Length: Sendable {
        case indefinite
        case definite(_: UInt)
    }

    @inlinable
    package mutating func _readLength(_ minimalEncoding: Bool) throws(ISO_8824.Error) -> Length? {
        guard let firstByte = self.popFirst() else {
            return nil
        }

        switch firstByte {
        case 0x80:
            return .indefinite

        case let val where val & 0x80 == 0x80:

            let fieldLength = Int(val & 0x7F)
            guard self.count >= fieldLength else {
                return nil
            }

            let lengthBytes = self.prefix(fieldLength)
            self = self.dropFirst(fieldLength)
            let length = try UInt(bigEndianBytes: lengthBytes)

            if minimalEncoding {

                let requiredBits = UInt.bitWidth - length.leadingZeroBitCount
                switch requiredBits {
                case 0...7:

                    throw ISO_8824.Error.unsupportedFieldLength(
                        reason:
                            "Field length encoded in long form, but DER requires \(length) to be encoded in short form"
                    )

                case 8...:

                    let requiredBytes = (requiredBits + 7) / 8
                    if fieldLength > requiredBytes {
                        throw ISO_8824.Error.unsupportedFieldLength(
                            reason: "Field length encoded in excessive number of bytes"
                        )
                    }

                default:

                    throw ISO_8824.Error.unsupportedFieldLength(
                        reason: "Correctness error: computed required bits as \(requiredBits)"
                    )
                }
            }

            return .definite(length)

        case let val:

            return .definite(UInt(val))
        }
    }
}

extension FixedWidthInteger {
    @inlinable
    package init<Bytes: Collection>(bigEndianBytes bytes: Bytes) throws(ISO_8824.Error)
    where Bytes.Element == UInt8 {
        guard bytes.count <= (Self.bitWidth / 8) else {
            throw ISO_8824.Error.invalidASN1Object(
                reason: "Unable to treat \(bytes.count) bytes as a \(Self.self)"
            )
        }

        self = 0

        var shift = (bytes.count &* 8) &- 8

        var index = bytes.startIndex
        while shift >= 0 {
            self |= Self(truncatingIfNeeded: bytes[index]) << shift
            bytes.formIndex(after: &index)
            shift &-= 8
        }
    }
}

extension Array where Element == UInt8 {
    @inlinable
    package mutating func _moveRange(offset: Int, range: Range<Index>) {

        precondition(offset > 0)

        let distanceFromEndOfRangeToEndOfSelf = self.distance(
            from: range.endIndex,
            to: self.endIndex
        )
        if distanceFromEndOfRangeToEndOfSelf < offset {

            for _ in 0..<(offset - distanceFromEndOfRangeToEndOfSelf) {
                self.append(0)
            }
        }

        for index in range.reversed() {
            self[index + offset] = self[index]
        }
    }
}

extension Int {
    @inlinable
    package var _bytesNeededToEncode: Int {

        guard self <= 0x7F else {

            return UInt(self).neededBytes &+ 1
        }
        return 1
    }
}

extension FixedWidthInteger {

    @inlinable
    package var neededBytes: Int {
        let neededBits = self.bitWidth - self.leadingZeroBitCount
        return (neededBits + 7) / 8
    }
}

extension ISO_8825.Node.Collection {
    @inlinable
    package func isOrderedAccordingToSetOfSemantics() -> Bool {
        var iterator = self.makeIterator()
        guard let first = iterator.next() else {
            return true
        }

        var previousElement = first
        while let nextElement = iterator.next() {
            guard
                asn1SetElementLessThanOrEqual(
                    previousElement.encodedBytes,
                    nextElement.encodedBytes
                )
            else {
                return false
            }
            previousElement = nextElement
        }

        return true
    }
}

@inlinable
package func asn1SetElementLessThan(_ lhs: ArraySlice<UInt8>, _ rhs: ArraySlice<UInt8>) -> Bool {
    for (leftByte, rightByte) in zip(lhs, rhs) {
        if leftByte < rightByte {

            return true
        } else if rightByte < leftByte {

            return false
        }
    }

    let trailing = rhs.dropFirst(lhs.count)
    if trailing.allSatisfy({ $0 == 0 }) {

        return false
    }
    return true
}

@inlinable
package func asn1SetElementLessThanOrEqual(
    _ lhs: ArraySlice<UInt8>,
    _ rhs: ArraySlice<UInt8>
) -> Bool {

    !asn1SetElementLessThan(rhs, lhs)
}
