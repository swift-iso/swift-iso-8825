public import ISO_8824


extension ISO_8825.Node {
    public enum Content: Hashable, Sendable {

        case constructed(ISO_8825.Node.Collection)

        case primitive(ArraySlice<UInt8>)
    }
}
