import ISO_8824
import Testing

@testable import ISO_8825

extension ISO_8825.Integer {
    @Suite
    struct Test {}
}

extension ISO_8825.Integer.Test {
    @Test
    func `ArraySlice round-trips as INTEGER content bytes`() throws {

        let integerBytes: ArraySlice<UInt8> = [
            0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A,
        ]

        var serializer = ISO_8825.DER.Serializer()
        try serializer.serialize(integerBytes)
        #expect(serializer.serializedBytes == [0x02, 0x0A] + integerBytes)

        let parsed = try ISO_8825.DER.parse(serializer.serializedBytes)
        let roundTripped = try ArraySlice<UInt8>(derEncoded: parsed)
        #expect(roundTripped == integerBytes)
    }

    @Test
    func `ArraySlice INTEGER gains a leading zero octet when the top bit is set`() throws {

        let integerBytes: ArraySlice<UInt8> = [
            0xFF, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A,
        ]

        var serializer = ISO_8825.DER.Serializer()
        try serializer.serialize(integerBytes)
        #expect(serializer.serializedBytes == [0x02, 0x0B, 0x00] + integerBytes)

        let parsed = try ISO_8825.DER.parse(serializer.serializedBytes)
        let roundTripped = try ArraySlice<UInt8>(derEncoded: parsed)
        #expect(roundTripped == integerBytes)
    }
}
