public import ISO_8824


extension ISO_8825 {
    @usableFromInline
    struct TLV {

        @usableFromInline
        var identifier: ISO_8824.Identifier

        @usableFromInline
        var depth: Int

        @usableFromInline
        var isConstructed: Bool

        @usableFromInline
        var encodedBytes: ArraySlice<UInt8>

        @usableFromInline
        var dataBytes: ArraySlice<UInt8>?

        @inlinable
        init(
            identifier: ISO_8824.Identifier,
            depth: Int,
            isConstructed: Bool,
            encodedBytes: ArraySlice<UInt8>,
            dataBytes: ArraySlice<UInt8>? = nil
        ) {
            self.identifier = identifier
            self.depth = depth
            self.isConstructed = isConstructed
            self.encodedBytes = encodedBytes
            self.dataBytes = dataBytes
        }
    }
}
