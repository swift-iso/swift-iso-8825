public import ISO_8824


extension ISO_8825.BER {
    public protocol Parseable: ISO_8825.DER.Parseable {

        init(berEncoded node: ISO_8825.Node) throws(ISO_8824.Error)
    }
}
