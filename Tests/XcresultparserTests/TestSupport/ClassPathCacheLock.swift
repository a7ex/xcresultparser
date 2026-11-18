import Foundation

/// Serializes tests that reset or fill `JunitXML`'s class path cache.
///
/// The cache is process-wide and filled once, by the first Sonar report that needs it. Swift Testing
/// runs tests in parallel, so without this lock one test can read paths another test put there.
enum ClassPathCacheLock {
    private static let lock = NSLock()

    static func withLock<T>(_ body: () throws -> T) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }
        return try body()
    }
}
