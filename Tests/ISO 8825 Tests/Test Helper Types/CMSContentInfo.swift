// ===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftASN1 open source project
//
// Copyright (c) 2023 Apple Inc. and the SwiftASN1 project authors
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

struct CMSContentInfo: ISO_8825.BER.ImplicitlyTaggable, ISO_8825.DER.ImplicitlyTaggable, Hashable {
    static var defaultIdentifier: ISO_8824.Identifier {
        .sequence
    }

    public var contentType: ISO_8824.ObjectIdentifier

    var content: ISO_8825.`Any`

    init(contentType: ISO_8824.ObjectIdentifier, content: ISO_8825.`Any`) {
        self.contentType = contentType
        self.content = content
    }

    init(derEncoded rootNode: ISO_8825.Node, withIdentifier identifier: ISO_8824.Identifier) throws(ISO_8824.Error) {
        self = try ISO_8825.DER.sequence(rootNode, identifier: Self.defaultIdentifier) { nodes throws(ISO_8824.Error) in
            let contentType = try ISO_8824.ObjectIdentifier(derEncoded: &nodes)
            let content = try ISO_8825.DER.explicitlyTagged(&nodes, tagNumber: 0, tagClass: .contextSpecific) { node throws(ISO_8824.Error) in
                ISO_8825.`Any`(derEncoded: node)
            }
            return .init(contentType: contentType, content: content)
        }
    }

    init(berEncoded rootNode: ISO_8825.Node, withIdentifier identifier: ISO_8824.Identifier) throws(ISO_8824.Error) {
        self = try ISO_8825.BER.sequence(rootNode, identifier: Self.defaultIdentifier) { nodes throws(ISO_8824.Error) in
            let contentType = try ISO_8824.ObjectIdentifier(derEncoded: &nodes)
            let content = try ISO_8825.BER.explicitlyTagged(&nodes, tagNumber: 0, tagClass: .contextSpecific) { node throws(ISO_8824.Error) in
                ISO_8825.`Any`(berEncoded: node)
            }
            return .init(contentType: contentType, content: content)
        }
    }

    func serialize(into coder: inout ISO_8825.DER.Serializer, withIdentifier identifier: ISO_8824.Identifier) throws(ISO_8824.Error) {
        try coder.appendConstructedNode(identifier: identifier) { coder throws(ISO_8824.Error) in
            try coder.serialize(contentType)
            try coder.serialize(content)
        }
    }
}
