import Foundation
import SessionLevelFailureRepro
import Testing

// Swift Testing attributes an issue to the test whose source contains the recording call,
// even if the issue is recorded on another thread or after the test returned.
// This function lies outside any test and runs on a plain thread, so its issue has no
// associated test or suite and xcresulttool lists it as a session-level issue.
func recordSessionLevelIssue() {
    // Issue.record is on line 11, the location recorded in the committed fixture.
    _ = Issue.record("Issue recorded on a thread outside any test — no Test.current")
}

@Suite("Session-level failure demo")
struct SessionLevelFailureTests {
    @Test
    func passingTest() {
        #expect(add(1, 2) == 3)
    }

    @Test
    func triggerSessionLevelFailure() async {
        await withCheckedContinuation { continuation in
            Thread.detachNewThread {
                recordSessionLevelIssue()
                continuation.resume()
            }
        }
    }
}
