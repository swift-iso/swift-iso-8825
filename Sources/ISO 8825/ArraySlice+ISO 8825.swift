public import ISO_8824

extension ArraySlice: ISO_8825.DER.Serializable where Element == UInt8 {}

extension ArraySlice: ISO_8825.DER.Parseable where Element == UInt8 {}

extension ArraySlice: ISO_8825.DER.ImplicitlyTaggable where Element == UInt8 {}

extension ArraySlice: ISO_8825.BER.Serializable where Element == UInt8 {}

extension ArraySlice: ISO_8825.BER.Parseable where Element == UInt8 {}

extension ArraySlice: ISO_8825.BER.ImplicitlyTaggable where Element == UInt8 {}

extension ArraySlice: @retroactive ISO_8824.Integer.Representable where Element == UInt8 {

    @inlinable
    public static var isSigned: Bool {
        return false
    }

    @inlinable
    public func withBigEndianIntegerBytes<ReturnType, E: Swift.Error>(
        _ body: (ArraySlice<UInt8>) throws(E) -> ReturnType
    ) throws(E) -> ReturnType {
        return try body(self)
    }
}

extension ArraySlice: ISO_8825.Integer.Representable where Element == UInt8 {
    @inlinable
    public init(derIntegerBytes: ArraySlice<UInt8>) throws(ISO_8824.Error) {
        self = derIntegerBytes
    }

    @inlinable
    public init(berIntegerBytes: ArraySlice<UInt8>) throws(ISO_8824.Error) {
        self = berIntegerBytes
    }
}
