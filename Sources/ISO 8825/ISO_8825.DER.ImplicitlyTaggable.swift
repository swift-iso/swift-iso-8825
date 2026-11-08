public import ISO_8824


extension ISO_8825.DER {
    public protocol ImplicitlyTaggable: ISO_8825.DER.Parseable, ISO_8825.DER.Serializable {

        static var defaultIdentifier: ISO_8824.Identifier { get }

        init(
            derEncoded: ISO_8825.Node,
            withIdentifier identifier: ISO_8824.Identifier
        ) throws(ISO_8824.Error)

        func serialize(
            into coder: inout ISO_8825.DER.Serializer,
            withIdentifier identifier: ISO_8824.Identifier
        ) throws(ISO_8824.Error)
    }
}
