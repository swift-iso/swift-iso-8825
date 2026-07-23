//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftASN1 open source project
//
// Copyright (c) 2019-2023 Apple Inc. and the SwiftASN1 project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftASN1 project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

public import ISO_8824

extension ISO_8825 {
    /// ``ISO_8825/BER`` defines a namespace that is used to store a number of helper methods and types
    /// for BER encoding and decoding.
    public enum BER {}
}

@available(*, unavailable)
extension ISO_8825.BER: Sendable {}

// MARK: - Parsing

extension ISO_8825.BER {
    @inlinable
    public static func parse(_ data: [UInt8]) throws(ISO_8824.Error) -> ISO_8825.Node {
        return try parse(data[...])
    }

    @inlinable
    public static func parse(_ data: ArraySlice<UInt8>) throws(ISO_8824.Error) -> ISO_8825.Node {
        var result = try ISO_8825.TLV.Parser.parse(data, encoding: .basic)

        // There will always be at least one node if the above didn't throw, so we can safely just removeFirst here.
        let firstNode = result.nodes.removeFirst()

        let rootNode: ISO_8825.Node
        if firstNode.isConstructed {
            // We need to feed it the next set of nodes.
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

        precondition(result.nodes.count == 0, "ISO_8825.TLV.Parser unexpectedly allowed multiple root nodes")

        return rootNode
    }
}

// MARK: - Sequence, SequenceOf, Set and SetOf
extension ISO_8825.BER {
    /// Parse the node as an ASN.1 SEQUENCE.
    ///
    /// The "child" elements in the sequence will be exposed as an iterator to `builder`.
    ///
    /// - parameters:
    ///     - node: The ``ISO_8825.Node`` to parse
    ///     - identifier: The ``ISO_8824.Identifier`` that the SEQUENCE is expected to have.
    ///     - builder: A closure that will be called with the collection of nodes within the sequence.
    @inlinable
    public static func sequence<T>(
        _ node: ISO_8825.Node,
        identifier: ISO_8824.Identifier,
        _ builder: (inout ISO_8825.Node.Collection.Iterator) throws(ISO_8824.Error) -> T
    ) throws(ISO_8824.Error) -> T {
        return try ISO_8825.DER.sequence(node, identifier: identifier, builder)
    }

    /// Parse the node as an ASN.1 SEQUENCE OF.
    ///
    /// Constructs an array of `T` elements parsed from the sequence.
    ///
    /// - parameters:
    ///     - of: An optional parameter to express the type to decode.
    ///     - identifier: The ``ISO_8824.Identifier`` that the SEQUENCE OF is expected to have.
    ///     - rootNode: The ``ISO_8825.Node`` to parse
    /// - returns: An array of elements representing the elements in the sequence.
    @inlinable
    public static func sequence<T: ISO_8825.BER.Parseable>(
        of: T.Type = T.self,
        identifier: ISO_8824.Identifier,
        rootNode: ISO_8825.Node
    ) throws(ISO_8824.Error) -> [T] {
        guard rootNode.identifier == identifier, case .constructed(let nodes) = rootNode.content else {
            throw ISO_8824.Error.unexpectedFieldType(rootNode.identifier)
        }

        return try nodes.map { (node: ISO_8825.Node) throws(ISO_8824.Error) -> T in try T(berEncoded: node) }
    }

    /// Parse the node as an ASN.1 SEQUENCE OF.
    ///
    /// Constructs an array of `T` elements parsed from the sequence.
    ///
    /// - parameters:
    ///     - of: An optional parameter to express the type to decode.
    ///     - identifier: The ``ISO_8824.Identifier`` that the SEQUENCE OF is expected to have.
    ///     - nodes: An ``ISO_8825.Node.Collection/Iterator`` of nodes to parse.
    /// - returns: An array of elements representing the elements in the sequence.
    @inlinable
    public static func sequence<T: ISO_8825.BER.Parseable>(
        of: T.Type = T.self,
        identifier: ISO_8824.Identifier,
        nodes: inout ISO_8825.Node.Collection.Iterator
    ) throws(ISO_8824.Error) -> [T] {
        guard let node = nodes.next() else {
            // Not present, throw.
            throw ISO_8824.Error.invalidASN1Object(
                reason: "No sequence node available for \(T.self) and identifier \(identifier)"
            )
        }

        return try sequence(of: T.self, identifier: identifier, rootNode: node)
    }

