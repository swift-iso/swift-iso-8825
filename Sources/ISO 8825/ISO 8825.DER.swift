public import ISO_8824

extension ISO_8825 {

    public enum DER {}
}

@available(*, unavailable)
extension ISO_8825.DER: Sendable {}

extension ISO_8825.DER {

    @inlinable
    public static func sequence<T>(
        _ node: ISO_8825.Node,
        identifier: ISO_8824.Identifier,
        _ builder: (inout ISO_8825.Node.Collection.Iterator) throws(ISO_8824.Error) -> T
    ) throws(ISO_8824.Error) -> T {
        guard node.identifier == identifier, case .constructed(let nodes) = node.content else {
            throw ISO_8824.Error.unexpectedFieldType(node.identifier)
        }

        var iterator = nodes.makeIterator()

        let result = try builder(&iterator)

        guard iterator.next() == nil else {
            throw ISO_8824.Error.invalidASN1Object(reason: "Unconsumed sequence nodes")
        }

        return result
    }

    @inlinable
    public static func sequence<T: ISO_8825.DER.Parseable>(
        of: T.Type = T.self,
        identifier: ISO_8824.Identifier,
        rootNode: ISO_8825.Node
    ) throws(ISO_8824.Error) -> [T] {
        guard rootNode.identifier == identifier, case .constructed(let nodes) = rootNode.content
        else {
            throw ISO_8824.Error.unexpectedFieldType(rootNode.identifier)
        }

        return try nodes.map { (node: ISO_8825.Node) throws(ISO_8824.Error) -> T in
            try T(derEncoded: node)
        }
    }

    @inlinable
    public static func sequence<T: ISO_8825.DER.Parseable>(
        of: T.Type = T.self,
        identifier: ISO_8824.Identifier,
        nodes: inout ISO_8825.Node.Collection.Iterator
    ) throws(ISO_8824.Error) -> [T] {
        guard let node = nodes.next() else {

            throw ISO_8824.Error.invalidASN1Object(
                reason: "No sequence node available for \(T.self) and identifier \(identifier)"
            )
        }

        return try sequence(of: T.self, identifier: identifier, rootNode: node)
    }

    @inlinable
    public static func set<T>(
        _ node: ISO_8825.Node,
        identifier: ISO_8824.Identifier,
        _ builder: (inout ISO_8825.Node.Collection.Iterator) throws(ISO_8824.Error) -> T
    ) throws(ISO_8824.Error) -> T {

        return try sequence(node, identifier: identifier, builder)
    }

    @inlinable
    public static func set<T: ISO_8825.DER.Parseable>(
        of: T.Type = T.self,
        identifier: ISO_8824.Identifier,
        nodes: inout ISO_8825.Node.Collection.Iterator
    ) throws(ISO_8824.Error) -> [T] {
        guard let node = nodes.next() else {

            throw ISO_8824.Error.invalidASN1Object(
                reason: "No set node available for \(T.self) and identifier \(identifier)"
            )
        }

        return try Self.set(of: T.self, identifier: identifier, rootNode: node)
    }

    @inlinable
    public static func set<T: ISO_8825.DER.Parseable>(
        of type: T.Type = T.self,
        identifier: ISO_8824.Identifier,
        rootNode: ISO_8825.Node
    ) throws(ISO_8824.Error) -> [T] {
        try self.lazySet(of: type, identifier: identifier, rootNode: rootNode)
            .map { (element: Result<T, ISO_8824.Error>) throws(ISO_8824.Error) -> T in
                try element.get()
            }
    }

