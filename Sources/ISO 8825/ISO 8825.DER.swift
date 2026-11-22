public import ISO_8824

extension ISO.`8825` {

    public enum DER {}
}

@available(*, unavailable)
extension ISO.`8825`.DER: Sendable {}

extension ISO.`8825`.DER {

    @inlinable
    public static func sequence<T>(
        _ node: ISO.`8825`.Node,
        identifier: ISO.`8824`.Identifier,
        _ builder: (inout ISO.`8825`.Node.Collection.Iterator) throws(ISO.`8824`.Error) -> T
    ) throws(ISO.`8824`.Error) -> T {
        guard node.identifier == identifier, case .constructed(let nodes) = node.content else {
            throw ISO.`8824`.Error.unexpectedFieldType(node.identifier)
        }

        var iterator = nodes.makeIterator()

        let result = try builder(&iterator)

        guard iterator.next() == nil else {
            throw ISO.`8824`.Error.invalidASN1Object(reason: "Unconsumed sequence nodes")
        }

        return result
    }

    @inlinable
    public static func sequence<T: ISO.`8825`.DER.Parseable>(
        of: T.Type = T.self,
        identifier: ISO.`8824`.Identifier,
        rootNode: ISO.`8825`.Node
    ) throws(ISO.`8824`.Error) -> [T] {
        guard rootNode.identifier == identifier, case .constructed(let nodes) = rootNode.content
        else {
            throw ISO.`8824`.Error.unexpectedFieldType(rootNode.identifier)
        }

        return try nodes.map { (node: ISO.`8825`.Node) throws(ISO.`8824`.Error) -> T in
            try T(derEncoded: node)
        }
    }

    @inlinable
    public static func sequence<T: ISO.`8825`.DER.Parseable>(
        of: T.Type = T.self,
        identifier: ISO.`8824`.Identifier,
        nodes: inout ISO.`8825`.Node.Collection.Iterator
    ) throws(ISO.`8824`.Error) -> [T] {
        guard let node = nodes.next() else {

            throw ISO.`8824`.Error.invalidASN1Object(
                reason: "No sequence node available for \(T.self) and identifier \(identifier)"
            )
        }

        return try sequence(of: T.self, identifier: identifier, rootNode: node)
    }

    @inlinable
    public static func set<T>(
        _ node: ISO.`8825`.Node,
        identifier: ISO.`8824`.Identifier,
        _ builder: (inout ISO.`8825`.Node.Collection.Iterator) throws(ISO.`8824`.Error) -> T
    ) throws(ISO.`8824`.Error) -> T {
        guard node.identifier == identifier, case .constructed(let nodes) = node.content else {
            throw ISO.`8824`.Error.unexpectedFieldType(node.identifier)
        }

        guard nodes.isOrderedAccordingToSetSemantics() else {
            throw ISO.`8824`.Error.invalidASN1Object(
                reason: "SET fields are not in canonical tag order"
            )
        }

        return try sequence(node, identifier: identifier, builder)
    }

    @inlinable
    public static func set<T: ISO.`8825`.DER.Parseable>(
        of: T.Type = T.self,
        identifier: ISO.`8824`.Identifier,
        nodes: inout ISO.`8825`.Node.Collection.Iterator
    ) throws(ISO.`8824`.Error) -> [T] {
        guard let node = nodes.next() else {

            throw ISO.`8824`.Error.invalidASN1Object(
                reason: "No set node available for \(T.self) and identifier \(identifier)"
            )
        }

        return try Self.set(of: T.self, identifier: identifier, rootNode: node)
    }

    @inlinable
    public static func set<T: ISO.`8825`.DER.Parseable>(
        of type: T.Type = T.self,
        identifier: ISO.`8824`.Identifier,
        rootNode: ISO.`8825`.Node
    ) throws(ISO.`8824`.Error) -> [T] {
        try self.lazySet(of: type, identifier: identifier, rootNode: rootNode)
            .map { (element: Result<T, ISO.`8824`.Error>) throws(ISO.`8824`.Error) -> T in
                try element.get()
            }
    }