    /// Parse the node as an ASN.1 SET.
    ///
    /// The "child" elements in the sequence will be exposed as an iterator to `builder`.
    ///
    /// - parameters:
    ///     - node: The ``ISO_8825.Node`` to parse
    ///     - identifier: The ``ISO_8824.Identifier`` that the SET is expected to have.
    ///     - builder: A closure that will be called with the collection of nodes within the set.
    @inlinable
    public static func set<T>(
        _ node: ISO_8825.Node,
        identifier: ISO_8824.Identifier,
        _ builder: (inout ISO_8825.Node.Collection.Iterator) throws(ISO_8824.Error) -> T
    ) throws(ISO_8824.Error) -> T {
        // Shhhh these two are secretly the same with identifier.
        return try sequence(node, identifier: identifier, builder)
    }

    /// Parse the node as an ASN.1 SET OF.
    ///
    /// Constructs an array of `T` elements parsed from the set.
    ///
    /// - parameters:
    ///     - of: An optional parameter to express the type to decode.
    ///     - identifier: The ``ISO_8824.Identifier`` that the SET OF is expected to have.
    ///     - nodes: An ``ISO_8825.Node.Collection/Iterator`` of nodes to parse.
    /// - returns: An array of elements representing the elements in the set.
    @inlinable
    public static func set<T: ISO_8825.BER.Parseable>(
        of: T.Type = T.self,
        identifier: ISO_8824.Identifier,
        nodes: inout ISO_8825.Node.Collection.Iterator
    ) throws(ISO_8824.Error) -> [T] {
        guard let node = nodes.next() else {
            // Not present, throw.
            throw ISO_8824.Error.invalidASN1Object(
                reason: "No set node available for \(T.self) and identifier \(identifier)"
            )
        }

        return try Self.set(of: T.self, identifier: identifier, rootNode: node)
    }

    /// Parse the node as an ASN.1 SET OF.
    ///
    /// Constructs an array of `T` elements parsed from the set.
    ///
    /// - parameters:
    ///     - type: An optional parameter to express the type to decode.
    ///     - identifier: The ``ISO_8824.Identifier`` that the SET OF is expected to have.
    ///     - rootNode: The ``ISO_8825.Node`` to parse
    /// - returns: An array of elements representing the elements in the sequence.
    @inlinable
    public static func set<T: ISO_8825.BER.Parseable>(
        of type: T.Type = T.self,
        identifier: ISO_8824.Identifier,
        rootNode: ISO_8825.Node
    ) throws(ISO_8824.Error) -> [T] {
        try self.lazySet(of: type, identifier: identifier, rootNode: rootNode)
            .map { (element: Result<T, ISO_8824.Error>) throws(ISO_8824.Error) -> T in try element.get() }
    }

