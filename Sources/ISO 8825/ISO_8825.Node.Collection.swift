import ISO_8824


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