    @inlinable
    public static func lazySet<T: ISO.`8825`.DER.Parseable>(
        of: T.Type = T.self,
        identifier: ISO.`8824`.Identifier,
        rootNode: ISO.`8825`.Node
    ) throws(ISO.`8824`.Error) -> ISO.`8825`.DER.LazySetOfSequence<T> {
        guard rootNode.identifier == identifier, case .constructed(let nodes) = rootNode.content
        else {
            throw ISO.`8824`.Error.unexpectedFieldType(rootNode.identifier)
        }

        guard nodes.isOrderedAccordingToSetOfSemantics() else {
            throw ISO.`8824`.Error.invalidASN1Object(
                reason: "SET OF fields are not lexicographically ordered"
            )
        }

        return .init(
            nodes.lazy.map { node in
                Result { () throws(ISO.`8824`.Error) -> T in try T(derEncoded: node) }
            }
        )
    }
}

extension ISO.`8825`.DER {
    public typealias LazySetOfSequence = ISO.`8825`.LazySetOfSequence
}

extension ISO.`8825`.DER {

    @inlinable
    public static func optionalExplicitlyTagged<T>(
        _ nodes: inout ISO.`8825`.Node.Collection.Iterator,
        tagNumber: UInt,
        tagClass: ISO.`8824`.Identifier.Class,
        _ builder: (ISO.`8825`.Node) throws(ISO.`8824`.Error) -> T
    ) throws(ISO.`8824`.Error) -> T? {
        var localNodesCopy = nodes
        guard let node = localNodesCopy.next() else {

            return nil
        }

        let expectedNodeID = ISO.`8824`.Identifier(tagWithNumber: tagNumber, tagClass: tagClass)

        guard node.identifier == expectedNodeID else {

            return nil
        }

        nodes = localNodesCopy

        guard case .constructed(let nodes) = node.content else {
            throw ISO.`8824`.Error.invalidASN1Object(
                reason:
                    "Explicit tags should always be constructed, got \(node.identifier) which is not."
            )
        }

        var nodeIterator = nodes.makeIterator()
        guard let child = nodeIterator.next(), nodeIterator.next() == nil else {
            throw ISO.`8824`.Error.invalidASN1Object(
                reason:
                    "Too many child nodes in optionally tagged node of \(T.self) with identifier \(expectedNodeID)"
            )
        }

        return try builder(child)
    }
}

extension ISO.`8825`.DER {

    @inlinable
    public static func optionalImplicitlyTagged<T: ISO.`8825`.DER.ImplicitlyTaggable>(
        _ nodes: inout ISO.`8825`.Node.Collection.Iterator,
        tag: ISO.`8824`.Identifier = T.defaultIdentifier
    ) throws(ISO.`8824`.Error) -> T? {
        var localNodesCopy = nodes
        guard let node = localNodesCopy.next() else {

            return nil
        }

        guard node.identifier == tag else {

            return nil
        }

        return try T(derEncoded: &nodes, withIdentifier: tag)
    }

    @inlinable
    public static func optionalImplicitlyTagged<Result, E: Swift.Error>(
        _ nodes: inout ISO.`8825`.Node.Collection.Iterator,
        tagNumber: UInt,
        tagClass: ISO.`8824`.Identifier.Class,
        _ builder: (ISO.`8825`.Node) throws(E) -> Result
    ) throws(E) -> Result? {
        var localNodesCopy = nodes
        guard let node = localNodesCopy.next() else {

            return nil
        }

        let expectedNodeID = ISO.`8824`.Identifier(tagWithNumber: tagNumber, tagClass: tagClass)
        guard node.identifier == expectedNodeID else {

            return nil
        }

        nodes = localNodesCopy

        return try builder(node)
    }
}

extension ISO.`8825`.DER {

    @inlinable
    public static func decodeDefault<T: ISO.`8825`.DER.Parseable & Equatable>(
        _ nodes: inout ISO.`8825`.Node.Collection.Iterator,
        identifier: ISO.`8824`.Identifier,
        defaultValue: T,
        _ builder: (ISO.`8825`.Node) throws(ISO.`8824`.Error) -> T
    ) throws(ISO.`8824`.Error) -> T {

        var localNodesCopy = nodes
        guard let node = localNodesCopy.next() else {

            return defaultValue
        }

        guard node.identifier == identifier else {

            return defaultValue
        }

        nodes = localNodesCopy
        let parsed = try builder(node)

        guard parsed != defaultValue else {
            throw ISO.`8824`.Error.invalidASN1Object(
                reason:
                    "DEFAULT for \(T.self) with identifier \(identifier) present in DER but encoded at default value \(defaultValue)"
            )
        }

        return parsed
    }

