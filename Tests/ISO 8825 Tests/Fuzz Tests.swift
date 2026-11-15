import ISO_8825
import Testing

struct Fuzzing: RandomNumberGenerator {
    var state: UInt64

    mutating func next() -> UInt64 {
        state &+= 0x9e37_79b9_7f4a_7c15
        var z = state
        z = (z ^ (z >> 30)) &* 0xbf58_476d_1ce4_e5b9
        z = (z ^ (z >> 27)) &* 0x94d0_49bb_1331_11eb
        return z ^ (z >> 31)
    }

    mutating func bytes(upTo limit: Int) -> [UInt8] {
        (0..<Int.random(in: 0...limit, using: &self)).map { _ in UInt8.random(in: .min ... .max, using: &self) }
    }
}

@Suite(.timeLimit(.minutes(1)))
struct `Fuzz Tests` {
    @Test
    func `random bytes are parsed or refused as DER and BER, never crash`() {
        var random = Fuzzing(state: 0xde4)
        for _ in 0..<50_000 {
            let bytes = random.bytes(upTo: 64)
            _ = try? ISO_8825.DER.parse(bytes)
            _ = try? ISO_8825.BER.parse(bytes)
        }
    }

    @Test
    func `deep nesting and lengths larger than the input are refused, never crash`() {
        var deep: [UInt8] = []
        for _ in 0..<50_000 { deep += [0x30, 0x80] }
        _ = try? ISO_8825.BER.parse(deep)
        _ = try? ISO_8825.DER.parse(deep)
        #expect(throws: (any Error).self) { try ISO_8825.DER.parse([0x04, 0x88, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff]) }
        #expect(throws: (any Error).self) { try ISO_8825.DER.parse([0x04, 0x84, 0x7f, 0xff, 0xff, 0xff, 0x00]) }
    }
}
