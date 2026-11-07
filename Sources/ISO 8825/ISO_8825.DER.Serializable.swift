public import ISO_8824


extension ISO_8825.DER {
    public protocol Serializable {

        func serialize(into coder: inout ISO_8825.DER.Serializer) throws(ISO_8824.Error)
    }
}