    @inlinable
    public static func decodeDefault<T: ISO.`8825`.DER.Parseable & Equatable>(
        _ nodes: inout ISO.`8825`.Node.Collection.Iterator,
        identifier: ISO.`8824`.Identifier,
        defaultValue: T
    ) throws(ISO.`8824`.Error) -> T {
        return try Self.decodeDefault(&nodes, identifier: identifier, defaultValue: defaultValue) {
            (node: ISO.`8825`.Node) throws(ISO.`8824`.Error) -> T in
            try T(derEncoded: node)
        }
    }

    @inlinable
    public static func decodeDefault<T: ISO.`8825`.DER.ImplicitlyTaggable & Equatable>(
        _ nodes: inout ISO.`8825`.Node.Collection.Iterator,
        defaultValue: T
    ) throws(ISO.`8824`.Error) -> T {
        return try Self.decodeDefault(
            &nodes,
            identifier: T.defaultIdentifier,
            defaultValue: defaultValue
        )
    }

    @inlinable
    public static func decodeDefaultExplicitlyTagged<T: ISO.`8825`.DER.Parseable & Equatable>(
        _ nodes: inout ISO.`8825`.Node.Collection.Iterator,
        tagNumber: UInt,
        tagClass: ISO.`8824`.Identifier.Class,
        defaultValue: T,
        _ builder: (ISO.`8825`.Node) throws(ISO.`8824`.Error) -> T
    ) throws(ISO.`8824`.Error) -> T {
        guard
            let result = try optionalExplicitlyTagged(
                &nodes,
                tagNumber: tagNumber,
                tagClass: tagClass,
                builder
            )
        else {
            return defaultValue
        }
        guard result != defaultValue else {

            throw ISO.`8824`.Error.invalidASN1Object(
                reason:
                    "DEFAULT for \(T.self) with tag number \(tagNumber) and class \(tagClass) present in DER but encoded at default value \(defaultValue)"
            )
        }

        return result
    }

    @inlinable
    public static func decodeDefaultExplicitlyTagged<T: ISO.`8825`.DER.Parseable & Equatable>(
        _ nodes: inout ISO.`8825`.Node.Collection.Iterator,
        tagNumber: UInt,
        tagClass: ISO.`8824`.Identifier.Class,
        defaultValue: T
    ) throws(ISO.`8824`.Error) -> T {
        return try Self.decodeDefaultExplicitlyTagged(
            &nodes,
            tagNumber: tagNumber,
            tagClass: tagClass,
            defaultValue: defaultValue
        ) { (node: ISO.`8825`.Node) throws(ISO.`8824`.Error) -> T in
            try T(derEncoded: node)
        }
    }
}

extension ISO.`8825`.DER {

    @inlinable
    public static func explicitlyTagged<T>(
        _ nodes: inout ISO.`8825`.Node.Collection.Iterator,
        tagNumber: UInt,
        tagClass: ISO.`8824`.Identifier.Class,
        _ builder: (ISO.`8825`.Node) throws(ISO.`8824`.Error) -> T
    ) throws(ISO.`8824`.Error) -> T {
        guard let node = nodes.next() else {

            throw ISO.`8824`.Error.invalidASN1Object(
                reason:
                    "Explicitly tagged node for \(T.self) with tag number \(tagNumber) and class \(tagClass) not present"
            )
        }

        return try self.explicitlyTagged(node, tagNumber: tagNumber, tagClass: tagClass, builder)
    }

    @inlinable
    public static func explicitlyTagged<T>(
        _ node: ISO.`8825`.Node,
        tagNumber: UInt,
        tagClass: ISO.`8824`.Identifier.Class,
        _ builder: (ISO.`8825`.Node) throws(ISO.`8824`.Error) -> T
    ) throws(ISO.`8824`.Error) -> T {
        let expectedNodeID = ISO.`8824`.Identifier(tagWithNumber: tagNumber, tagClass: tagClass)
        guard node.identifier == expectedNodeID else {

            throw ISO.`8824`.Error.unexpectedFieldType(node.identifier)
        }

        guard case .constructed(let nodes) = node.content else {
            throw ISO.`8824`.Error.invalidASN1Object(
                reason: "Explicit tag \(expectedNodeID) for \(T.self) is primitive"
            )
        }

        var nodeIterator = nodes.makeIterator()
        guard let child = nodeIterator.next(), nodeIterator.next() == nil else {
            throw ISO.`8824`.Error.invalidASN1Object(
                reason:
                    "Invalid number of child nodes for explicit tag \(expectedNodeID) for \(T.self)"
            )
        }

        return try builder(child)
    }
}

