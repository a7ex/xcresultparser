import Foundation
import Testing
@testable import XcresultparserLib

struct XCResultToolProviderRetryTests {
    // Catches a failed concurrent read of a bundle xcresulttool is upgrading not being run again.
    @Test
    func testProviderRetriesACallThatFailedWhileTheBundleWasUpgraded() async throws {
        let attempts = CallCounter()
        var client = StubXCResultToolClient()
        client.getTestSummaryHandler = { _ in
            // The first read fails, as one of two concurrent first reads of an older bundle does.
            if await attempts.increment() == 1 {
                throw TestDoubleError.forced
            }
            return try TestModelFactory.summary(startTime: 1, finishTime: 2)
        }
        client.getTestsHandler = { _ in try TestModelFactory.tests() }

        let provider = try await XCResultToolJunitXMLDataProvider(url: URL(fileURLWithPath: "/tmp/test.xcresult"), client: client)

        #expect(await attempts.count == 2)
        #expect(provider.metrics.testsCount == 0)
    }
}