    /// Parse the node as an ASN.1 SET OF lazily.
    ///
    /// Constructs a Sequence of `T` elements that will be lazily parsed from the set.
    ///
    /// - parameters:
    ///     - of: An optional parameter to express the type to decode.
    ///     - identifier: The ``ISO_8824.Identifier`` that the SET OF is expected to have.
    ///     - rootNode: The ``ISO_8825.Node`` to parse
    /// - returns: A `Sequence` of elements representing the `Result` of parsing the elements in the sequence.
    @inlinable
    public static func lazySet<T: ISO_8825.BER.Parseable>(
        of: T.Type = T.self,
        identifier: ISO_8824.Identifier,
        rootNode: ISO_8825.Node
    ) throws(ISO_8824.Error) -> ISO_8825.BER.LazySetOfSequence<T> {
        guard rootNode.identifier == identifier, case .constructed(let nodes) = rootNode.content else {
            throw ISO_8824.Error.unexpectedFieldType(rootNode.identifier)
        }

        // BER allows unsorted SET OF

        return .init(nodes.lazy.map { node in Result { () throws(ISO_8824.Error) -> T in try T(berEncoded: node) } })
    }
}

// MARK: - LazySetOfSequence
extension ISO_8825.BER {
    public typealias LazySetOfSequence = ISO_8825.LazySetOfSequence
}

// MARK: - Optional explicitly tagged
extension ISO_8825.BER {
    /// Parses an optional explicitly tagged element.
    ///
    /// - parameters:
    ///     - nodes: The ``ISO_8825.Node.Collection/Iterator`` to parse this element out of.
    ///     - tagNumber: The number of the explicit tag.
    ///     - tagClass: The class of the explicit tag.
    ///     - builder: A closure that will be called with the node for the element, if the element is present.
    ///
    /// - returns: The result of `builder` if the element was present, or `nil` if it was not.
    @inlinable
    public static func optionalExplicitlyTagged<T>(
        _ nodes: inout ISO_8825.Node.Collection.Iterator,
        tagNumber: UInt,
        tagClass: ISO_8824.Identifier.Class,
        _ builder: (ISO_8825.Node) throws(ISO_8824.Error) -> T
    ) throws(ISO_8824.Error) -> T? {
        return try ISO_8825.DER.optionalExplicitlyTagged(&nodes, tagNumber: tagNumber, tagClass: tagClass, builder)
    }
}

// MARK: - Optional implicitly tagged
extension ISO_8825.BER {
    /// Parses an optional implicitly tagged element.
    ///
    /// - parameters:
    ///     - nodes: The ``ISO_8825.Node.Collection/Iterator`` to parse this element out of.
    ///     - tag: The implicit tag. Defaults to the default tag for the element.
    ///
    /// - returns: The parsed element, if it was present, or `nil` if it was not.
    @inlinable
    public static func optionalImplicitlyTagged<T: ISO_8825.DER.ImplicitlyTaggable>(
        _ nodes: inout ISO_8825.Node.Collection.Iterator,
        tag: ISO_8824.Identifier = T.defaultIdentifier
    ) throws(ISO_8824.Error) -> T? {
        var localNodesCopy = nodes
        guard let node = localNodesCopy.next() else {
            // Node not present, return nil.
            return nil
        }

        guard node.identifier == tag else {
            // Node is a mismatch, with the wrong tag. Our optional isn't present.
            return nil
        }

        // We're good: pass the node on.
        return try T(derEncoded: &nodes, withIdentifier: tag)
    }

