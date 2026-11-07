public import ISO_8824


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
                } while data.count > 0 && nodes.last?.isEndMarker == false
                guard let endMarker = nodes.popLast() else {
                    preconditionFailure("Parsing a constructed indefinite-length TLV always appends nodes")
                }
                let encodedBytes = originalData[..<endMarker.encodedBytes.endIndex]
                nodes[lastIndex].encodedBytes = encodedBytes
            }
        }
    }
}
