// ===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftASN1 open source project
//
// Copyright (c) 2019-2020 Apple Inc. and the SwiftASN1 project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftASN1 project authors
//
// SPDX-License-Identifier: Apache-2.0
//
// ===----------------------------------------------------------------------===//

public import ISO_8824

extension ISO_8825 {
    /// ``ISO_8825/DER`` defines a namespace that is used to store a number of helper methods and types
    /// for DER encoding and decoding.
    public enum DER {}
}

@available(*, unavailable)
extension ISO_8825.DER: Sendable {}

// MARK: - Sequence, SequenceOf, Set and SetOf
extension ISO_8825.DER {
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
    public static func sequence<T: ISO_8825.DER.Parseable>(
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
    public static func set<T: ISO_8825.DER.Parseable>(
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

// MARK: - LazySetOfSequence

extension ISO_8825.DER {
    public typealias LazySetOfSequence = ISO_8825.LazySetOfSequence
}

// MARK: - Optional explicitly tagged
extension ISO_8825.DER {
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
        var localNodesCopy = nodes
        guard let node = localNodesCopy.next() else {
            // Node not present, return nil.
            return nil
        }

        let expectedNodeID = ISO_8824.Identifier(tagWithNumber: tagNumber, tagClass: tagClass)
        //        assert(expectedNodeID.constructed)
        guard node.identifier == expectedNodeID else {
            // Node is a mismatch, with the wrong tag. Our optional isn't present.
            return nil
        }

        // We have the right optional, so let's consume it.
        nodes = localNodesCopy

        // We expect a single child.
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

// MARK: - Optional implicitly tagged
extension ISO_8825.DER {
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
        var localNodesCopy = nodes
        guard let node = localNodesCopy.next() else {
            // Node not present, return nil.
            return nil
        }

        let expectedNodeID = ISO_8824.Identifier(tagWithNumber: tagNumber, tagClass: tagClass)
        guard node.identifier == expectedNodeID else {
            // Node is a mismatch, with the wrong tag. Our optional isn't present.
            return nil
        }

        // We have the right optional, so let's consume it.
        nodes = localNodesCopy

        // We're good: pass the node on.
        return try builder(node)
    }
}

// MARK: - DEFAULT
extension ISO_8825.DER {
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
    public static func decodeDefault<T: ISO_8825.DER.Parseable & Equatable>(
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

        // DER forbids encoding DEFAULT values at their default state.
        // We can lift this in BER.
        guard parsed != defaultValue else {
            throw ISO_8824.Error.invalidASN1Object(
                reason:
                    "DEFAULT for \(T.self) with identifier \(identifier) present in DER but encoded at default value \(defaultValue)"
            )
        }

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
            // DER forbids encoding DEFAULT values at their default state.
            // We can lift this in BER.
            throw ISO_8824.Error.invalidASN1Object(
                reason:
                    "DEFAULT for \(T.self) with tag number \(tagNumber) and class \(tagClass) present in DER but encoded at default value \(defaultValue)"
            )
        }

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

// MARK: - Ordinary, explicit tagging
extension ISO_8825.DER {
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
        guard let node = nodes.next() else {
            // Node not present, throw.
            throw ISO_8824.Error.invalidASN1Object(
                reason:
                    "Explicitly tagged node for \(T.self) with tag number \(tagNumber) and class \(tagClass) not present"
            )
        }

        return try self.explicitlyTagged(node, tagNumber: tagNumber, tagClass: tagClass, builder)
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

// MARK: - Parsing
extension ISO_8825.DER {
    /// Parses an array of bytes as DER-encoded ASN.1 bytes.
    ///
    /// This function does not produce a complete decoded representation. Instead it produces a tree of ``ISO_8825.Node`` objects,
    /// each representing a single ASN.1 object. The leaves of the tree are primitive ASN.1 objects, and the intermediate nodes are
    /// constructed.
    ///
    /// In general this function is not called by users directly. Prefer using ``ISO_8825.DER.Parseable/init(derEncoded:)-i2rf``, which encapsulates
    /// the use of this function and immediately returns a strongly typed, fully-parsed object.
    ///
    /// - parameters:
    ///     - data: The DER-encoded bytes to parse.
    /// - returns: The root node in the ASN.1 tree.
    @inlinable
    public static func parse(_ data: [UInt8]) throws(ISO_8824.Error) -> ISO_8825.Node {
        return try parse(data[...])
    }

    /// Parses an array of bytes as DER-encoded ASN.1 bytes.
    ///
    /// This function does not produce a complete decoded representation. Instead it produces a tree of ``ISO_8825.Node`` objects,
    /// each representing a single ASN.1 object. The leaves of the tree are primitive ASN.1 objects, and the intermediate nodes are
    /// constructed.
    ///
    /// In general this function is not called by users directly. Prefer using ``ISO_8825.DER.Parseable/init(derEncoded:)-8yeds``, which encapsulates
    /// the use of this function and immediately returns a strongly typed, fully-parsed object.
    ///
    /// - parameters:
    ///     - data: The DER-encoded bytes to parse.
    /// - returns: The root node in the ASN.1 tree.
    @inlinable
    public static func parse(_ data: ArraySlice<UInt8>) throws(ISO_8824.Error) -> ISO_8825.Node {
        var result = try ISO_8825.TLV.Parser.parse(data, encoding: .distinguished)

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

        precondition(
            result.nodes.count == 0,
            "ISO_8825.TLV.Parser unexpectedly allowed multiple root nodes"
        )

        return rootNode
    }
}

// MARK: - Serializing
extension ISO_8825.DER {
    /// An object that can serialize ASN.1 bytes.
    ///
    /// ``Serializer`` is a copy-on-write value type.
    public struct Serializer: Sendable {
        @usableFromInline
        var _serializedBytes: [UInt8]

        // -> Byte discipline: [UInt8] output substrate retained pending a compile-gated
        //    [API-BYTE-004] migration (serializer mixes byte writes with length
        //    arithmetic); judgment deferred to the lead.
        /// The bytes that have been serialized by this serializer.
        @inlinable
        public var serializedBytes: [UInt8] {
            self._serializedBytes
        }

        /// Construct a new serializer.
        @inlinable
        public init() {
            // We allocate a 1kB array because that should cover us most of the time.
            self._serializedBytes = []
            self._serializedBytes.reserveCapacity(1024)
        }

        /// Appends a single, non-constructed node to the content.
        ///
        /// This is a low-level operation that can be used to implement primitive ASN.1 types.
        ///
        /// - parameters:
        ///      - identifier: The tag for this ASN.1 node
        ///      - contentWriter: A callback that will be invoked that allows users to write their bytes into the output stream.
        @inlinable
        public mutating func appendPrimitiveNode<E: Swift.Error>(
            identifier: ISO_8824.Identifier,
            _ contentWriter: (inout [UInt8]) throws(E) -> Void
        ) throws(E) {
            try self._appendNode(identifier: identifier, constructed: false) {
                (serializer: inout Serializer) throws(E) in
                try contentWriter(&serializer._serializedBytes)
            }
        }

        /// Appends a single constructed node to the content.
        ///
        /// This is an operation that can be used to implement constructed ASN.1 types. Most ASN.1 types are sequences and rely on using this function
        /// to append their SEQUENCE node.
        ///
        /// - parameters:
        ///      - identifier: The tag for this ASN.1 node
        ///      - contentWriter: A callback that will be invoked that allows users to write the objects contained within this constructed node.
        @inlinable
        public mutating func appendConstructedNode<E: Swift.Error>(
            identifier: ISO_8824.Identifier,
            _ contentWriter: (inout Serializer) throws(E) -> Void
        ) throws(E) {
            try self._appendNode(identifier: identifier, constructed: true, contentWriter)
        }

        /// Serializes a single node to the end of the byte stream.
        ///
        /// - parameters:
        ///     node: The node to be serialized.
        @inlinable
        public mutating func serialize<T: ISO_8825.DER.Serializable>(
            _ node: T
        ) throws(ISO_8824.Error) {
            try node.serialize(into: &self)
        }

        /// Serializes a single node to the end of the byte stream with an explicit ASN.1 tag.
        ///
        /// This is a wrapper for ``DER/Serializer/serialize(_:explicitlyTaggedWithIdentifier:)`` that builds the ASN.1 tag
        /// automatically.
        ///
        /// - parameters:
        ///     node: The node to be serialized.
        ///     tagNumber: The number of the explicit tag.
        ///     tagClass: The number of the explicit tag.
        @inlinable
        public mutating func serialize<T: ISO_8825.DER.Serializable>(
            _ node: T,
            explicitlyTaggedWithTagNumber tagNumber: UInt,
            tagClass: ISO_8824.Identifier.Class
        ) throws(ISO_8824.Error) {
            let identifier = ISO_8824.Identifier(tagWithNumber: tagNumber, tagClass: tagClass)
            return try self.serialize(node, explicitlyTaggedWithIdentifier: identifier)
        }

        /// Serializes a single node to the end of the byte stream with an explicit ASN.1 tag.
        ///
        /// - parameters:
        ///     node: The node to be serialized.
        ///     identifier: The explicit ASN.1 tag to apply.
        @inlinable
        public mutating func serialize<T: ISO_8825.DER.Serializable>(
            _ node: T,
            explicitlyTaggedWithIdentifier identifier: ISO_8824.Identifier
        ) throws(ISO_8824.Error) {
            try self.appendConstructedNode(identifier: identifier) {
                (coder: inout Serializer) throws(ISO_8824.Error) in
                try coder.serialize(node)
            }
        }

        /// Serializes a single optional node to the end of the byte stream with an implicit ASN.1 tag.
        ///
        /// If the node is `nil`, nothing is appended to the stream.
        ///
        /// The node is appended with its default tag.
        ///
        /// - parameters:
        ///     node: The node to be serialized.
        @inlinable
        public mutating func serializeOptionalImplicitlyTagged<T: ISO_8825.DER.Serializable>(
            _ node: T?
        ) throws(ISO_8824.Error) {
            if let node {
                try self.serialize(node)
            }
        }

        /// Serializes a single optional node to the end of the byte stream with an implicit ASN.1 tag.
        ///
        /// If the node is `nil`, nothing is appended to the stream.
        ///
        /// - parameters:
        ///     node: The node to be serialized.
        ///     identifier: The implicit ASN.1 tag to apply.
        @inlinable
        public mutating func serializeOptionalImplicitlyTagged<T: ISO_8825.DER.ImplicitlyTaggable>(
            _ node: T?,
            withIdentifier identifier: ISO_8824.Identifier
        ) throws(ISO_8824.Error) {
            if let node {
                try node.serialize(into: &self, withIdentifier: identifier)
            }
        }

        /// Serializes an explicit ASN.1 tag using a custom builder to store the elements of the explicitly tagged node.
        ///
        /// This is a helper version of ``DER/Serializer/serialize(_:explicitlyTaggedWithTagNumber:tagClass:)`` that allows users to avoid defining an object for the
        /// explicit node.
        ///
        /// - parameters:
        ///     tagNumber: The number of the explicit tag.
        ///     tagClass: The number of the explicit tag.
        ///     block: The block that will be invoked to encode the contents of the explicit tag.
        @inlinable
        public mutating func serialize<E: Swift.Error>(
            explicitlyTaggedWithTagNumber tagNumber: UInt,
            tagClass: ISO_8824.Identifier.Class,
            _ block: (inout Serializer) throws(E) -> Void
        ) throws(E) {
            let identifier = ISO_8824.Identifier(tagWithNumber: tagNumber, tagClass: tagClass)
            try self.appendConstructedNode(identifier: identifier) {
                (coder: inout Serializer) throws(E) in
                try block(&coder)
            }
        }

        /// Serializes a SEQUENCE OF ASN.1 nodes.
        ///
        /// - parameters:
        ///     - elements: The members of the ASN.1 SEQUENCE OF.
        ///     - identifier: The identifier to use for the SEQUENCE OF node. Defaults to ``ISO_8824.Identifier/sequence``.
        @inlinable
        public mutating func serializeSequenceOf<Elements: Sequence>(
            _ elements: Elements,
            identifier: ISO_8824.Identifier = .sequence
        ) throws(ISO_8824.Error) where Elements.Element: ISO_8825.DER.Serializable {
            try self.appendConstructedNode(identifier: identifier) {
                (coder: inout Serializer) throws(ISO_8824.Error) in
                for element in elements {
                    try coder.serialize(element)
                }
            }
        }

        /// Serializes a SET OF ASN.1 nodes.
        ///
        /// - parameters:
        ///     - elements: The members of the ASN.1 SET OF.
        ///     - identifier: The identifier to use for the SET OF node. Defaults to ``ISO_8824.Identifier/set``.
        @inlinable
        public mutating func serializeSetOf<Elements: Sequence>(
            _ elements: Elements,
            identifier: ISO_8824.Identifier = .set
        ) throws(ISO_8824.Error) where Elements.Element: ISO_8825.DER.Serializable {
            // We first serialize all elements into one intermediate Serializer and
            // create ArraySlices of their binary DER representation.
            var intermediateSerializer = ISO_8825.DER.Serializer()
            let serializedRanges = try elements.map {
                (element: Elements.Element) throws(ISO_8824.Error) -> Range<Int> in
                let startIndex = intermediateSerializer.serializedBytes.endIndex
                try intermediateSerializer.serialize(element)
                let endIndex = intermediateSerializer.serializedBytes.endIndex
                // It is important to first serialise all elements before we create `ArraySlice`s
                // as we otherwise trigger CoW of `intermediateSerializer.serializedBytes`.
                // We therefore just return a `Range` in the first iteration and
                // get `ArraySlice`s during the sort and write operations on demand.
                return startIndex..<endIndex
            }

            let serializedBytes = intermediateSerializer.serializedBytes
            // Afterwards we sort the binary representation of each element lexicographically
            let sortedRanges = serializedRanges.sorted { lhs, rhs in
                asn1SetElementLessThan(serializedBytes[lhs], serializedBytes[rhs])
            }
            // We then only need to create a constructed node and append the binary representation in their sorted order
            self.appendConstructedNode(identifier: identifier) { serializer in
                for range in sortedRanges {
                    serializer.serializeRawBytes(serializedBytes[range])
                }
            }
        }

        /// Serializes a parsed ASN.1 node directly.
        ///
        /// This is an extremely low-level helper function that can be used to re-serialize a parsed object when properly deserializing it was not
        /// practical.
        ///
        /// - parameters:
        ///     - node: The parsed node to serialize.
        @inlinable
        public mutating func serialize(_ node: ISO_8825.Node) {
            let identifier = node.identifier
            let constructed: Bool

            if case .constructed = node.content {
                constructed = true
            } else {
                constructed = false
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

        /// Serializes a sequence of raw bytes directly into the output stream.
        ///
        /// This is an extremely low-level helper function that can be used to serialize a parsed object exactly as it was deserialized.
        /// This can be used to enable perfect fidelity re-encoding where there are equally valid alternatives for serializing something
        /// and your code makes default choices.
        ///
        /// In general, users should avoid calling this function unless it's absolutely necessary to do so as a matter of implementation.
        ///
        /// Users are required to ensure that `bytes` is well-formed DER. Failure to do so will lead to invalid output being produced.
        ///
        /// - parameters:
        ///     - bytes: The raw bytes to serialize. These bytes must be well-formed DER.
        @inlinable
        public mutating func serializeRawBytes<Bytes: Sequence>(_ bytes: Bytes)
        where Bytes.Element == UInt8 {
            self._serializedBytes.append(contentsOf: bytes)
        }

        // This is the base logical function that all other append methods are built on. This one has most of the logic, and doesn't
        // police what we expect to happen in the content writer.
        @inlinable
        package mutating func _appendNode<E: Swift.Error>(
            identifier: ISO_8824.Identifier,
            constructed: Bool,
            _ contentWriter: (inout Serializer) throws(E) -> Void
        ) throws(E) {
            // This is a tricky game to play. We want to write the identifier and the length, but we don't know what the
            // length is here. To get around that, we _assume_ the length will be one byte, and let the writer write their content.
            // If it turns out to have been longer, we recalculate how many bytes we need and shuffle them in the buffer,
            // before updating the length. Most of the time we'll be right: occasionally we'll be wrong and have to shuffle.
            self._serializedBytes.writeIdentifier(identifier, constructed: constructed)

            // Write a zero for the length.
            self._serializedBytes.append(0)

            // Save the indices and write.
            let originalEndIndex = self._serializedBytes.endIndex
            let lengthIndex = self._serializedBytes.index(before: originalEndIndex)

            try contentWriter(&self)

            let contentLength = self._serializedBytes.distance(
                from: originalEndIndex,
                to: self._serializedBytes.endIndex
            )
            let lengthBytesNeeded = contentLength._bytesNeededToEncode
            if lengthBytesNeeded == 1 {
                // We can just set this at the top, and we're done!
                assert(contentLength <= 0x7F)
                self._serializedBytes[lengthIndex] = UInt8(contentLength)
                return
            }

            // Whoops, we need more than one byte to represent the length. That's annoying!
            // To sort this out we want to "move" the memory to the right.
            self._serializedBytes._moveRange(
                offset: lengthBytesNeeded - 1,
                range: originalEndIndex..<self._serializedBytes.endIndex
            )

            // Now we can write the length bytes back. We first write the number of length bytes
            // we needed, setting the high bit. Then we write the bytes of the length.
            self._serializedBytes[lengthIndex] = 0x80 | UInt8(lengthBytesNeeded - 1)
            var writeIndex = lengthIndex

            for shift in (0..<(lengthBytesNeeded - 1)).reversed() {
                // Shift and mask the integer.
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

// MARK: - Helpers

/// Defines a type that can be parsed from a DER-encoded form.
///
/// Users implementing this type are expected to write the ASN.1 decoding code themselves. This approach is discussed in
/// depth in <doc:DecodingASN1>. When working with a type that may be implicitly tagged (which is most ASN.1 types),
/// users are recommended to implement ``ISO_8825.DER.ImplicitlyTaggable`` instead.
extension ISO_8825.DER {
    public protocol Parseable {
        /// Initialize this object from a serialized DER representation.
        ///
        /// This function is invoked by the parser with the root node for the ASN.1 object. Implementers are
        /// expected to initialize themselves if possible, or to throw if they cannot.
        ///
        /// - parameters:
        ///     - node: The ASN.1 node representing this object.
        init(derEncoded node: ISO_8825.Node) throws(ISO_8824.Error)
    }
}

extension ISO_8825.DER.Parseable {
    /// Initialize this object as one element of a constructed ASN.1 object.
    ///
    /// This is a helper function for parsing constructed ASN.1 objects. It delegates all its functionality
    /// to ``ISO_8825.DER.Parseable/init(derEncoded:)-7tumk``.
    ///
    /// - parameters:
    ///     - sequenceNodeIterator: The sequence of nodes that make up this object's parent. The first node in this collection
    ///         will be used to construct this object.
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

    /// Initialize this object from a serialized DER representation.
    ///
    /// - parameters:
    ///     - derEncoded: The DER-encoded bytes representing this object.
    @inlinable
    public init(derEncoded: [UInt8]) throws(ISO_8824.Error) {
        self = try .init(derEncoded: ISO_8825.DER.parse(derEncoded))
    }

    /// Initialize this object from a serialized DER representation.
    ///
    /// - parameters:
    ///     - derEncoded: The DER-encoded bytes representing this object.
    @inlinable
    public init(derEncoded: ArraySlice<UInt8>) throws(ISO_8824.Error) {
        self = try .init(derEncoded: ISO_8825.DER.parse(derEncoded))
    }
}

/// Defines a type that can be serialized in DER-encoded form.
///
/// Users implementing this type are expected to write the ASN.1 serialization code themselves. This approach is discussed in
/// depth in <doc:DecodingASN1>. When working with a type that may be implicitly tagged (which is most ASN.1 types),
/// users are recommended to implement ``ISO_8825.DER.ImplicitlyTaggable`` instead.
extension ISO_8825.DER {
    public protocol Serializable {
        /// Serialize this object into DER-encoded ASN.1 form.
        ///
        /// - parameters:
        ///     - coder: A serializer to be used to encode the object.
        func serialize(into coder: inout ISO_8825.DER.Serializer) throws(ISO_8824.Error)
    }
}

/// An ASN.1 node that can tolerate having an implicit tag.
///
/// Implicit tags prevent the decoder from being able to work out what the actual type of the object
/// is, as they replace the tags. This means some objects cannot be implicitly tagged. In particular,
/// CHOICE elements without explicit tags cannot be implicitly tagged.
///
/// Objects that _can_ be implicitly tagged should prefer to implement this protocol in preference to
/// ``ISO_8825.DER.Serializable`` and ``ISO_8825.DER.Parseable``.
extension ISO_8825.DER {
    // -> naming judgment: `ImplicitlyTaggable` retained from upstream. IMPLICIT is
    //    X.680/X.690 spec vocabulary; the compound leaf is mechanically exempt at L2
    //    (Bundle.standards omits the compound rules) but flagged for principal review.
    public protocol ImplicitlyTaggable: ISO_8825.DER.Parseable, ISO_8825.DER.Serializable {
        /// The tag that the first node will use "by default" if the grammar omits
        /// any more specific tag definition.
        static var defaultIdentifier: ISO_8824.Identifier { get }

        /// Initialize this object from a serialized DER representation.
        ///
        /// This function is invoked by the parser with the root node for the ASN.1 object. Implementers are
        /// expected to initialize themselves if possible, or to throw if they cannot. The object is expected
        /// to use the identifier `identifier`.
        ///
        /// - parameters:
        ///     - derEncoded: The ASN.1 node representing this object.
        ///     - identifier: The ASN.1 identifier that `derEncoded` is expected to have.
        init(
            derEncoded: ISO_8825.Node,
            withIdentifier identifier: ISO_8824.Identifier
        ) throws(ISO_8824.Error)

        /// Serialize this object into DER-encoded ASN.1 form.
        ///
        /// - parameters:
        ///     - coder: A serializer to be used to encode the object.
        ///     - identifier: The ASN.1 identifier that this object should use to represent itself.
        func serialize(
            into coder: inout ISO_8825.DER.Serializer,
            withIdentifier identifier: ISO_8824.Identifier
        ) throws(ISO_8824.Error)
    }
}

extension ISO_8825.DER.ImplicitlyTaggable {
    /// Initialize this object as one element of a constructed ASN.1 object.
    ///
    /// This is a helper function for parsing constructed ASN.1 objects. It delegates all its functionality
    /// to ``ISO_8825.DER.ImplicitlyTaggable/init(derEncoded:withIdentifier:)-7e88k``.
    ///
    /// - parameters:
    ///     - sequenceNodeIterator: The sequence of nodes that make up this object's parent. The first node in this collection
    ///         will be used to construct this object.
    ///     - identifier: The ASN.1 identifier that `derEncoded` is expected to have.
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

    /// Initialize this object from a serialized DER representation.
    ///
    /// - parameters:
    ///     - derEncoded: The DER-encoded bytes representing this object.
    ///     - identifier: The ASN.1 identifier that `derEncoded` is expected to have.
    @inlinable
    public init(
        derEncoded: [UInt8],
        withIdentifier identifier: ISO_8824.Identifier = Self.defaultIdentifier
    ) throws(ISO_8824.Error) {
        self = try .init(derEncoded: ISO_8825.DER.parse(derEncoded), withIdentifier: identifier)
    }

    /// Initialize this object from a serialized DER representation.
    ///
    /// - parameters:
    ///     - derEncoded: The DER-encoded bytes representing this object.
    ///     - identifier: The ASN.1 identifier that `derEncoded` is expected to have.
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
