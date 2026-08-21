import ISO_8824
import ISO_8825

struct ECDSASignature<IntegerType: ISO_8825.Integer.Representable>: ISO_8825.DER.ImplicitlyTaggable
{
    static var defaultIdentifier: ISO_8824.Identifier {
        .sequence
    }

    var r: IntegerType
    var s: IntegerType

    init(r: IntegerType, s: IntegerType) {
        self.r = r
        self.s = s
    }

    init(
        derEncoded rootNode: ISO_8825.Node,
        withIdentifier identifier: ISO_8824.Identifier
    ) throws(ISO_8824.Error) {
        self = try ISO_8825.DER.sequence(rootNode, identifier: identifier) {
            nodes throws(ISO_8824.Error) in
            let r = try IntegerType(derEncoded: &nodes)
            let s = try IntegerType(derEncoded: &nodes)

            return ECDSASignature(r: r, s: s)
        }
    }

    func serialize(
        into coder: inout ISO_8825.DER.Serializer,
        withIdentifier identifier: ISO_8824.Identifier
    ) throws(ISO_8824.Error) {
        try coder.appendConstructedNode(identifier: identifier) { coder throws(ISO_8824.Error) in
            try coder.serialize(r)
            try coder.serialize(s)
        }
    }
}
