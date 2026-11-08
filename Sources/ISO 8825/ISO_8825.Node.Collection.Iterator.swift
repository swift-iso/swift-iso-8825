public import ISO_8824


extension ISO_8825.Node.Collection: Swift.Sequence {
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
                guard let dataBytes = nextNode.dataBytes else {
                    preconditionFailure("A primitive TLV always carries its data bytes")
                }
                return ISO_8825.Node(
                    identifier: nextNode.identifier,
                    content: .primitive(dataBytes),
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
}
