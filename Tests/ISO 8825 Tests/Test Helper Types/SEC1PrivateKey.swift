import ISO_8824
import ISO_8825

struct SEC1PrivateKey: ISO.`8825`.DER.ImplicitlyTaggable {
    var algorithm: RFC5480AlgorithmIdentifier?

    var privateKey: ISO.`8824`.OctetString

    var publicKey: ISO.`8824`.BitString?

    init(
        derEncoded rootNode: ISO.`8825`.Node,
        withIdentifier identifier: ISO.`8824`.Identifier
    ) throws(ISO.`8824`.Error) {
        self = try ISO.`8825`.DER.sequence(rootNode, identifier: identifier) {
            nodes throws(ISO.`8824`.Error) in
            let version = try Int(derEncoded: &nodes)
            guard 1 == version else {
                throw ISO.`8824`.Error.invalidASN1Object(reason: "Invalid version")
            }

            let privateKey = try ISO.`8824`.OctetString(derEncoded: &nodes)
            let parameters = try ISO.`8825`.DER.optionalExplicitlyTagged(
                &nodes,
                tagNumber: 0,
                tagClass: .contextSpecific
            ) { node throws(ISO.`8824`.Error) in
                return try ISO.`8824`.ObjectIdentifier(derEncoded: node)
            }
            let publicKey = try ISO.`8825`.DER.optionalExplicitlyTagged(
                &nodes,
                tagNumber: 1,
                tagClass: .contextSpecific
            ) { node throws(ISO.`8824`.Error) in
                return try ISO.`8824`.BitString(derEncoded: node)
            }

            return try .init(privateKey: privateKey, algorithm: parameters, publicKey: publicKey)
        }
    }

    private init(
        privateKey: ISO.`8824`.OctetString,
        algorithm: ISO.`8824`.ObjectIdentifier?,
        publicKey: ISO.`8824`.BitString?
    ) throws(ISO.`8824`.Error) {
        self.privateKey = privateKey
        self.publicKey = publicKey
        self.algorithm = try algorithm.map { algorithmOID throws(ISO.`8824`.Error) in
            switch algorithmOID {
            case ISO.`8824`.ObjectIdentifier.NamedCurves.secp256r1:
                return .ecdsaP256

            case ISO.`8824`.ObjectIdentifier.NamedCurves.secp384r1:
                return .ecdsaP384

            case ISO.`8824`.ObjectIdentifier.NamedCurves.secp521r1:
                return .ecdsaP521

            default:
                throw ISO.`8824`.Error.invalidASN1Object(reason: "Invalid algorithm ID")
            }
        }
    }

    init(privateKey: [UInt8], algorithm: RFC5480AlgorithmIdentifier?, publicKey: [UInt8]) {
        self.privateKey = ISO.`8824`.OctetString(contentBytes: privateKey[...])
        self.algorithm = algorithm

        do {
            self.publicKey = try ISO.`8824`.BitString(bytes: publicKey[...])
        } catch {
            preconditionFailure("Test public key bytes must form a valid bit string: \(error)")
        }
    }
}

extension SEC1PrivateKey {
    static var defaultIdentifier: ISO.`8824`.Identifier {
        return .sequence
    }

    func serialize(
        into coder: inout ISO.`8825`.DER.Serializer,
        withIdentifier identifier: ISO.`8824`.Identifier
    ) throws(ISO.`8824`.Error) {
        try coder.appendConstructedNode(identifier: identifier) { coder throws(ISO.`8824`.Error) in
            try coder.serialize(1)
            try coder.serialize(privateKey)

            if let algorithm {
                let oid: ISO.`8824`.ObjectIdentifier
                switch algorithm {
                case .ecdsaP256:
                    oid = ISO.`8824`.ObjectIdentifier.NamedCurves.secp256r1

                case .ecdsaP384:
                    oid = ISO.`8824`.ObjectIdentifier.NamedCurves.secp384r1

                case .ecdsaP521:
                    oid = ISO.`8824`.ObjectIdentifier.NamedCurves.secp521r1

                default:
                    throw ISO.`8824`.Error.invalidASN1Object(reason: "Unsupported algorithm")
                }

                try coder.serialize(
                    oid,
                    explicitlyTaggedWithTagNumber: 0,
                    tagClass: .contextSpecific
                )
            }

            if let publicKey {
                try coder.serialize(
                    publicKey,
                    explicitlyTaggedWithTagNumber: 1,
                    tagClass: .contextSpecific
                )
            }
        }
    }
}