extension ISO.`8825`.DER {

    @inlinable
    public static func parse(_ data: [UInt8]) throws(ISO.`8824`.Error) -> ISO.`8825`.Node {
        return try parse(data[...])
    }

    @inlinable
    public static func parse(_ data: ArraySlice<UInt8>) throws(ISO.`8824`.Error) -> ISO.`8825`.Node {
        var result = try ISO.`8825`.TLV.Parser.parse(data, encoding: .distinguished)

        let firstNode = result.nodes.removeFirst()

        let rootNode: ISO.`8825`.Node
        if firstNode.isConstructed {

            let nodeCollection = result.nodes.prefix { $0.depth > firstNode.depth }
            result.nodes = result.nodes.dropFirst(nodeCollection.count)
            rootNode = ISO.`8825`.Node(
                identifier: firstNode.identifier,
                content: .constructed(.init(nodes: nodeCollection, depth: firstNode.depth)),
                encodedBytes: firstNode.encodedBytes
            )
        } else {
            guard let dataBytes = firstNode.dataBytes else {
                preconditionFailure("A primitive TLV always carries its data bytes")
            }
            rootNode = ISO.`8825`.Node(
                identifier: firstNode.identifier,
                content: .primitive(dataBytes),
                encodedBytes: firstNode.encodedBytes
            )
        }

        precondition(
            result.nodes.count == 0,
            "ISO.8825.TLV.Parser unexpectedly allowed multiple root nodes"
        )

        return rootNode
    }
}

extension ISO.`8825`.DER {

    public struct Serializer: Sendable {
        @usableFromInline
        var _serializedBytes: [UInt8]

        @inlinable
        public var serializedBytes: [UInt8] {
            self._serializedBytes
        }

        @inlinable
        public init() {

            self._serializedBytes = []
            self._serializedBytes.reserveCapacity(1024)
        }

        @inlinable
        public mutating func appendPrimitiveNode<E: Swift.Error>(
            identifier: ISO.`8824`.Identifier,
            _ contentWriter: (inout [UInt8]) throws(E) -> Void
        ) throws(E) {
            try self._appendNode(identifier: identifier, constructed: false) {
                (serializer: inout Serializer) throws(E) in
                try contentWriter(&serializer._serializedBytes)
            }
        }

        @inlinable
        public mutating func appendConstructedNode<E: Swift.Error>(
            identifier: ISO.`8824`.Identifier,
            _ contentWriter: (inout Serializer) throws(E) -> Void
        ) throws(E) {
            try self._appendNode(identifier: identifier, constructed: true, contentWriter)
        }

        @inlinable
        public mutating func serialize<T: ISO.`8825`.DER.Serializable>(
            _ node: T
        ) throws(ISO.`8824`.Error) {
            try node.serialize(into: &self)
        }

        @inlinable
        public mutating func serialize<T: ISO.`8825`.DER.Serializable>(
            _ node: T,
            explicitlyTaggedWithTagNumber tagNumber: UInt,
            tagClass: ISO.`8824`.Identifier.Class
        ) throws(ISO.`8824`.Error) {
            let identifier = ISO.`8824`.Identifier(tagWithNumber: tagNumber, tagClass: tagClass)
            return try self.serialize(node, explicitlyTaggedWithIdentifier: identifier)
        }

        @inlinable
        public mutating func serialize<T: ISO.`8825`.DER.Serializable>(
            _ node: T,
            explicitlyTaggedWithIdentifier identifier: ISO.`8824`.Identifier
        ) throws(ISO.`8824`.Error) {
            try self.appendConstructedNode(identifier: identifier) {
                (coder: inout Serializer) throws(ISO.`8824`.Error) in
                try coder.serialize(node)
            }
        }

        @inlinable
        public mutating func serializeOptionalImplicitlyTagged<T: ISO.`8825`.DER.Serializable>(
            _ node: T?
        ) throws(ISO.`8824`.Error) {
            if let node {
                try self.serialize(node)
            }
        }

