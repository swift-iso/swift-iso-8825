public import ISO_8824


extension ISO_8825.BER {
    public protocol ImplicitlyTaggable: ISO_8825.BER.Parseable, ISO_8825.BER.Serializable, ISO_8825
            .DER.ImplicitlyTaggable
    {

        static var defaultIdentifier: ISO_8824.Identifier { get }

        init(
            berEncoded: ISO_8825.Node,
            withIdentifier identifier: ISO_8824.Identifier
        ) throws(ISO_8824.Error)
    }
}
