import Foundation
import Testing
@testable import XcresultparserLib

struct HexStringTests {
    @Test
    func emptyBytesGiveAnEmptyString() {
        #expect([UInt8]().hexString == "")
    }

    // Catches dropping the leading zero of bytes below 0x10.
    @Test
    func everyByteIsTwoDigits() {
        #expect([0x00, 0x01, 0x0F, 0x10].hexString == "00010f10")
    }

    @Test
    func digitsAreLowercase() {
        #expect([0xAB, 0xCD, 0xEF, 0xFF].hexString == "abcdefff")
    }

    // Catches the high and low nibbles being swapped.
    @Test
    func highNibbleComesFirst() {
        #expect([0x12, 0xF0].hexString == "12f0")
    }

    // Catches any byte formatting differently from the `String(format: "%02hhx")` this replaced.
    @Test
    func matchesTwoDigitHexForEveryByte() {
        let allBytes = (0...255).map { UInt8($0) }
        let expected = allBytes.map { byte in
            let hex = String(byte, radix: 16)
            return hex.count == 1 ? "0" + hex : hex
        }.joined()
        #expect(allBytes.hexString == expected)
    }

    @Test
    func worksForAnyByteSequence() {
        #expect(Data([0xDE, 0xAD, 0xBE, 0xEF]).hexString == "deadbeef")
    }
}
