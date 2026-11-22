import ISO_8824
import ISO_8825

struct PKCS8PrivateKey: ISO.`8825`.DER.ImplicitlyTaggable {
    var algorithm: RFC5480AlgorithmIdentifier

    var privateKey: SEC1PrivateKey

    init(
        derEncoded rootNode: ISO.`8825`.Node,
        withIdentifier identifier: ISO.`8824`.Identifier
    ) throws(ISO.`8824`.Error) {
        self = try ISO.`8825`.DER.sequence(rootNode, identifier: identifier) {
            nodes throws(ISO.`8824`.Error) in
            let version = try Int(derEncoded: &nodes)
            guard version == 0 else {
                throw ISO.`8824`.Error.invalidASN1Object(reason: "Invalid version")
            }

            let algorithm = try RFC5480AlgorithmIdentifier(derEncoded: &nodes)
            let privateKeyBytes = try ISO.`8824`.OctetString(derEncoded: &nodes)

            _ = try ISO.`8825`.DER.optionalExplicitlyTagged(
                &nodes,
                tagNumber: 0,
                tagClass: .contextSpecific
            ) { _ in }

            let sec1PrivateKeyNode = try ISO.`8825`.DER.parse(privateKeyBytes.bytes)
            let sec1PrivateKey = try SEC1PrivateKey(derEncoded: sec1PrivateKeyNode)
            if let innerAlgorithm = sec1PrivateKey.algorithm, innerAlgorithm != algorithm {
                throw ISO.`8824`.Error.invalidASN1Object(reason: "Mismatched algorithms")
            }

            return try .init(algorithm: algorithm, privateKey: sec1PrivateKey)
        }
    }

    private init(
        algorithm: RFC5480AlgorithmIdentifier,
        privateKey: SEC1PrivateKey
    ) throws(ISO.`8824`.Error) {
        self.privateKey = privateKey
        self.algorithm = algorithm
    }

    init(algorithm: RFC5480AlgorithmIdentifier, privateKey: [UInt8], publicKey: [UInt8]) {
        self.algorithm = algorithm

        self.privateKey = SEC1PrivateKey(
            privateKey: privateKey,
            algorithm: nil,
            publicKey: publicKey
        )
    }
}

extension PKCS8PrivateKey {
    static var defaultIdentifier: ISO.`8824`.Identifier {
        return .sequence
    }

    func serialize(
        into coder: inout ISO.`8825`.DER.Serializer,
        withIdentifier identifier: ISO.`8824`.Identifier
    ) throws(ISO.`8824`.Error) {
        try coder.appendConstructedNode(identifier: identifier) { coder throws(ISO.`8824`.Error) in
            try coder.serialize(0)
            try coder.serialize(algorithm)

            var subCoder = ISO.`8825`.DER.Serializer()
            try subCoder.serialize(privateKey)
            let serializedKey = ISO.`8824`.OctetString(contentBytes: subCoder.serializedBytes[...])

            try coder.serialize(serializedKey)
        }
    }
}