    /// Parses an optional implicitly tagged element.
    ///
    /// - parameters:
    ///     - nodes: The ``ISO_8825.Node.Collection/Iterator`` to parse this element out of.
    ///     - tagNumber: The number of the explicit tag.
    ///     - tagClass: The class of the explicit tag.
    ///     - builder: A closure that will be called with the node for the element, if the element is present.
    ///
    /// - returns: The result of `builder` if the element was present, or `nil` if it was not.
    @inlinable
    public static func optionalImplicitlyTagged<Result, E: Swift.Error>(
        _ nodes: inout ISO_8825.Node.Collection.Iterator,
        tagNumber: UInt,
        tagClass: ISO_8824.Identifier.Class,
        _ builder: (ISO_8825.Node) throws(E) -> Result
    ) throws(E) -> Result? {
        return try ISO_8825.DER.optionalImplicitlyTagged(&nodes, tagNumber: tagNumber, tagClass: tagClass, builder)
    }
}

// MARK: - DEFAULT
extension ISO_8825.BER {
    /// Parses a value that is encoded with a DEFAULT.
    ///
    /// Such a value is optional, and if absent will be replaced with its default.
    ///
    /// - parameters:
    ///     - nodes: The ``ISO_8825.Node.Collection/Iterator`` to parse this element out of.
    ///     - identifier: The implicit tag. Defaults to the default tag for the element.
    ///     - defaultValue: The default value to use if there was no encoded value.
    ///     - builder: A closure that will be called with the node for the element, if the element is present.
    ///
    /// - returns: The parsed element, if it was present, or the default if it was not.
    @inlinable
    public static func decodeDefault<T: ISO_8825.BER.Parseable & Equatable>(
        _ nodes: inout ISO_8825.Node.Collection.Iterator,
        identifier: ISO_8824.Identifier,
        defaultValue: T,
        _ builder: (ISO_8825.Node) throws(ISO_8824.Error) -> T
    ) throws(ISO_8824.Error) -> T {
        // A weird trick here: we only want to consume the next node _if_ it has the right tag. To achieve that,
        // we work on a copy.
        var localNodesCopy = nodes
        guard let node = localNodesCopy.next() else {
            // Whoops, nothing here.
            return defaultValue
        }

        guard node.identifier == identifier else {
            // Node is a mismatch, with the wrong identifier. Our optional isn't present.
            return defaultValue
        }

        // We have the right optional, so let's consume it.
        nodes = localNodesCopy
        let parsed = try builder(node)

        // DER forbids encoding DEFAULT values at their default state, but BER allows it

        return parsed
    }

    /// Parses a value that is encoded with a DEFAULT.
    ///
    /// Such a value is optional, and if absent will be replaced with its default. This function is
    /// a helper wrapper for ``decodeDefault(_:identifier:defaultValue:_:)`` that automatically invokes
    /// ``ISO_8825.DER.Parseable/init(derEncoded:)-7tumk`` on `T`.
    ///
    /// - parameters:
    ///     - nodes: The ``ISO_8825.Node.Collection/Iterator`` to parse this element out of.
    ///     - identifier: The implicit tag. Defaults to the default tag for the element.
    ///     - defaultValue: The default value to use if there was no encoded value.
    ///
    /// - returns: The parsed element, if it was present, or the default if it was not.
    @inlinable
    public static func decodeDefault<T: ISO_8825.BER.Parseable & Equatable>(
        _ nodes: inout ISO_8825.Node.Collection.Iterator,
        identifier: ISO_8824.Identifier,
        defaultValue: T
    ) throws(ISO_8824.Error) -> T {
        return try Self.decodeDefault(&nodes, identifier: identifier, defaultValue: defaultValue) { (node: ISO_8825.Node) throws(ISO_8824.Error) -> T in
            try T(berEncoded: node)
        }
    }

    /// Parses a value that is encoded with a DEFAULT.
    ///
    /// Such a value is optional, and if absent will be replaced with its default. This function is
    /// a helper wrapper for ``decodeDefault(_:identifier:defaultValue:_:)`` that automatically invokes
    /// ``ISO_8825.DER.ImplicitlyTaggable/init(derEncoded:withIdentifier:)-7e88k`` on `T` using ``ISO_8825.DER.ImplicitlyTaggable/defaultIdentifier``.
    ///
    /// - parameters:
    ///     - nodes: The ``ISO_8825.Node.Collection/Iterator`` to parse this element out of.
    ///     - defaultValue: The default value to use if there was no encoded value.
    ///
    /// - returns: The parsed element, if it was present, or the default if it was not.
    @inlinable
    public static func decodeDefault<T: ISO_8825.BER.ImplicitlyTaggable & Equatable>(
        _ nodes: inout ISO_8825.Node.Collection.Iterator,
        defaultValue: T
    ) throws(ISO_8824.Error) -> T {
        return try Self.decodeDefault(&nodes, identifier: T.defaultIdentifier, defaultValue: defaultValue)
    }

