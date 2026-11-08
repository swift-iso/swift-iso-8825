public import ISO_8824


extension ISO_8825.Integer {
    public protocol Representable: ISO_8824.Integer.Representable, ISO_8825.DER.ImplicitlyTaggable,
        ISO_8825.BER.ImplicitlyTaggable
    {

        init(derIntegerBytes: ArraySlice<UInt8>) throws(ISO_8824.Error)

        init(berIntegerBytes: ArraySlice<UInt8>) throws(ISO_8824.Error)
    }
}
