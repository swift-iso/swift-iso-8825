//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftASN1 open source project
//
// Copyright (c) 2021 Apple Inc. and the SwiftASN1 project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftASN1 project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

public import ISO_8824

// The X.690 wire discipline for the X.680 character-string value types
// (upstream ASN1Strings.swift). All of them encode as their raw bytes with a
// string-specific tag, so every conformance delegates to the OCTET STRING
// codec. The value law (byte storage, alphabet validation, String bridging)
// lives in ISO_8824; the validated types re-validate on decode through their
// public throwing `init(contentBytes:)`.
//
// Documented-extensions file: seven sibling conformance extensions for the
// seven string types ([API-IMPL-005] exception, mirroring the upstream file).
//
// `defaultIdentifier` is declared publicly on each value type in ISO_8824 and
// witnesses the requirement from there.

// MARK: - UTF8String

extension ISO_8824.UTF8String: ISO_8825.DER.ImplicitlyTaggable, ISO_8825.BER.ImplicitlyTaggable {
    @inlinable
    public init(derEncoded node: ISO_8825.Node, withIdentifier identifier: ISO_8824.Identifier) throws(ISO_8824.Error) {
        self.init(contentBytes: try ISO_8824.OctetString(derEncoded: node, withIdentifier: identifier).bytes)
    }

    @inlinable
    public init(berEncoded node: ISO_8825.Node, withIdentifier identifier: ISO_8824.Identifier) throws(ISO_8824.Error) {
        self.init(contentBytes: try ISO_8824.OctetString(berEncoded: node, withIdentifier: identifier).bytes)
    }

    @inlinable
    public func serialize(into coder: inout ISO_8825.DER.Serializer, withIdentifier identifier: ISO_8824.Identifier) throws(ISO_8824.Error) {
        let octet = ISO_8824.OctetString(contentBytes: self.bytes)
        try octet.serialize(into: &coder, withIdentifier: identifier)
    }
}

// MARK: - TeletexString

extension ISO_8824.TeletexString: ISO_8825.DER.ImplicitlyTaggable, ISO_8825.BER.ImplicitlyTaggable {
    @inlinable
    public init(derEncoded node: ISO_8825.Node, withIdentifier identifier: ISO_8824.Identifier) throws(ISO_8824.Error) {
        self.init(contentBytes: try ISO_8824.OctetString(derEncoded: node, withIdentifier: identifier).bytes)
    }

    @inlinable
    public init(berEncoded node: ISO_8825.Node, withIdentifier identifier: ISO_8824.Identifier) throws(ISO_8824.Error) {
        self.init(contentBytes: try ISO_8824.OctetString(berEncoded: node, withIdentifier: identifier).bytes)
    }

    @inlinable
    public func serialize(into coder: inout ISO_8825.DER.Serializer, withIdentifier identifier: ISO_8824.Identifier) throws(ISO_8824.Error) {
        let octet = ISO_8824.OctetString(contentBytes: self.bytes)
        try octet.serialize(into: &coder, withIdentifier: identifier)
    }
}

// MARK: - PrintableString

extension ISO_8824.PrintableString: ISO_8825.DER.ImplicitlyTaggable, ISO_8825.BER.ImplicitlyTaggable {
    @inlinable
    public init(derEncoded node: ISO_8825.Node, withIdentifier identifier: ISO_8824.Identifier) throws(ISO_8824.Error) {
        // The throwing value initializer re-validates the alphabet (value law in ISO_8824).
        self = try Self(contentBytes: ISO_8824.OctetString(derEncoded: node, withIdentifier: identifier).bytes)
    }

    @inlinable
    public init(berEncoded node: ISO_8825.Node, withIdentifier identifier: ISO_8824.Identifier) throws(ISO_8824.Error) {
        self = try Self(contentBytes: ISO_8824.OctetString(berEncoded: node, withIdentifier: identifier).bytes)
    }

    @inlinable
    public func serialize(into coder: inout ISO_8825.DER.Serializer, withIdentifier identifier: ISO_8824.Identifier) throws(ISO_8824.Error) {
        let octet = ISO_8824.OctetString(contentBytes: self.bytes)
        try octet.serialize(into: &coder, withIdentifier: identifier)
    }
}

// MARK: - VisibleString