        @inlinable
        public mutating func serializeOptionalImplicitlyTagged<T: ISO.`8825`.DER.ImplicitlyTaggable>(
            _ node: T?,
            withIdentifier identifier: ISO.`8824`.Identifier
        ) throws(ISO.`8824`.Error) {
            if let node {
                try node.serialize(into: &self, withIdentifier: identifier)
            }
        }

        @inlinable
        public mutating func serialize<E: Swift.Error>(
            explicitlyTaggedWithTagNumber tagNumber: UInt,
            tagClass: ISO.`8824`.Identifier.Class,
            _ block: (inout Serializer) throws(E) -> Void
        ) throws(E) {
            let identifier = ISO.`8824`.Identifier(tagWithNumber: tagNumber, tagClass: tagClass)
            try self.appendConstructedNode(identifier: identifier) {
                (coder: inout Serializer) throws(E) in
                try block(&coder)
            }
        }

        @inlinable
        public mutating func serializeSequenceOf<Elements: Swift.Sequence>(
            _ elements: Elements,
            identifier: ISO.`8824`.Identifier = .sequence
        ) throws(ISO.`8824`.Error) where Elements.Element: ISO.`8825`.DER.Serializable {
            try self.appendConstructedNode(identifier: identifier) {
                (coder: inout Serializer) throws(ISO.`8824`.Error) in
                for element in elements {
                    try coder.serialize(element)
                }
            }
        }

        @inlinable
        public mutating func serializeSetOf<Elements: Swift.Sequence>(
            _ elements: Elements,
            identifier: ISO.`8824`.Identifier = .set
        ) throws(ISO.`8824`.Error) where Elements.Element: ISO.`8825`.DER.Serializable {

            var intermediateSerializer = ISO.`8825`.DER.Serializer()
            let serializedRanges = try elements.map {
                (element: Elements.Element) throws(ISO.`8824`.Error) -> Range<Int> in
                let startIndex = intermediateSerializer.serializedBytes.endIndex
                try intermediateSerializer.serialize(element)
                let endIndex = intermediateSerializer.serializedBytes.endIndex

                return startIndex..<endIndex
            }

            let serializedBytes = intermediateSerializer.serializedBytes

            let sortedRanges = serializedRanges.sorted { lhs, rhs in
                asn1SetElementLessThan(serializedBytes[lhs], serializedBytes[rhs])
            }

            self.appendConstructedNode(identifier: identifier) { serializer in
                for range in sortedRanges {
                    serializer.serializeRawBytes(serializedBytes[range])
                }
            }
        }

        @inlinable
        public mutating func serialize(_ node: ISO.`8825`.Node) {
            let identifier = node.identifier
            let constructed: Bool

            constructed =
                if case .constructed = node.content {
                    true
                } else {
                    false
                }

            self._appendNode(identifier: identifier, constructed: constructed) { coder in
                switch node.content {
                case .constructed(let nodes):
                    for node in nodes {
                        coder.serialize(node)
                    }

                case .primitive(let baseData):
                    coder.serializeRawBytes(baseData)
                }
            }
        }

        @inlinable
        public mutating func serializeRawBytes<Bytes: Swift.Sequence>(_ bytes: Bytes)
        where Bytes.Element == UInt8 {
            self._serializedBytes.append(contentsOf: bytes)
        }

        @inlinable
        package mutating func _appendNode<E: Swift.Error>(
            identifier: ISO.`8824`.Identifier,
            constructed: Bool,
            _ contentWriter: (inout Serializer) throws(E) -> Void
        ) throws(E) {

            self._serializedBytes.writeIdentifier(identifier, constructed: constructed)

            self._serializedBytes.append(0)

            let originalEndIndex = self._serializedBytes.endIndex
            let lengthIndex = self._serializedBytes.index(before: originalEndIndex)

            try contentWriter(&self)

            let contentLength = self._serializedBytes.distance(
                from: originalEndIndex,
                to: self._serializedBytes.endIndex
            )
            let lengthBytesNeeded = contentLength._bytesNeededToEncode
            if lengthBytesNeeded == 1 {

                assert(contentLength <= 0x7F)
                self._serializedBytes[lengthIndex] = UInt8(contentLength)
                return
            }

            self._serializedBytes._moveRange(
                offset: lengthBytesNeeded - 1,
                range: originalEndIndex..<self._serializedBytes.endIndex
            )

            self._serializedBytes[lengthIndex] = 0x80 | UInt8(lengthBytesNeeded - 1)
            var writeIndex = lengthIndex

            (0..<(lengthBytesNeeded - 1)).reversed().forEach { shift in

                self._serializedBytes.formIndex(after: &writeIndex)
                self._serializedBytes[writeIndex] = UInt8(
                    truncatingIfNeeded: (contentLength >> (shift * 8))
                )
            }

            assert(
                writeIndex
                    == self._serializedBytes.index(lengthIndex, offsetBy: lengthBytesNeeded - 1)
            )
        }
    }
}

