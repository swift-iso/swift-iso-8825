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

// The X.690 §8.1.2 identifier-octet wire discipline for the X.680 identifier
// value type. The abstract identifier (tag number + class) lives in ISO_8824;
// its short-form/long-form octet encoding is X.690 wire law and is owned here.
//
// -> ISO 8824 coordination: these helpers are derived exclusively from the
//    public `tagNumber` / `tagClass` surface and the public
//    `init(tagWithNumber:tagClass:)`; no internal 8824 access is required.

extension ISO_8824.Identifier {
    /// The short-form identifier octet for this identifier, if the tag number
    /// permits short-form encoding (X.690 §8.1.2.3).
    @inlinable
    package var _shortForm: UInt8? {
        // An ASN.1 identifier can be encoded in short form iff the tag number is strictly
        // less than 0x1f.
        guard self.tagNumber < 0x1f else { return nil }

        var baseNumber = UInt8(truncatingIfNeeded: self.tagNumber)
        baseNumber |= self.tagClass._topByteFlags
        return baseNumber
    }

    /// Decodes a short-form identifier octet (X.690 §8.1.2.3).
    @inlinable
    package init(shortIdentifier: UInt8) {
        precondition(shortIdentifier & 0x1F != 0x1F)
        self.init(
            tagWithNumber: UInt(shortIdentifier & 0x1f),
            tagClass: ISO_8824.Identifier.Class(topByteInWireFormat: shortIdentifier)
        )
    }
}

extension ISO_8824.Identifier.Class {
    /// Decodes the tag class from the leading identifier octet (X.690 §8.1.2.2).
    @inlinable
    package init(topByteInWireFormat topByte: UInt8) {
        switch topByte >> 6 {
        case 0x00:
            self = .universal
        case 0x01:
            self = .application
        case 0x02:
            self = .contextSpecific
        case 0x03:
            self = .private
        default:
            fatalError("Unreachable")
        }
    }

    /// The class bits of the leading identifier octet (X.690 §8.1.2.2).
    @inlinable
    package var _topByteFlags: UInt8 {
        switch self {
        case .universal:
            return 0x00
        case .application:
            return 0x01 << 6
        case .contextSpecific:
            return 0x02 << 6
        case .private:
            return 0x03 << 6
        }
    }
}

extension Array where Element == UInt8 {
    /// Appends the identifier octets for `identifier` (X.690 §8.1.2).
    @inlinable
    package mutating func writeIdentifier(_ identifier: ISO_8824.Identifier, constructed: Bool) {
        if var shortForm = identifier._shortForm {
            if constructed {
                shortForm |= 0x20
            }
            self.append(shortForm)
        } else {
            // Long-form encoded. The top byte is 0x1f plus the various flags.
            var topByte = UInt8(0x1f)
            if constructed {
                topByte |= 0x20
            }
            topByte |= identifier.tagClass._topByteFlags
            self.append(topByte)

            // Then we encode this in base128, just like an OID subidentifier.
            self.writeUsing7BitBytesASN1Discipline(unsignedInteger: identifier.tagNumber)
        }
    }
}
