public import ISO_8824

extension ISO_8825 {

    @usableFromInline
    enum Time {}
}

@available(*, unavailable)
extension ISO_8825.Time: Sendable {}

extension ISO_8825.Time {
    @inlinable
    static func generalizedTimeFromBytes(
        _ bytes: ArraySlice<UInt8>
    ) throws(ISO_8824.Error) -> ISO_8824.GeneralizedTime {
        var bytes = bytes

        guard let rawYear = bytes._readFourDigitDecimalInteger(),
            let rawMonth = bytes._readTwoDigitDecimalInteger(),
            let rawDay = bytes._readTwoDigitDecimalInteger()
        else {
            throw ISO_8824.Error.invalidASN1Object(
                reason: "Unable to load year, month, and day for GeneralizedTime"
            )
        }

        guard let rawHour = bytes._readTwoDigitDecimalInteger(),
            let rawMinutes = bytes._readTwoDigitDecimalInteger(),
            let rawSeconds = bytes._readTwoDigitDecimalInteger()
        else {
            throw ISO_8824.Error.invalidASN1Object(
                reason: "Unable to load hour, minutes, and seconds for GeneralizedTime"
            )
        }

        var rawFractionalSeconds = ArraySlice<UInt8>()
        if bytes.first == UInt8(ascii: ".") {
            bytes.removeFirst()
            rawFractionalSeconds = try bytes._readRawFractionalSeconds()
        }

        guard bytes.popFirst() == UInt8(ascii: "Z") else {
            throw ISO_8824.Error.invalidASN1Object(reason: "Invalid time zone in GeneralizedTime")
        }

        guard bytes.count == 0 else {
            throw ISO_8824.Error.invalidASN1Object(reason: "Trailing bytes in GeneralizedTime")
        }

        return try ISO_8824.GeneralizedTime(
            year: rawYear,
            month: rawMonth,
            day: rawDay,
            hours: rawHour,
            minutes: rawMinutes,
            seconds: rawSeconds,
            rawFractionalSeconds: rawFractionalSeconds
        )
    }

    @inlinable
    static func utcTimeFromBytes(
        _ bytes: ArraySlice<UInt8>
    ) throws(ISO_8824.Error) -> ISO_8824.UTCTime {
        var bytes = bytes

        guard let rawYear = bytes._readTwoDigitDecimalInteger(),
            let rawMonth = bytes._readTwoDigitDecimalInteger(),
            let rawDay = bytes._readTwoDigitDecimalInteger()
        else {
            throw ISO_8824.Error.invalidASN1Object(
                reason: "Unable to load year, month, and day for UTCTime"
            )
        }

        guard let rawHour = bytes._readTwoDigitDecimalInteger(),
            let rawMinutes = bytes._readTwoDigitDecimalInteger(),
            let rawSeconds = bytes._readTwoDigitDecimalInteger()
        else {
            throw ISO_8824.Error.invalidASN1Object(
                reason: "Unable to load hour, minutes, and seconds for UTCTime"
            )
        }

        guard bytes.popFirst() == UInt8(ascii: "Z") else {
            throw ISO_8824.Error.invalidASN1Object(reason: "Invalid time zone in UTCTime")
        }

        guard bytes.count == 0 else {
            throw ISO_8824.Error.invalidASN1Object(reason: "Trailing bytes in UTCTime")
        }

        let actualYear = rawYear < 50 ? rawYear &+ 2000 : rawYear &+ 1900

        return try ISO_8824.UTCTime(
            year: actualYear,
            month: rawMonth,
            day: rawDay,
            hours: rawHour,
            minutes: rawMinutes,
            seconds: rawSeconds
        )
    }
}

extension ArraySlice where Element == UInt8 {
    @inlinable
    package mutating func _readFourDigitDecimalInteger() -> Int? {
        guard let first = self._readTwoDigitDecimalInteger(),
            let second = self._readTwoDigitDecimalInteger()
        else {
            return nil
        }

        return (first &* 100) &+ second
    }