    @inlinable
    public static func lazySet<T: ISO_8825.DER.Parseable>(
        of: T.Type = T.self,
        identifier: ISO_8824.Identifier,
        rootNode: ISO_8825.Node
    ) throws(ISO_8824.Error) -> ISO_8825.DER.LazySetOfSequence<T> {
        guard rootNode.identifier == identifier, case .constructed(let nodes) = rootNode.content
        else {
            throw ISO_8824.Error.unexpectedFieldType(rootNode.identifier)
        }

        guard nodes.isOrderedAccordingToSetOfSemantics() else {
            throw ISO_8824.Error.invalidASN1Object(
                reason: "SET OF fields are not lexicographically ordered"
            )
        }

        return .init(
            nodes.lazy.map { node in
                Result { () throws(ISO_8824.Error) -> T in try T(derEncoded: node) }
            }
        )
    }
}

extension ISO_8825.DER {
    public typealias LazySetOfSequence = ISO_8825.LazySetOfSequence
}

extension ISO_8825.DER {

    @inlinable
    public static func optionalExplicitlyTagged<T>(
        _ nodes: inout ISO_8825.Node.Collection.Iterator,
        tagNumber: UInt,
        tagClass: ISO_8824.Identifier.Class,
        _ builder: (ISO_8825.Node) throws(ISO_8824.Error) -> T
    ) throws(ISO_8824.Error) -> T? {
        var localNodesCopy = nodes
        guard let node = localNodesCopy.next() else {

            return nil
        }

        let expectedNodeID = ISO_8824.Identifier(tagWithNumber: tagNumber, tagClass: tagClass)

        guard node.identifier == expectedNodeID else {

            return nil
        }

        nodes = localNodesCopy

        guard case .constructed(let nodes) = node.content else {
            throw ISO_8824.Error.invalidASN1Object(
                reason:
                    "Explicit tags should always be constructed, got \(node.identifier) which is not."
            )
        }

        var nodeIterator = nodes.makeIterator()
        guard let child = nodeIterator.next(), nodeIterator.next() == nil else {
            throw ISO_8824.Error.invalidASN1Object(
                reason:
                    "Too many child nodes in optionally tagged node of \(T.self) with identifier \(expectedNodeID)"
            )
        }

        return try builder(child)
    }
}

extension ISO_8825.DER {

    @inlinable
    public static func optionalImplicitlyTagged<T: ISO_8825.DER.ImplicitlyTaggable>(
        _ nodes: inout ISO_8825.Node.Collection.Iterator,
        tag: ISO_8824.Identifier = T.defaultIdentifier
    ) throws(ISO_8824.Error) -> T? {
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
        _ nodes: inout ISO_8825.Node.Collection.Iterator,
        tagNumber: UInt,
        tagClass: ISO_8824.Identifier.Class,
        _ builder: (ISO_8825.Node) throws(E) -> Result
    ) throws(E) -> Result? {
        var localNodesCopy = nodes
        guard let node = localNodesCopy.next() else {

            return nil
        }

        let expectedNodeID = ISO_8824.Identifier(tagWithNumber: tagNumber, tagClass: tagClass)
        guard node.identifier == expectedNodeID else {

            return nil
        }

        nodes = localNodesCopy

        return try builder(node)
    }
}

extension ISO_8825.DER {

    @inlinable
    public static func decodeDefault<T: ISO_8825.DER.Parseable & Equatable>(
        _ nodes: inout ISO_8825.Node.Collection.Iterator,
        identifier: ISO_8824.Identifier,
        defaultValue: T,
        _ builder: (ISO_8825.Node) throws(ISO_8824.Error) -> T
    ) throws(ISO_8824.Error) -> T {

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
            throw ISO_8824.Error.invalidASN1Object(
                reason:
                    "DEFAULT for \(T.self) with identifier \(identifier) present in DER but encoded at default value \(defaultValue)"
            )
        }

