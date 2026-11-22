import ISO_8824
import ISO_8825

struct CMSContentInfo: ISO.`8825`.BER.ImplicitlyTaggable, ISO.`8825`.DER.ImplicitlyTaggable, Hashable {
    public var contentType: ISO.`8824`.ObjectIdentifier

    var content: ISO.`8825`.`Any`

    init(contentType: ISO.`8824`.ObjectIdentifier, content: ISO.`8825`.`Any`) {
        self.contentType = contentType
        self.content = content
    }

    init(
        derEncoded rootNode: ISO.`8825`.Node,
        withIdentifier identifier: ISO.`8824`.Identifier
    ) throws(ISO.`8824`.Error) {
        self = try ISO.`8825`.DER.sequence(rootNode, identifier: Self.defaultIdentifier) {
            nodes throws(ISO.`8824`.Error) in
            let contentType = try ISO.`8824`.ObjectIdentifier(derEncoded: &nodes)
            let content = try ISO.`8825`.DER.explicitlyTagged(
                &nodes,
                tagNumber: 0,
                tagClass: .contextSpecific
            ) { node throws(ISO.`8824`.Error) in
                ISO.`8825`.`Any`(derEncoded: node)
            }
            return .init(contentType: contentType, content: content)
        }
    }

    init(
        berEncoded rootNode: ISO.`8825`.Node,
        withIdentifier identifier: ISO.`8824`.Identifier
    ) throws(ISO.`8824`.Error) {
        self = try ISO.`8825`.BER.sequence(rootNode, identifier: Self.defaultIdentifier) {
            nodes throws(ISO.`8824`.Error) in
            let contentType = try ISO.`8824`.ObjectIdentifier(derEncoded: &nodes)
            let content = try ISO.`8825`.BER.explicitlyTagged(
                &nodes,
                tagNumber: 0,
                tagClass: .contextSpecific
            ) { node throws(ISO.`8824`.Error) in
                ISO.`8825`.`Any`(berEncoded: node)
            }
            return .init(contentType: contentType, content: content)
        }
    }
}

extension CMSContentInfo {
    static var defaultIdentifier: ISO.`8824`.Identifier {
        .sequence
    }

    func serialize(
        into coder: inout ISO.`8825`.DER.Serializer,
        withIdentifier identifier: ISO.`8824`.Identifier
    ) throws(ISO.`8824`.Error) {
        try coder.appendConstructedNode(identifier: identifier) { coder throws(ISO.`8824`.Error) in
            try coder.serialize(contentType)
            try coder.serialize(content)
        }
    }
}
