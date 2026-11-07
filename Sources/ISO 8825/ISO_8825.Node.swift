public import ISO_8824


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