        return parsed
    }

    @inlinable
    public static func decodeDefault<T: ISO_8825.DER.Parseable & Equatable>(
        _ nodes: inout ISO_8825.Node.Collection.Iterator,
        identifier: ISO_8824.Identifier,
        defaultValue: T
    ) throws(ISO_8824.Error) -> T {
        return try Self.decodeDefault(&nodes, identifier: identifier, defaultValue: defaultValue) {
            (node: ISO_8825.Node) throws(ISO_8824.Error) -> T in
            try T(derEncoded: node)
        }
    }

    @inlinable
    public static func decodeDefault<T: ISO_8825.DER.ImplicitlyTaggable & Equatable>(
        _ nodes: inout ISO_8825.Node.Collection.Iterator,
        defaultValue: T
    ) throws(ISO_8824.Error) -> T {
        return try Self.decodeDefault(
            &nodes,
            identifier: T.defaultIdentifier,
            defaultValue: defaultValue
        )
    }

    @inlinable
    public static func decodeDefaultExplicitlyTagged<T: ISO_8825.DER.Parseable & Equatable>(
        _ nodes: inout ISO_8825.Node.Collection.Iterator,
        tagNumber: UInt,
        tagClass: ISO_8824.Identifier.Class,
        defaultValue: T,
        _ builder: (ISO_8825.Node) throws(ISO_8824.Error) -> T
    ) throws(ISO_8824.Error) -> T {
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

            throw ISO_8824.Error.invalidASN1Object(
                reason:
                    "DEFAULT for \(T.self) with tag number \(tagNumber) and class \(tagClass) present in DER but encoded at default value \(defaultValue)"
            )
        }

        return result
    }

    @inlinable
    public static func decodeDefaultExplicitlyTagged<T: ISO_8825.DER.Parseable & Equatable>(
        _ nodes: inout ISO_8825.Node.Collection.Iterator,
        tagNumber: UInt,
        tagClass: ISO_8824.Identifier.Class,
        defaultValue: T
    ) throws(ISO_8824.Error) -> T {
        return try Self.decodeDefaultExplicitlyTagged(
            &nodes,
            tagNumber: tagNumber,
            tagClass: tagClass,
            defaultValue: defaultValue
        ) { (node: ISO_8825.Node) throws(ISO_8824.Error) -> T in
            try T(derEncoded: node)
        }
    }
}

extension ISO_8825.DER {

    @inlinable
    public static func explicitlyTagged<T>(
        _ nodes: inout ISO_8825.Node.Collection.Iterator,
        tagNumber: UInt,
        tagClass: ISO_8824.Identifier.Class,
        _ builder: (ISO_8825.Node) throws(ISO_8824.Error) -> T
    ) throws(ISO_8824.Error) -> T {
        guard let node = nodes.next() else {

            throw ISO_8824.Error.invalidASN1Object(
                reason:
                    "Explicitly tagged node for \(T.self) with tag number \(tagNumber) and class \(tagClass) not present"
            )
        }

        return try self.explicitlyTagged(node, tagNumber: tagNumber, tagClass: tagClass, builder)
    }

    @inlinable
    public static func explicitlyTagged<T>(
        _ node: ISO_8825.Node,
        tagNumber: UInt,
        tagClass: ISO_8824.Identifier.Class,
        _ builder: (ISO_8825.Node) throws(ISO_8824.Error) -> T
    ) throws(ISO_8824.Error) -> T {
        let expectedNodeID = ISO_8824.Identifier(tagWithNumber: tagNumber, tagClass: tagClass)
        guard node.identifier == expectedNodeID else {

            throw ISO_8824.Error.unexpectedFieldType(node.identifier)
        }

        guard case .constructed(let nodes) = node.content else {
            throw ISO_8824.Error.invalidASN1Object(
                reason: "Explicit tag \(expectedNodeID) for \(T.self) is primitive"
            )
        }

        var nodeIterator = nodes.makeIterator()
        guard let child = nodeIterator.next(), nodeIterator.next() == nil else {
            throw ISO_8824.Error.invalidASN1Object(
                reason:
                    "Invalid number of child nodes for explicit tag \(expectedNodeID) for \(T.self)"
            )
        }

        return try builder(child)
    }
}

extension ISO_8825.DER {

    @inlinable
    public static func parse(_ data: [UInt8]) throws(ISO_8824.Error) -> ISO_8825.Node {
        return try parse(data[...])
    }