    @inlinable
    package mutating func _readTwoDigitDecimalInteger() -> Int? {
        guard let firstASCII = self.popFirst(),
            let secondASCII = self.popFirst()
        else {
            return nil
        }

        guard let first = Int(fromDecimalASCII: firstASCII),
            let second = Int(fromDecimalASCII: secondASCII)
        else {
            return nil
        }

        return (first &* 10) &+ (second)
    }

    @inlinable
    package mutating func _readRawFractionalSeconds() throws(ISO_8824.Error) -> ArraySlice<UInt8> {
        guard
            let nonDecimalASCIIIndex = self.firstIndex(where: { Int(fromDecimalASCII: $0) == nil })
        else {
            throw ISO_8824.Error.invalidASN1Object(
                reason: "Invalid fractional seconds"
            )
        }

        if nonDecimalASCIIIndex == self.startIndex {
            throw ISO_8824.Error.invalidASN1Object(
                reason: "Invalid fractional seconds"
            )
        }

        let rawFractionalSeconds = self[..<nonDecimalASCIIIndex]
        self = self[nonDecimalASCIIIndex...]
        return rawFractionalSeconds
    }
}

extension Array where Element == UInt8 {
    @inlinable
    package mutating func append(_ generalizedTime: ISO_8824.GeneralizedTime) {
        self._appendFourDigitDecimal(generalizedTime.year)
        self._appendTwoDigitDecimal(generalizedTime.month)
        self._appendTwoDigitDecimal(generalizedTime.day)
        self._appendTwoDigitDecimal(generalizedTime.hours)
        self._appendTwoDigitDecimal(generalizedTime.minutes)
        self._appendTwoDigitDecimal(generalizedTime.seconds)

        if generalizedTime.rawFractionalSeconds.count > 0 {
            self.append(UInt8(ascii: "."))
            self.append(contentsOf: generalizedTime.rawFractionalSeconds)
        }

        self.append(UInt8(ascii: "Z"))
    }

    @inlinable
    package mutating func append(_ utcTime: ISO_8824.UTCTime) {
        precondition((1950..<2050).contains(utcTime.year))
        if utcTime.year >= 2000 {
            self._appendTwoDigitDecimal(utcTime.year &- 2000)
        } else {
            self._appendTwoDigitDecimal(utcTime.year &- 1900)
        }
        self._appendTwoDigitDecimal(utcTime.month)
        self._appendTwoDigitDecimal(utcTime.day)
        self._appendTwoDigitDecimal(utcTime.hours)
        self._appendTwoDigitDecimal(utcTime.minutes)
        self._appendTwoDigitDecimal(utcTime.seconds)
        self.append(UInt8(ascii: "Z"))
    }

    @inlinable
    package mutating func _appendFourDigitDecimal(_ number: Int) {
        assert(number >= 0 && number <= 9999)

        let asciiZero = UInt8(ascii: "0")
        self.append(UInt8(truncatingIfNeeded: (number / 1000) % 10) &+ asciiZero)
        self.append(UInt8(truncatingIfNeeded: (number / 100) % 10) &+ asciiZero)
        self.append(UInt8(truncatingIfNeeded: (number / 10) % 10) &+ asciiZero)
        self.append(UInt8(truncatingIfNeeded: number % 10) &+ asciiZero)
    }

    @inlinable
    package mutating func _appendTwoDigitDecimal(_ number: Int) {
        assert(number >= 0 && number <= 99)

        let asciiZero = UInt8(ascii: "0")
        self.append(UInt8(truncatingIfNeeded: (number / 10) % 10) &+ asciiZero)
        self.append(UInt8(truncatingIfNeeded: number % 10) &+ asciiZero)
    }
}

extension Int {
    @inlinable
    package init?(fromDecimalASCII ascii: UInt8) {
        let asciiZero = UInt8(ascii: "0")
        let zeroToNine = 0...9

        let converted = Int(ascii) &- Int(asciiZero)

        guard zeroToNine.contains(converted) else {
            return nil
        }

        self = converted
    }
}
