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

        let directoryLink = directory.appending(path: "directory-link")
        let fileLink = directory.appending(path: "file-link")
        let missing = directory.appending(path: "missing")
        let danglingLink = directory.appending(path: "dangling-link")
        let hardLink = directory.appending(path: "hard-link")
        try FileManager.default.createSymbolicLink(at: directoryLink, withDestinationURL: directory)
        try FileManager.default.createSymbolicLink(at: fileLink, withDestinationURL: file)
        try FileManager.default.createSymbolicLink(at: danglingLink, withDestinationURL: missing)
        try FileManager.default.linkItem(at: file, to: hardLink)

        #expect(FileManager.default.directoryExists(atPath: directory.path))
        #expect(!FileManager.default.directoryExists(atPath: file.path))
        #expect(FileManager.default.directoryExists(atPath: directoryLink.path))
        #expect(!FileManager.default.directoryExists(atPath: fileLink.path))
        #expect(!FileManager.default.directoryExists(atPath: danglingLink.path))
        #expect(!FileManager.default.directoryExists(atPath: hardLink.path))
        #expect(!FileManager.default.directoryExists(atPath: missing.path))
        #expect(!FileManager.default.directoryExists(atPath: ""))

        // Each component before ".." must itself resolve to a directory.
        #expect(!FileManager.default.directoryExists(atPath: file.path + "/.."))
        #expect(!FileManager.default.directoryExists(atPath: missing.path + "/.."))
        #expect(FileManager.default.directoryExists(atPath: directoryLink.path + "/.."))
    }
}
