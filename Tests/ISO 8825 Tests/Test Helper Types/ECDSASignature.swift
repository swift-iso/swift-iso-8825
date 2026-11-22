import ISO_8824
import ISO_8825

struct ECDSASignature<IntegerType: ISO.`8825`.Integer.Representable>: ISO.`8825`.DER.ImplicitlyTaggable {
    var r: IntegerType
    var s: IntegerType

    init(r: IntegerType, s: IntegerType) {
        self.r = r
        self.s = s
    }

    init(
        derEncoded rootNode: ISO.`8825`.Node,
        withIdentifier identifier: ISO.`8824`.Identifier
    ) throws(ISO.`8824`.Error) {
        self = try ISO.`8825`.DER.sequence(rootNode, identifier: identifier) {
            nodes throws(ISO.`8824`.Error) in
            let r = try IntegerType(derEncoded: &nodes)
            let s = try IntegerType(derEncoded: &nodes)

            return ECDSASignature(r: r, s: s)
        }
    }
}

extension ECDSASignature {
    static var defaultIdentifier: ISO.`8824`.Identifier {
        .sequence
    }

    func serialize(
        into coder: inout ISO.`8825`.DER.Serializer,
        withIdentifier identifier: ISO.`8824`.Identifier
    ) throws(ISO.`8824`.Error) {
        try coder.appendConstructedNode(identifier: identifier) { coder throws(ISO.`8824`.Error) in
            try coder.serialize(r)
            try coder.serialize(s)
        }
    }
}
