public import ISO_8824


extension ISO_8825.DER {
    public protocol Parseable {

        init(derEncoded node: ISO_8825.Node) throws(ISO_8824.Error)
    }
}
