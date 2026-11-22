import Foundation
import Testing
@testable import XcresultparserLib

struct ShellTests {
    // Catches execute leaving the program running after its task is cancelled.
    // The test doesn't measure time: on a busy CI runner the other tests can keep this one from
    // resuming for a long time. Instead the program records that it received SIGTERM.
    @Test
    func testExecuteTerminatesTheProgramWhenCancelled() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("xcresultparser-shell-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: directory)
        }
        let startedMarker = directory.appendingPathComponent("started")
        let terminatedMarker = directory.appendingPathComponent("terminated")
        // On SIGTERM: record it, stop sleep and exit. Without SIGTERM the script exits after 60 s
        // without writing the terminated marker. sleep writes to /dev/null, so that only the
        // script holds the output pipe open.
        let script = """
        trap 'touch "$1"; kill "$pid" 2>/dev/null; exit 143' TERM
        /bin/sleep 60 >/dev/null 2>&1 &
        pid=$!
        touch "$0"
        wait "$pid"
        """
        let run = Task {
            try await Shell().execute(
                program: "/bin/sh",
                with: ["-c", script, startedMarker.path, terminatedMarker.path],
                at: nil
            )
        }

        // Cancel once the script is running and its trap is set.
        let deadline = Date().addingTimeInterval(60)
        while !FileManager.default.fileExists(atPath: startedMarker.path), Date() < deadline {
            try await Task.sleep(for: .milliseconds(10))
        }
        let started = FileManager.default.fileExists(atPath: startedMarker.path)
        run.cancel()

        #expect(started)
        await #expect(throws: CancellationError.self) {
            try await run.value
        }
        #expect(FileManager.default.fileExists(atPath: terminatedMarker.path))
    }
}