    /// Parses a value that is encoded with a DEFAULT and an explicit tag.
    ///
    /// Such a value is optional, and if absent will be replaced with its default.
    ///
    /// - parameters:
    ///     - nodes: The ``ISO_8825.Node.Collection/Iterator`` to parse this element out of.
    ///     - tagNumber: The number of the explicit tag.
    ///     - tagClass: The class of the explicit tag.
    ///     - defaultValue: The default value to use if there was no encoded value.
    ///     - builder: A closure that will be called with the node for the element, if the element is present.
    ///
    /// - returns: The parsed element, if it was present, or the default if it was not.
    @inlinable
    public static func decodeDefaultExplicitlyTagged<T: ISO_8825.BER.Parseable & Equatable>(
        _ nodes: inout ISO_8825.Node.Collection.Iterator,
        tagNumber: UInt,
        tagClass: ISO_8824.Identifier.Class,
        defaultValue: T,
        _ builder: (ISO_8825.Node) throws(ISO_8824.Error) -> T
    ) throws(ISO_8824.Error) -> T {
        guard let result = try optionalExplicitlyTagged(&nodes, tagNumber: tagNumber, tagClass: tagClass, builder)
        else {
            return defaultValue
        }
        // BER allows explcitly default encoded
        return result
    }

    /// Parses a value that is encoded with a DEFAULT and an explicit tag.
    ///
    /// Such a value is optional, and if absent will be replaced with its default. This function is
    /// a helper wrapper for ``decodeDefaultExplicitlyTagged(_:tagNumber:tagClass:defaultValue:_:)`` that automatically invokes
    /// ``ISO_8825.DER.Parseable/init(derEncoded:)-7tumk`` on `T`.
    ///
    /// - parameters:
    ///     - nodes: The ``ISO_8825.Node.Collection/Iterator`` to parse this element out of.
    ///     - tagNumber: The number of the explicit tag.
    ///     - tagClass: The class of the explicit tag.
    ///     - defaultValue: The default value to use if there was no encoded value.
    ///
    /// - returns: The parsed element, if it was present, or the default if it was not.
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

// MARK: - Ordinary, explicit tagging
extension ISO_8825.BER {
    /// Parses an explicitly tagged element.
    ///
    /// - parameters:
    ///     - nodes: The ``ISO_8825.Node.Collection/Iterator`` to parse this element out of.
    ///     - tagNumber: The number of the explicit tag.
    ///     - tagClass: The class of the explicit tag.
    ///     - builder: A closure that will be called with the node for the element.
    ///
    /// - returns: The result of `builder`.
    @inlinable
    public static func explicitlyTagged<T>(
        _ nodes: inout ISO_8825.Node.Collection.Iterator,
        tagNumber: UInt,
        tagClass: ISO_8824.Identifier.Class,
        _ builder: (ISO_8825.Node) throws(ISO_8824.Error) -> T
    ) throws(ISO_8824.Error) -> T {
        return try ISO_8825.DER.explicitlyTagged(&nodes, tagNumber: tagNumber, tagClass: tagClass, builder)
    }

