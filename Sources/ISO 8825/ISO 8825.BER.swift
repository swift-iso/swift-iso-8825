public import ISO_8824

extension ISO_8825 {

    public enum BER {}
}

@available(*, unavailable)
extension ISO_8825.BER: Sendable {}

extension ISO_8825.BER {
    @inlinable
    public static func parse(_ data: [UInt8]) throws(ISO_8824.Error) -> ISO_8825.Node {
        return try parse(data[...])
    }

    @inlinable
    public static func parse(_ data: ArraySlice<UInt8>) throws(ISO_8824.Error) -> ISO_8825.Node {
        var result = try ISO_8825.TLV.Parser.parse(data, encoding: .basic)

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
            rootNode = ISO_8825.Node(
                identifier: firstNode.identifier,
                content: .primitive(firstNode.dataBytes!),
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

extension ISO_8825.BER {

    @inlinable
    public static func sequence<T>(
        _ node: ISO_8825.Node,
        identifier: ISO_8824.Identifier,
        _ builder: (inout ISO_8825.Node.Collection.Iterator) throws(ISO_8824.Error) -> T
    ) throws(ISO_8824.Error) -> T {
        return try ISO_8825.DER.sequence(node, identifier: identifier, builder)
    }

    @inlinable
    public static func sequence<T: ISO_8825.BER.Parseable>(
        of: T.Type = T.self,
        identifier: ISO_8824.Identifier,
        rootNode: ISO_8825.Node
    ) throws(ISO_8824.Error) -> [T] {
        guard rootNode.identifier == identifier, case .constructed(let nodes) = rootNode.content
        else {
            throw ISO_8824.Error.unexpectedFieldType(rootNode.identifier)
        }

        return try nodes.map { (node: ISO_8825.Node) throws(ISO_8824.Error) -> T in
            try T(berEncoded: node)
        }
    }

    @inlinable
    public static func sequence<T: ISO_8825.BER.Parseable>(
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
    public static func set<T: ISO_8825.BER.Parseable>(
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
    public static func set<T: ISO_8825.BER.Parseable>(
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
    public static func lazySet<T: ISO_8825.BER.Parseable>(
        of: T.Type = T.self,
        identifier: ISO_8824.Identifier,
        rootNode: ISO_8825.Node
    ) throws(ISO_8824.Error) -> ISO_8825.BER.LazySetOfSequence<T> {
        guard rootNode.identifier == identifier, case .constructed(let nodes) = rootNode.content
        else {
            throw ISO_8824.Error.unexpectedFieldType(rootNode.identifier)
        }

        return .init(
            nodes.lazy.map { node in
                Result { () throws(ISO_8824.Error) -> T in try T(berEncoded: node) }
            }
        )
    }
}

extension ISO_8825.BER {
    public typealias LazySetOfSequence = ISO_8825.LazySetOfSequence
}

extension ISO_8825.BER {

    @inlinable
    public static func optionalExplicitlyTagged<T>(
        _ nodes: inout ISO_8825.Node.Collection.Iterator,
        tagNumber: UInt,
        tagClass: ISO_8824.Identifier.Class,
        _ builder: (ISO_8825.Node) throws(ISO_8824.Error) -> T
    ) throws(ISO_8824.Error) -> T? {
        return try ISO_8825.DER.optionalExplicitlyTagged(
            &nodes,
            tagNumber: tagNumber,
            tagClass: tagClass,
            builder
        )
    }
}

extension ISO_8825.BER {

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
        return try ISO_8825.DER.optionalImplicitlyTagged(
            &nodes,
            tagNumber: tagNumber,
            tagClass: tagClass,
            builder
        )
    }
}

extension ISO_8825.BER {

    @inlinable
    public static func decodeDefault<T: ISO_8825.BER.Parseable & Equatable>(
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

        return try builder(node)
    }

    @inlinable
    public static func decodeDefault<T: ISO_8825.BER.Parseable & Equatable>(
        _ nodes: inout ISO_8825.Node.Collection.Iterator,
        identifier: ISO_8824.Identifier,
        defaultValue: T
    ) throws(ISO_8824.Error) -> T {
        return try Self.decodeDefault(&nodes, identifier: identifier, defaultValue: defaultValue) {
            (node: ISO_8825.Node) throws(ISO_8824.Error) -> T in
            try T(berEncoded: node)
        }
    }

    @inlinable
    public static func decodeDefault<T: ISO_8825.BER.ImplicitlyTaggable & Equatable>(
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
    public static func decodeDefaultExplicitlyTagged<T: ISO_8825.BER.Parseable & Equatable>(
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

        return result
    }

    @inlinable
    public static func decodeDefaultExplicitlyTagged<T: ISO_8825.BER.Parseable & Equatable>(
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
            try T(berEncoded: node)
        }
    }
}

extension ISO_8825.BER {

    @inlinable
    public static func explicitlyTagged<T>(
        _ nodes: inout ISO_8825.Node.Collection.Iterator,
        tagNumber: UInt,
        tagClass: ISO_8824.Identifier.Class,
        _ builder: (ISO_8825.Node) throws(ISO_8824.Error) -> T
    ) throws(ISO_8824.Error) -> T {
        return try ISO_8825.DER.explicitlyTagged(
            &nodes,
            tagNumber: tagNumber,
            tagClass: tagClass,
            builder
        )
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

extension ISO_8825.BER {
    public protocol Parseable: ISO_8825.DER.Parseable {

        init(berEncoded node: ISO_8825.Node) throws(ISO_8824.Error)
    }
}

extension ISO_8825.BER.Parseable {

    @inlinable
    public init(berEncoded node: ISO_8825.Node) throws(ISO_8824.Error) {
        self = try .init(derEncoded: node)
    }

    @inlinable
    public init(
        berEncoded sequenceNodeIterator: inout ISO_8825.Node.Collection.Iterator
    ) throws(ISO_8824.Error) {
        guard let node = sequenceNodeIterator.next() else {
            throw ISO_8824.Error.invalidASN1Object(
                reason: "Unable to decode \(Self.self), no ASN.1 nodes to decode"
            )
        }

        self = try .init(berEncoded: node)
    }

    @inlinable
    public init(berEncoded: [UInt8]) throws(ISO_8824.Error) {
        self = try .init(berEncoded: ISO_8825.BER.parse(berEncoded))
    }

    @inlinable
    public init(berEncoded: ArraySlice<UInt8>) throws(ISO_8824.Error) {
        self = try .init(berEncoded: ISO_8825.BER.parse(berEncoded))
    }
}

extension ISO_8825.BER {
    public protocol Serializable: ISO_8825.DER.Serializable {
    }
}

extension ISO_8825.BER {

    public protocol ImplicitlyTaggable: ISO_8825.BER.Parseable, ISO_8825.BER.Serializable, ISO_8825
            .DER.ImplicitlyTaggable
    {

        static var defaultIdentifier: ISO_8824.Identifier { get }

        init(
            berEncoded: ISO_8825.Node,
            withIdentifier identifier: ISO_8824.Identifier
        ) throws(ISO_8824.Error)
    }
}

extension ISO_8825.BER.ImplicitlyTaggable {

    @inlinable
    public init(
        berEncoded sequenceNodeIterator: inout ISO_8825.Node.Collection.Iterator,
        withIdentifier identifier: ISO_8824.Identifier = Self.defaultIdentifier
    ) throws(ISO_8824.Error) {
        guard let node = sequenceNodeIterator.next() else {
            throw ISO_8824.Error.invalidASN1Object(
                reason: "Unable to decode \(Self.self), no ASN.1 nodes to decode"
            )
        }

        self = try .init(berEncoded: node, withIdentifier: identifier)
    }

    @inlinable
    public init(
        berEncoded: [UInt8],
        withIdentifier identifier: ISO_8824.Identifier = Self.defaultIdentifier
    ) throws(ISO_8824.Error) {
        self = try .init(berEncoded: ISO_8825.BER.parse(berEncoded), withIdentifier: identifier)
    }

    @inlinable
    public init(
        berEncoded: ArraySlice<UInt8>,
        withIdentifier identifier: ISO_8824.Identifier = Self.defaultIdentifier
    ) throws(ISO_8824.Error) {
        self = try .init(berEncoded: ISO_8825.BER.parse(berEncoded), withIdentifier: identifier)
    }

    @inlinable
    public init(berEncoded: ISO_8825.Node) throws(ISO_8824.Error) {
        try self.init(berEncoded: berEncoded, withIdentifier: Self.defaultIdentifier)
    }
}
