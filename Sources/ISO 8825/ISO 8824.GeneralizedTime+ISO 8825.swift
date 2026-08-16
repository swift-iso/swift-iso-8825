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

public import ISO_8824

// The X.690 §11.7 wire discipline for the X.680 GeneralizedTime value type.
// The calendar value law lives in ISO_8824; the YYYYMMDDHHMMSS[.f]Z
// content-octet codec (ISO_8825.Time) is X.690 wire law and is owned here.
//
// `defaultIdentifier` is declared publicly on the value type in ISO_8824 and
// witnesses the requirement from there; it is not re-declared in this extension.

extension ISO_8824.GeneralizedTime: ISO_8825.DER.ImplicitlyTaggable, ISO_8825.BER.ImplicitlyTaggable
{
    @inlinable
    public init(
        derEncoded node: ISO_8825.Node,
        withIdentifier identifier: ISO_8824.Identifier
    ) throws(ISO_8824.Error) {
        let content = try ISO_8824.OctetString(derEncoded: node, withIdentifier: identifier).bytes
        self = try ISO_8825.Time.generalizedTimeFromBytes(content)
    }

    @inlinable
    public init(
        berEncoded node: ISO_8825.Node,
        withIdentifier identifier: ISO_8824.Identifier
    ) throws(ISO_8824.Error) {
        // BER doesn't require the seconds to be present, and the time can be followed by a timezone offset. We don't support this at the moment.
        let content = try ISO_8824.OctetString(berEncoded: node, withIdentifier: identifier).bytes
        self = try ISO_8825.Time.generalizedTimeFromBytes(content)
    }

    @inlinable
    public func serialize(
        into coder: inout ISO_8825.DER.Serializer,
        withIdentifier identifier: ISO_8824.Identifier
    ) throws(ISO_8824.Error) {
        coder.appendPrimitiveNode(identifier: identifier) { bytes in
            bytes.append(self)
        }
    }
}