    /// Parses an explicitly tagged element.
    ///
    /// - parameters:
    ///     - node: The ``ISO_8825.Node`` to parse this element out of.
    ///     - tagNumber: The number of the explicit tag.
    ///     - tagClass: The class of the explicit tag.
    ///     - builder: A closure that will be called with the node for the element.
    ///
    /// - returns: The result of `builder`.
    @inlinable
    public static func explicitlyTagged<T>(
        _ node: ISO_8825.Node,
        tagNumber: UInt,
        tagClass: ISO_8824.Identifier.Class,
        _ builder: (ISO_8825.Node) throws(ISO_8824.Error) -> T
    ) throws(ISO_8824.Error) -> T {
        let expectedNodeID = ISO_8824.Identifier(tagWithNumber: tagNumber, tagClass: tagClass)
        guard node.identifier == expectedNodeID else {
            // Node is a mismatch, with the wrong tag.
            throw ISO_8824.Error.unexpectedFieldType(node.identifier)
        }

        // We expect a single child.
        guard case .constructed(let nodes) = node.content else {
            throw ISO_8824.Error.invalidASN1Object(reason: "Explicit tag \(expectedNodeID) for \(T.self) is primitive")
        }

        var nodeIterator = nodes.makeIterator()
        guard let child = nodeIterator.next(), nodeIterator.next() == nil else {
            throw ISO_8824.Error.invalidASN1Object(
                reason: "Invalid number of child nodes for explicit tag \(expectedNodeID) for \(T.self)"
            )
        }

        return try builder(child)
    }
}

// MARK: - Helpers

/// Defines a type that can be parsed from a BER-encoded form, which is a superset of DER.
///
/// Inherits the ISO_8825.DER.Parseable protocol.
///
/// Users implementing this type are expected to write the ASN.1 decoding code themselves. This approach is discussed in
/// depth in <doc:DecodingASN1>. When working with a type that may be implicitly tagged (which is most ASN.1 types),
/// users are recommended to implement ``ISO_8825.BER.ImplicitlyTaggable`` instead.
extension ISO_8825.BER {
    public protocol Parseable: ISO_8825.DER.Parseable {
        /// Initialize this object from a serialized BER representation.
        ///
        /// This function is invoked by the parser with the root node for the ASN.1 object. Implementers are
        /// expected to initialize themselves if possible, or to throw if they cannot.
        ///
        /// - parameters:
        ///     - node: The ASN.1 node representing this object.
        init(berEncoded node: ISO_8825.Node) throws(ISO_8824.Error)
    }
}

extension ISO_8825.BER.Parseable {

    /// By default, uses the underlying ISO_8825.DER.Parseable initializer.
    @inlinable
    public init(berEncoded node: ISO_8825.Node) throws(ISO_8824.Error) {
        self = try .init(derEncoded: node)
    }

    @inlinable
    public init(berEncoded sequenceNodeIterator: inout ISO_8825.Node.Collection.Iterator) throws(ISO_8824.Error) {
        guard let node = sequenceNodeIterator.next() else {
            throw ISO_8824.Error.invalidASN1Object(reason: "Unable to decode \(Self.self), no ASN.1 nodes to decode")
        }

        self = try .init(berEncoded: node)
    }

    /// Initialize this object from a serialized BER representation.
    ///
    /// - parameters:
    ///     - berEncoded: The BER-encoded bytes representing this object.
    @inlinable
    public init(berEncoded: [UInt8]) throws(ISO_8824.Error) {
        self = try .init(berEncoded: ISO_8825.BER.parse(berEncoded))
    }

    /// Initialize this object from a serialized BER representation.
    ///
    /// - parameters:
    ///     - berEncoded: The BER-encoded bytes representing this object.
    @inlinable
    public init(berEncoded: ArraySlice<UInt8>) throws(ISO_8824.Error) {
        self = try .init(berEncoded: ISO_8825.BER.parse(berEncoded))
    }
}

/// Defines a type that can be serialized in BER-encoded form.
///
/// Inherits from ISO_8825.DER.Serializable.
///
/// Since DER is a subset of BER, all DER-encoded objects are valid BER-encodings. In almost all cases DER is the preferred
/// form of serialization, and no BER-only constructs for serialization are supported.
///
/// Users implementing this type are expected to write the ASN.1 serialization code themselves. This approach is discussed in
/// depth in <doc:DecodingASN1>. When working with a type that may be implicitly tagged (which is most ASN.1 types),
/// users are recommended to implement ``ISO_8825.BER.ImplicitlyTaggable`` instead.
extension ISO_8825.BER {
    public protocol Serializable: ISO_8825.DER.Serializable {
    }
}

extension ISO_8825.BER {
    // -> naming judgment: `ImplicitlyTaggable` retained from upstream; see the
    //    matching note on ISO_8825.DER.ImplicitlyTaggable.
    public protocol ImplicitlyTaggable: ISO_8825.BER.Parseable, ISO_8825.BER.Serializable, ISO_8825.DER.ImplicitlyTaggable {
        /// The tag that the first node will use "by default" if the grammar omits
        /// any more specific tag definition.
        static var defaultIdentifier: ISO_8824.Identifier { get }

