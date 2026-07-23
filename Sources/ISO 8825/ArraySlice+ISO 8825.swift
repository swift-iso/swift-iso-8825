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

public import ISO_8824

// For temporary purposes we pretend that ArraySlice is our "bigint" type. We don't really need anything else.
extension ArraySlice: ISO_8825.DER.Serializable where Element == UInt8 {}

extension ArraySlice: ISO_8825.DER.Parseable where Element == UInt8 {}

extension ArraySlice: ISO_8825.DER.ImplicitlyTaggable where Element == UInt8 {}

extension ArraySlice: ISO_8825.BER.Serializable where Element == UInt8 {}

extension ArraySlice: ISO_8825.BER.Parseable where Element == UInt8 {}

extension ArraySlice: ISO_8825.BER.ImplicitlyTaggable where Element == UInt8 {}

// The value-facing base conformance ([API-IMPL-018]: cross-package protocol on a
// stdlib type → @retroactive).
extension ArraySlice: @retroactive ISO_8824.Integer.Representable where Element == UInt8 {
    // We only use unsigned "bigint"s
    @inlinable
    public static var isSigned: Bool {
        return false
    }

    @inlinable
    public func withBigEndianIntegerBytes<ReturnType, E: Swift.Error>(
        _ body: (ArraySlice<UInt8>) throws(E) -> ReturnType
    ) throws(E) -> ReturnType {
        return try body(self)
    }
}

// The codec-facing refinement conformance (protocol declared in this package —
// no @retroactive).
extension ArraySlice: ISO_8825.Integer.Representable where Element == UInt8 {
    @inlinable
    public init(derIntegerBytes: ArraySlice<UInt8>) throws(ISO_8824.Error) {
        self = derIntegerBytes
    }

    @inlinable
    public init(berIntegerBytes: ArraySlice<UInt8>) throws(ISO_8824.Error) {
        self = berIntegerBytes
    }
}