extension ISO_8824.VisibleString: ISO_8825.DER.ImplicitlyTaggable, ISO_8825.BER.ImplicitlyTaggable {
    @inlinable
    public init(derEncoded node: ISO_8825.Node, withIdentifier identifier: ISO_8824.Identifier) throws(ISO_8824.Error) {
        self = try Self(contentBytes: ISO_8824.OctetString(derEncoded: node, withIdentifier: identifier).bytes)
    }

    @inlinable
    public init(berEncoded node: ISO_8825.Node, withIdentifier identifier: ISO_8824.Identifier) throws(ISO_8824.Error) {
        self = try Self(contentBytes: ISO_8824.OctetString(berEncoded: node, withIdentifier: identifier).bytes)
    }

    @inlinable
    public func serialize(into coder: inout ISO_8825.DER.Serializer, withIdentifier identifier: ISO_8824.Identifier) throws(ISO_8824.Error) {
        let octet = ISO_8824.OctetString(contentBytes: self.bytes)
        try octet.serialize(into: &coder, withIdentifier: identifier)
    }
}

// MARK: - UniversalString

extension ISO_8824.UniversalString: ISO_8825.DER.ImplicitlyTaggable, ISO_8825.BER.ImplicitlyTaggable {
    @inlinable
    public init(derEncoded node: ISO_8825.Node, withIdentifier identifier: ISO_8824.Identifier) throws(ISO_8824.Error) {
        self.init(contentBytes: try ISO_8824.OctetString(derEncoded: node, withIdentifier: identifier).bytes)
    }

    @inlinable
    public init(berEncoded node: ISO_8825.Node, withIdentifier identifier: ISO_8824.Identifier) throws(ISO_8824.Error) {
        self.init(contentBytes: try ISO_8824.OctetString(berEncoded: node, withIdentifier: identifier).bytes)
    }

    @inlinable
    public func serialize(into coder: inout ISO_8825.DER.Serializer, withIdentifier identifier: ISO_8824.Identifier) throws(ISO_8824.Error) {
        let octet = ISO_8824.OctetString(contentBytes: self.bytes)
        try octet.serialize(into: &coder, withIdentifier: identifier)
    }
}

// MARK: - BMPString

extension ISO_8824.BMPString: ISO_8825.DER.ImplicitlyTaggable, ISO_8825.BER.ImplicitlyTaggable {
    @inlinable
    public init(derEncoded node: ISO_8825.Node, withIdentifier identifier: ISO_8824.Identifier) throws(ISO_8824.Error) {
        self.init(contentBytes: try ISO_8824.OctetString(derEncoded: node, withIdentifier: identifier).bytes)
    }

    @inlinable
    public init(berEncoded node: ISO_8825.Node, withIdentifier identifier: ISO_8824.Identifier) throws(ISO_8824.Error) {
        self.init(contentBytes: try ISO_8824.OctetString(berEncoded: node, withIdentifier: identifier).bytes)
    }

    @inlinable
    public func serialize(into coder: inout ISO_8825.DER.Serializer, withIdentifier identifier: ISO_8824.Identifier) throws(ISO_8824.Error) {
        let octet = ISO_8824.OctetString(contentBytes: self.bytes)
        try octet.serialize(into: &coder, withIdentifier: identifier)
    }
}

// MARK: - IA5String

extension ISO_8824.IA5String: ISO_8825.DER.ImplicitlyTaggable, ISO_8825.BER.ImplicitlyTaggable {
    @inlinable
    public init(derEncoded node: ISO_8825.Node, withIdentifier identifier: ISO_8824.Identifier) throws(ISO_8824.Error) {
        self = try Self(contentBytes: ISO_8824.OctetString(derEncoded: node, withIdentifier: identifier).bytes)
    }

    @inlinable
    public init(berEncoded node: ISO_8825.Node, withIdentifier identifier: ISO_8824.Identifier) throws(ISO_8824.Error) {
        self = try Self(contentBytes: ISO_8824.OctetString(berEncoded: node, withIdentifier: identifier).bytes)
    }

    @inlinable
    public func serialize(into coder: inout ISO_8825.DER.Serializer, withIdentifier identifier: ISO_8824.Identifier) throws(ISO_8824.Error) {
        let octet = ISO_8824.OctetString(contentBytes: self.bytes)
        try octet.serialize(into: &coder, withIdentifier: identifier)
    }
}
