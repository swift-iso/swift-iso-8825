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
}

extension ISO_8825.TLV.Parser: Hashable {}

extension ISO_8825 {
}

@available(*, unavailable)
extension ISO_8825.LazySetOfSequence: Sendable {}

@available(*, unavailable)
extension ISO_8825.LazySetOfSequence.Iterator: Sendable {}

extension ISO_8825.Node {
}

extension ISO_8825.Node.Collection: Hashable {}

extension ISO_8825.Node.Collection: Sendable {}

extension ISO_8825.Node.Collection: Swift.Sequence {


    @inlinable
    public func makeIterator() -> Iterator {
        return Iterator(nodes: self._nodes, depth: self._depth)
    }
}

extension ISO_8825 {
}

extension ISO_8825.Node {
}

extension ArraySlice where Element == UInt8 {


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
