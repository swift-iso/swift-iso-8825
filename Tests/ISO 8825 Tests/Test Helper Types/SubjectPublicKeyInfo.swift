import ISO_8824
import ISO_8825

struct SubjectPublicKeyInfo: ISO.`8825`.DER.ImplicitlyTaggable, Hashable {
    var algorithmIdentifier: RFC5480AlgorithmIdentifier

    var key: ISO.`8824`.BitString

    init(
        derEncoded rootNode: ISO.`8825`.Node,
        withIdentifier identifier: ISO.`8824`.Identifier
    ) throws(ISO.`8824`.Error) {

        self = try ISO.`8825`.DER.sequence(rootNode, identifier: identifier) {
            nodes throws(ISO.`8824`.Error) in
            let algorithmIdentifier = try RFC5480AlgorithmIdentifier(derEncoded: &nodes)
            let key = try ISO.`8824`.BitString(derEncoded: &nodes)

            return SubjectPublicKeyInfo(algorithmIdentifier: algorithmIdentifier, key: key)
        }
    }

    private init(algorithmIdentifier: RFC5480AlgorithmIdentifier, key: ISO.`8824`.BitString) {
        self.algorithmIdentifier = algorithmIdentifier
        self.key = key
    }

    internal init(algorithmIdentifier: RFC5480AlgorithmIdentifier, key: [UInt8]) {
        self.algorithmIdentifier = algorithmIdentifier

        do {
            self.key = try ISO.`8824`.BitString(bytes: key[...])
        } catch {
            preconditionFailure("Test key bytes must form a valid bit string: \(error)")
        }
    }
}

extension SubjectPublicKeyInfo {
    static var defaultIdentifier: ISO.`8824`.Identifier {
        .sequence
    }

    func serialize(
        into coder: inout ISO.`8825`.DER.Serializer,
        withIdentifier identifier: ISO.`8824`.Identifier
    ) throws(ISO.`8824`.Error) {
        try coder.appendConstructedNode(identifier: identifier) { coder throws(ISO.`8824`.Error) in
            try coder.serialize(algorithmIdentifier)
            try coder.serialize(key)
        }
    }
}

struct RFC5480AlgorithmIdentifier: ISO.`8825`.DER.ImplicitlyTaggable, Hashable {
    var algorithm: ISO.`8824`.ObjectIdentifier

    var parameters: ISO.`8825`.`Any`?

    init(algorithm: ISO.`8824`.ObjectIdentifier, parameters: ISO.`8825`.`Any`?) {
        self.algorithm = algorithm
        self.parameters = parameters
    }

    init(
        derEncoded rootNode: ISO.`8825`.Node,
        withIdentifier identifier: ISO.`8824`.Identifier
    ) throws(ISO.`8824`.Error) {

        self = try ISO.`8825`.DER.sequence(rootNode, identifier: identifier) {
            nodes throws(ISO.`8824`.Error) in
            let algorithmOID = try ISO.`8824`.ObjectIdentifier(derEncoded: &nodes)

            let parameters = nodes.next().map { ISO.`8825`.`Any`(derEncoded: $0) }

            return .init(algorithm: algorithmOID, parameters: parameters)
        }
    }
}

extension RFC5480AlgorithmIdentifier {
    static var defaultIdentifier: ISO.`8824`.Identifier {
        .sequence
    }

    func serialize(
        into coder: inout ISO.`8825`.DER.Serializer,
        withIdentifier identifier: ISO.`8824`.Identifier
    ) throws(ISO.`8824`.Error) {
        try coder.appendConstructedNode(identifier: identifier) { coder throws(ISO.`8824`.Error) in
            try coder.serialize(algorithm)
            if let parameters {
                try coder.serialize(parameters)
            }
        }
    }
}

extension RFC5480AlgorithmIdentifier {

    private static func erasedCurve(_ curve: ISO.`8824`.ObjectIdentifier) -> ISO.`8825`.`Any` {
        do {
            return try ISO.`8825`.`Any`(erasing: curve)
        } catch {
            preconditionFailure("Named curve identifiers must be erasable: \(error)")
        }
    }

    static let ecdsaP256 = RFC5480AlgorithmIdentifier(
        algorithm: .AlgorithmIdentifier.idEcPublicKey,

        parameters: erasedCurve(ISO.`8824`.ObjectIdentifier.NamedCurves.secp256r1)
    )

    static let ecdsaP384 = RFC5480AlgorithmIdentifier(
        algorithm: .AlgorithmIdentifier.idEcPublicKey,

        parameters: erasedCurve(ISO.`8824`.ObjectIdentifier.NamedCurves.secp384r1)
    )

    static let ecdsaP521 = RFC5480AlgorithmIdentifier(
        algorithm: .AlgorithmIdentifier.idEcPublicKey,

        parameters: erasedCurve(ISO.`8824`.ObjectIdentifier.NamedCurves.secp521r1)
    )
}
