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

/// ISO/IEC 8825-1 | ITU-T X.690 — ASN.1 encoding rules.
///
/// ``ISO_8825`` is the namespace for the X.690 transfer syntaxes: the Basic
/// Encoding Rules (BER) and the Distinguished Encoding Rules (DER), together
/// with the TLV wire vocabulary (X.690 §8) they share.
///
/// The abstract-syntax value types (BIT STRING, OCTET STRING, OBJECT
/// IDENTIFIER, the character strings, and the times) live in `ISO_8824`
/// (X.680); this module supplies their wire conformances retroactively.
public enum ISO_8825 {}

@available(*, unavailable)
extension ISO_8825: Sendable {}