    @inlinable
    public static func parse(_ data: ArraySlice<UInt8>) throws(ISO_8824.Error) -> ISO_8825.Node {
        var result = try ISO_8825.TLV.Parser.parse(data, encoding: .distinguished)

        let firstNode = result.nodes.removeFirst()

        let rootNode: ISO_8825.Node
        if firstNode.isConstructed {

            let nodeCollection = result.nodes.prefix { $0.depth > firstNode.depth }
            result.nodes = result.nodes.dropFirst(nodeCollection.count)
            rootNode = ISO_8825.Node(
                identifier: firstNode.identifier,
                content: .constructed(.init(nodes: nodeCollection, depth: firstNode.depth)),
                encodedBytes: firstNode.encodedBytes
            )
        } else {
            guard let dataBytes = firstNode.dataBytes else {
                preconditionFailure("A primitive TLV always carries its data bytes")
            }
            rootNode = ISO_8825.Node(
                identifier: firstNode.identifier,
                content: .primitive(dataBytes),
                encodedBytes: firstNode.encodedBytes
            )
        }

        precondition(
            result.nodes.count == 0,
            "ISO_8825.TLV.Parser unexpectedly allowed multiple root nodes"
        )

        return rootNode
    }
}

extension ISO_8825.DER {
}

extension ISO_8825.DER {
}

extension ISO_8825.DER.Parseable {

    @inlinable
    public init(
        derEncoded sequenceNodeIterator: inout ISO_8825.Node.Collection.Iterator
    ) throws(ISO_8824.Error) {
        guard let node = sequenceNodeIterator.next() else {
            throw ISO_8824.Error.invalidASN1Object(
                reason: "Unable to decode \(Self.self), no ASN.1 nodes to decode"
            )
        }

        self = try .init(derEncoded: node)
    }

    @inlinable
    public init(derEncoded: [UInt8]) throws(ISO_8824.Error) {
        self = try .init(derEncoded: ISO_8825.DER.parse(derEncoded))
    }

    @inlinable
    public init(derEncoded: ArraySlice<UInt8>) throws(ISO_8824.Error) {
        self = try .init(derEncoded: ISO_8825.DER.parse(derEncoded))
    }
}

extension ISO_8825.DER {
}

extension ISO_8825.DER {
}

extension ISO_8825.DER.ImplicitlyTaggable {

    @inlinable
    public init(
        derEncoded sequenceNodeIterator: inout ISO_8825.Node.Collection.Iterator,
        withIdentifier identifier: ISO_8824.Identifier = Self.defaultIdentifier
    ) throws(ISO_8824.Error) {
        guard let node = sequenceNodeIterator.next() else {
            throw ISO_8824.Error.invalidASN1Object(
                reason: "Unable to decode \(Self.self), no ASN.1 nodes to decode"
            )
        }

        self = try .init(derEncoded: node, withIdentifier: identifier)
    }

    @inlinable
    public init(
        derEncoded: [UInt8],
        withIdentifier identifier: ISO_8824.Identifier = Self.defaultIdentifier
    ) throws(ISO_8824.Error) {
        self = try .init(derEncoded: ISO_8825.DER.parse(derEncoded), withIdentifier: identifier)
    }

    @inlinable
    public init(
        derEncoded: ArraySlice<UInt8>,
        withIdentifier identifier: ISO_8824.Identifier = Self.defaultIdentifier
    ) throws(ISO_8824.Error) {
        self = try .init(derEncoded: ISO_8825.DER.parse(derEncoded), withIdentifier: identifier)
    }

    @inlinable
    public init(derEncoded: ISO_8825.Node) throws(ISO_8824.Error) {
        try self.init(derEncoded: derEncoded, withIdentifier: Self.defaultIdentifier)
    }

    @inlinable
    public func serialize(into coder: inout ISO_8825.DER.Serializer) throws(ISO_8824.Error) {
        try self.serialize(into: &coder, withIdentifier: Self.defaultIdentifier)
    }
}
