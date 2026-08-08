// ===----------------------------------------------------------------------===//
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
// ===----------------------------------------------------------------------===//
import ISO_8824
import ISO_8825

// For PKCS#8 we need the following for the private key:
//
// PrivateKeyInfo ::= SEQUENCE {
//   version                   Version,
//   privateKeyAlgorithm       PrivateKeyAlgorithmIdentifier,
//   privateKey                PrivateKey,
//   attributes           [0]  IMPLICIT Attributes OPTIONAL }
//
// Version ::= INTEGER
//
// PrivateKeyAlgorithmIdentifier ::= AlgorithmIdentifier
//
// PrivateKey ::= OCTET STRING
//
// Attributes ::= SET OF Attribute
//
// We disregard the attributes because we don't support them anyway.
//
// For testing purposes we're supporting a very general version of this, which only contains a SEC1
// private key (i.e. an EC private key). In the wild, the PKCS8 key format can contain other keys,
// but for testing we don't care.
struct PKCS8PrivateKey: ISO_8825.DER.ImplicitlyTaggable {
    static var defaultIdentifier: ISO_8824.Identifier {
        return .sequence
    }

    var algorithm: RFC5480AlgorithmIdentifier

    var privateKey: SEC1PrivateKey

    init(derEncoded rootNode: ISO_8825.Node, withIdentifier identifier: ISO_8824.Identifier) throws(ISO_8824.Error) {
        self = try ISO_8825.DER.sequence(rootNode, identifier: identifier) { nodes throws(ISO_8824.Error) in
            let version = try Int(derEncoded: &nodes)
            guard version == 0 else {
                throw ISO_8824.Error.invalidASN1Object(reason: "Invalid version")
            }

            let algorithm = try RFC5480AlgorithmIdentifier(derEncoded: &nodes)
            let privateKeyBytes = try ISO_8824.OctetString(derEncoded: &nodes)

            // We ignore the attributes
            _ = try ISO_8825.DER.optionalExplicitlyTagged(&nodes, tagNumber: 0, tagClass: .contextSpecific) { _ in }

            let sec1PrivateKeyNode = try ISO_8825.DER.parse(privateKeyBytes.bytes)
            let sec1PrivateKey = try SEC1PrivateKey(derEncoded: sec1PrivateKeyNode)
            if let innerAlgorithm = sec1PrivateKey.algorithm, innerAlgorithm != algorithm {
                throw ISO_8824.Error.invalidASN1Object(reason: "Mismatched algorithms")
            }

            return try .init(algorithm: algorithm, privateKey: sec1PrivateKey)
        }
    }

    private init(algorithm: RFC5480AlgorithmIdentifier, privateKey: SEC1PrivateKey) throws(ISO_8824.Error) {
        self.privateKey = privateKey
        self.algorithm = algorithm
    }

    init(algorithm: RFC5480AlgorithmIdentifier, privateKey: [UInt8], publicKey: [UInt8]) {
        self.algorithm = algorithm

        // We nil out the private key here. I don't really know why we do this, but OpenSSL does, and it seems
        // safe enough to do: it certainly avoids the possibility of disagreeing on what it is!
        self.privateKey = SEC1PrivateKey(privateKey: privateKey, algorithm: nil, publicKey: publicKey)
    }

    func serialize(into coder: inout ISO_8825.DER.Serializer, withIdentifier identifier: ISO_8824.Identifier) throws(ISO_8824.Error) {
        try coder.appendConstructedNode(identifier: identifier) { coder throws(ISO_8824.Error) in
            try coder.serialize(0)  // version
            try coder.serialize(algorithm)

            // Here's a weird one: we recursively serialize the private key, and then turn the bytes into an octet string.
            var subCoder = ISO_8825.DER.Serializer()
            try subCoder.serialize(privateKey)
            let serializedKey = ISO_8824.OctetString(contentBytes: subCoder.serializedBytes[...])

            try coder.serialize(serializedKey)
        }
    }
}
