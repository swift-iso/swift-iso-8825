//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftASN1 open source project
//
// Copyright (c) 2019-2020 Apple Inc. and the SwiftASN1 project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftASN1 project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
import ISO_8824
import ISO_8825

struct SubjectPublicKeyInfo: ISO_8825.DER.ImplicitlyTaggable, Hashable {
    static var defaultIdentifier: ISO_8824.Identifier {
        .sequence
    }

    var algorithmIdentifier: RFC5480AlgorithmIdentifier

    var key: ISO_8824.BitString

    init(derEncoded rootNode: ISO_8825.Node, withIdentifier identifier: ISO_8824.Identifier) throws(ISO_8824.Error) {
        // The SPKI block looks like this:
        //
        // SubjectPublicKeyInfo  ::=  SEQUENCE  {
        //   algorithm         AlgorithmIdentifier,
        //   subjectPublicKey  BIT STRING
        // }
        self = try ISO_8825.DER.sequence(rootNode, identifier: identifier) { (nodes) throws(ISO_8824.Error) in
            let algorithmIdentifier = try RFC5480AlgorithmIdentifier(derEncoded: &nodes)
            let key = try ISO_8824.BitString(derEncoded: &nodes)

            return SubjectPublicKeyInfo(algorithmIdentifier: algorithmIdentifier, key: key)
        }
    }

    private init(algorithmIdentifier: RFC5480AlgorithmIdentifier, key: ISO_8824.BitString) {
        self.algorithmIdentifier = algorithmIdentifier
        self.key = key
    }

    internal init(algorithmIdentifier: RFC5480AlgorithmIdentifier, key: [UInt8]) {
        self.algorithmIdentifier = algorithmIdentifier
        self.key = ISO_8824.BitString(bytes: key[...])
    }

    func serialize(into coder: inout ISO_8825.DER.Serializer, withIdentifier identifier: ISO_8824.Identifier) throws(ISO_8824.Error) {
        try coder.appendConstructedNode(identifier: identifier) { (coder) throws(ISO_8824.Error) in
            try coder.serialize(self.algorithmIdentifier)
            try coder.serialize(self.key)
        }
    }
}

struct RFC5480AlgorithmIdentifier: ISO_8825.DER.ImplicitlyTaggable, Hashable {
    static var defaultIdentifier: ISO_8824.Identifier {
        .sequence
    }

    var algorithm: ISO_8824.ObjectIdentifier

    var parameters: ISO_8825.`Any`?

    init(algorithm: ISO_8824.ObjectIdentifier, parameters: ISO_8825.`Any`?) {
        self.algorithm = algorithm
        self.parameters = parameters
    }

    init(derEncoded rootNode: ISO_8825.Node, withIdentifier identifier: ISO_8824.Identifier) throws(ISO_8824.Error) {
        // The AlgorithmIdentifier block looks like this.
        //
        // AlgorithmIdentifier  ::=  SEQUENCE  {
        //   algorithm   OBJECT IDENTIFIER,
        //   parameters  ANY DEFINED BY algorithm OPTIONAL
        // }
        //
        // ECParameters ::= CHOICE {
        //   namedCurve         OBJECT IDENTIFIER
        //   -- implicitCurve   NULL
        //   -- specifiedCurve  SpecifiedECDomain
        // }
        //
        // We don't bother with helpers: we just try to decode it directly.
        self = try ISO_8825.DER.sequence(rootNode, identifier: identifier) { (nodes) throws(ISO_8824.Error) in
            let algorithmOID = try ISO_8824.ObjectIdentifier(derEncoded: &nodes)

            let parameters = nodes.next().map { ISO_8825.`Any`(derEncoded: $0) }

            return .init(algorithm: algorithmOID, parameters: parameters)
        }
    }

    func serialize(into coder: inout ISO_8825.DER.Serializer, withIdentifier identifier: ISO_8824.Identifier) throws(ISO_8824.Error) {
        try coder.appendConstructedNode(identifier: identifier) { (coder) throws(ISO_8824.Error) in
            try coder.serialize(self.algorithm)
            if let parameters = self.parameters {
                try coder.serialize(parameters)
            }
        }
    }
}

// MARK: Algorithm Identifier Statics
extension RFC5480AlgorithmIdentifier {
    static let ecdsaP256 = RFC5480AlgorithmIdentifier(
        algorithm: .AlgorithmIdentifier.idEcPublicKey,
        parameters: try! .init(erasing: ISO_8824.ObjectIdentifier.NamedCurves.secp256r1)
    )

    static let ecdsaP384 = RFC5480AlgorithmIdentifier(
        algorithm: .AlgorithmIdentifier.idEcPublicKey,
        parameters: try! .init(erasing: ISO_8824.ObjectIdentifier.NamedCurves.secp384r1)
    )

    static let ecdsaP521 = RFC5480AlgorithmIdentifier(
        algorithm: .AlgorithmIdentifier.idEcPublicKey,
        parameters: try! .init(erasing: ISO_8824.ObjectIdentifier.NamedCurves.secp521r1)
    )
}