        /// Initialize this object from a serialized BER representation.
        ///
        /// This function is invoked by the parser with the root node for the ASN.1 object. Implementers are
        /// expected to initialize themselves if possible, or to throw if they cannot. The object is expected
        /// to use the identifier `identifier`.
        ///
        /// - parameters:
        ///     - berEncoded: The ASN.1 node representing this object.
        ///     - identifier: The ASN.1 identifier that `berEncoded` is expected to have.
        init(berEncoded: ISO_8825.Node, withIdentifier identifier: ISO_8824.Identifier) throws(ISO_8824.Error)
    }
}

extension ISO_8825.BER.ImplicitlyTaggable {
    /// Initialize this object as one element of a constructed ASN.1 object.
    ///
    /// This is a helper function for parsing constructed ASN.1 objects. It delegates all its functionality
    /// to ``ISO_8825.BER.ImplicitlyTaggable/init(berEncoded:withIdentifier:)``.
    ///
    /// - parameters:
    ///     - sequenceNodeIterator: The sequence of nodes that make up this object's parent. The first node in this collection
    ///         will be used to construct this object.
    ///     - identifier: The ASN.1 identifier that `berEncoded` is expected to have.
    @inlinable
    public init(
        berEncoded sequenceNodeIterator: inout ISO_8825.Node.Collection.Iterator,
        withIdentifier identifier: ISO_8824.Identifier = Self.defaultIdentifier
    ) throws(ISO_8824.Error) {
        guard let node = sequenceNodeIterator.next() else {
            throw ISO_8824.Error.invalidASN1Object(reason: "Unable to decode \(Self.self), no ASN.1 nodes to decode")
        }

        self = try .init(berEncoded: node, withIdentifier: identifier)
    }

    /// Initialize this object from a serialized BER representation.
    ///
    /// - parameters:
    ///     - berEncoded: The BER-encoded bytes representing this object.
    ///     - identifier: The ASN.1 identifier that `berEncoded` is expected to have.
    @inlinable
    public init(berEncoded: [UInt8], withIdentifier identifier: ISO_8824.Identifier = Self.defaultIdentifier) throws(ISO_8824.Error) {
        self = try .init(berEncoded: ISO_8825.BER.parse(berEncoded), withIdentifier: identifier)
    }

    /// Initialize this object from a serialized BER representation.
    ///
    /// - parameters:
    ///     - berEncoded: The DER-encoded bytes representing this object.
    ///     - identifier: The ASN.1 identifier that `berEncoded` is expected to have.
    @inlinable
    public init(
        berEncoded: ArraySlice<UInt8>,
        withIdentifier identifier: ISO_8824.Identifier = Self.defaultIdentifier
    ) throws(ISO_8824.Error) {
        self = try .init(berEncoded: ISO_8825.BER.parse(berEncoded), withIdentifier: identifier)
    }

    /// Initialize this object from a serialized BER representation.
    ///
    /// - parameters:
    ///     - berEncoded: The BER-encoded bytes representing this object.
    @inlinable
    public init(berEncoded: ISO_8825.Node) throws(ISO_8824.Error) {
        try self.init(berEncoded: berEncoded, withIdentifier: Self.defaultIdentifier)
    }
}
