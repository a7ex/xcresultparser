import Foundation

enum TestFixtures {
    enum FixtureError: Error {
        case missing(String)
    }

    /// Returns a private copy of a bundled `.xcresult` fixture.
    ///
    /// xcresulttool (Xcode 27) migrates bundles written by older Xcode versions in place the first
    /// time it opens them: it rebuilds `database.sqlite3` and moves the new file into the bundle.
    /// Tests run in parallel, and several of them opening the same bundle at once make this move fail
    /// ("database.sqlite3 couldn't be moved … an item with the same name already exists").
    /// A copy per call keeps the tests independent. On APFS the copy is a clone, so it is cheap.
    static func xcresult(_ name: String) throws -> URL {
        guard let source = Bundle.module.url(forResource: name, withExtension: "xcresult") else {
            throw FixtureError.missing("\(name).xcresult")
        }
        let directory = copiesRoot.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let copy = directory.appendingPathComponent(source.lastPathComponent, isDirectory: true)
        try FileManager.default.copyItem(at: source, to: copy)
        return copy
    }

    /// One directory per test process. Directories left behind by earlier test processes that are
    /// no longer running are removed when the first fixture is copied.
    private static let copiesRoot: URL = {
        let temporaryDirectory = FileManager.default.temporaryDirectory
        let prefix = "xcresultparser-test-fixtures-"
        let currentProcess = ProcessInfo.processInfo.processIdentifier
        let leftovers = (try? FileManager.default.contentsOfDirectory(atPath: temporaryDirectory.path)) ?? []
        for entry in leftovers where entry.hasPrefix(prefix) {
            guard let pid = Int32(entry.dropFirst(prefix.count)),
                  pid != currentProcess,
                  kill(pid, 0) != 0, errno == ESRCH else {
                continue
            }
            try? FileManager.default.removeItem(at: temporaryDirectory.appendingPathComponent(entry))
        }
        return temporaryDirectory.appendingPathComponent("\(prefix)\(currentProcess)", isDirectory: true)
    }()
}
