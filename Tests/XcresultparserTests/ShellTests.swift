import Foundation
import Testing
@testable import XcresultparserLib

struct ShellTests {
    // Catches executeCancellable leaving the program running after its task is cancelled.
    @Test
    func testExecuteCancellableTerminatesTheProgramWhenCancelled() async throws {
        let marker = FileManager.default.temporaryDirectory
            .appendingPathComponent("xcresultparser-shell-\(UUID().uuidString)")
        defer {
            try? FileManager.default.removeItem(at: marker)
        }
        let start = Date()
        let run = Task {
            try await Shell().executeCancellable(
                program: "/bin/sh",
                with: ["-c", "touch \"$0\" && exec /bin/sleep 60", marker.path],
                at: nil
            )
        }

        // Cancel once the program is running, so that only terminating it can end the call early.
        // Task.sleep(for:) needs macOS 13; the package supports macOS 12.
        while !FileManager.default.fileExists(atPath: marker.path), Date().timeIntervalSince(start) < 10 {
            try await Task.sleep(nanoseconds: 10000000)
        }
        let started = FileManager.default.fileExists(atPath: marker.path)
        run.cancel()

        #expect(started)
        await #expect(throws: CancellationError.self) {
            try await run.value
        }
        // Without termination the call only returns once sleep exits after 60 s.
        #expect(Date().timeIntervalSince(start) < 30)
    }
}
