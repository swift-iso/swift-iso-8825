import ISO_8824


extension ArraySlice where Element == UInt8 {
    @usableFromInline
    package enum Length: Sendable {
        case indefinite
        case definite(_: UInt)
    }
}
