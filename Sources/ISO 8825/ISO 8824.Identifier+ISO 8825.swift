public import ISO_8824

extension ISO_8824.Identifier {

    @inlinable
    package var _shortForm: UInt8? {

        guard self.tagNumber < 0x1f else { return nil }

        var baseNumber = UInt8(truncatingIfNeeded: self.tagNumber)
        baseNumber |= self.tagClass._topByteFlags
        return baseNumber
    }

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

    @inlinable
    package mutating func writeIdentifier(_ identifier: ISO_8824.Identifier, constructed: Bool) {
        if var shortForm = identifier._shortForm {
            if constructed {
                shortForm |= 0x20
            }
            self.append(shortForm)
        } else {

            var topByte = UInt8(0x1f)
            if constructed {
                topByte |= 0x20
            }
            topByte |= identifier.tagClass._topByteFlags
            self.append(topByte)

            self.writeUsing7BitBytesASN1Discipline(unsignedInteger: identifier.tagNumber)
        }
    }
}