extension ISO.`8825`.DER {
    public protocol Parseable {

        init(derEncoded node: ISO.`8825`.Node) throws(ISO.`8824`.Error)
    }
}

extension ISO.`8825`.DER.Parseable {

    @inlinable
    public init(
        derEncoded sequenceNodeIterator: inout ISO.`8825`.Node.Collection.Iterator
    ) throws(ISO.`8824`.Error) {
        guard let node = sequenceNodeIterator.next() else {
            throw ISO.`8824`.Error.invalidASN1Object(
                reason: "Unable to decode \(Self.self), no ASN.1 nodes to decode"
            )
        }

        self = try .init(derEncoded: node)
    }

    @inlinable
    public init(derEncoded: [UInt8]) throws(ISO.`8824`.Error) {
        self = try .init(derEncoded: ISO.`8825`.DER.parse(derEncoded))
    }

    @inlinable
    public init(derEncoded: ArraySlice<UInt8>) throws(ISO.`8824`.Error) {
        self = try .init(derEncoded: ISO.`8825`.DER.parse(derEncoded))
    }
}

extension ISO.`8825`.DER {
    public protocol Serializable {

        func serialize(into coder: inout ISO.`8825`.DER.Serializer) throws(ISO.`8824`.Error)
    }
}

extension ISO.`8825`.DER {

    public protocol ImplicitlyTaggable: ISO.`8825`.DER.Parseable, ISO.`8825`.DER.Serializable {

        static var defaultIdentifier: ISO.`8824`.Identifier { get }

        init(
            derEncoded: ISO.`8825`.Node,
            withIdentifier identifier: ISO.`8824`.Identifier
        ) throws(ISO.`8824`.Error)

        func serialize(
            into coder: inout ISO.`8825`.DER.Serializer,
            withIdentifier identifier: ISO.`8824`.Identifier
        ) throws(ISO.`8824`.Error)
    }
}

extension ISO.`8825`.DER.ImplicitlyTaggable {

    @inlinable
    public init(
        derEncoded sequenceNodeIterator: inout ISO.`8825`.Node.Collection.Iterator,
        withIdentifier identifier: ISO.`8824`.Identifier = Self.defaultIdentifier
    ) throws(ISO.`8824`.Error) {
        guard let node = sequenceNodeIterator.next() else {
            throw ISO.`8824`.Error.invalidASN1Object(
                reason: "Unable to decode \(Self.self), no ASN.1 nodes to decode"
            )
        }

        self = try .init(derEncoded: node, withIdentifier: identifier)
    }

    @inlinable
    public init(
        derEncoded: [UInt8],
        withIdentifier identifier: ISO.`8824`.Identifier = Self.defaultIdentifier
    ) throws(ISO.`8824`.Error) {
        self = try .init(derEncoded: ISO.`8825`.DER.parse(derEncoded), withIdentifier: identifier)
    }

    @inlinable
    public init(
        derEncoded: ArraySlice<UInt8>,
        withIdentifier identifier: ISO.`8824`.Identifier = Self.defaultIdentifier
    ) throws(ISO.`8824`.Error) {
        self = try .init(derEncoded: ISO.`8825`.DER.parse(derEncoded), withIdentifier: identifier)
    }

    @inlinable
    public init(derEncoded: ISO.`8825`.Node) throws(ISO.`8824`.Error) {
        try self.init(derEncoded: derEncoded, withIdentifier: Self.defaultIdentifier)
    }

    @inlinable
    public func serialize(into coder: inout ISO.`8825`.DER.Serializer) throws(ISO.`8824`.Error) {
        try self.serialize(into: &coder, withIdentifier: Self.defaultIdentifier)
    }
}
