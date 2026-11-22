import Foundation
import Testing
@testable import XcresultparserLib

struct SafeReplacementTests {
    // Catches hexString formatting digests differently from the String(format: "%02hhx") it replaced.
    @Test
    func digestsUseLowercaseZeroPaddedHex() {
        #expect("".md5() == "d41d8cd98f00b204e9800998ecf8427e")
        #expect(Data("abc".utf8).md5() == "900150983cd24fb0d6963f7d28e17f72")
        #expect("abc".sha256() == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
        #expect([0x00, 0x0F, 0xA0, 0xFF].hexString == "000fa0ff")
    }

    // Catches directoryExists treating an empty project root as the current working directory.
    @Test
    func directoryExistsOnlyForDirectories() throws {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "xcresultparser-directory-exists-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: directory)
        }
        let file = directory.appending(path: "file.txt")
        try Data().write(to: file)

        #expect(FileManager.default.directoryExists(atPath: directory.path))
        #expect(!FileManager.default.directoryExists(atPath: file.path))
        #expect(!FileManager.default.directoryExists(atPath: directory.appending(path: "missing").path))
        #expect(!FileManager.default.directoryExists(atPath: ""))
    }
}
