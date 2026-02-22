import Foundation
@testable import XcresultparserLib
import Testing

@MainActor
struct XCResultToolClientTests {
    @Test
    func testGetBuildResultsUsesExpectedCommandAndDecodes() throws {
        let json = """
        {
          "destination": {
            "deviceId": "device-1",
            "deviceName": "My Mac"
          },
          "startTime": 1.0,
          "endTime": 2.0,
          "analyzerWarnings": [],
          "warnings": [],
          "errors": []
        }
        """
        let shell = CapturingCommandline(response: Data(json.utf8))
        let client = XCResultToolClient(shell: shell)
        let path = URL(fileURLWithPath: "/tmp/test.xcresult")

        let result = try client.getBuildResults(path: path)

        #expect(result.destination.deviceName == "My Mac")
        #expect(shell.lastProgram == "/usr/bin/xcrun")
        #expect(shell.lastArguments == ["xcresulttool", "get", "build-results", "--path", "/tmp/test.xcresult"])
    }

    @Test
    func testGetTestDetailsUsesExpectedCommandAndDecodes() throws {
        let json = """
        {
          "testIdentifier": "A/B",
          "testName": "testFoo()",
          "testDescription": "Test case with 1 run",
          "duration": "0,01s",
          "testPlanConfigurations": [{"configurationId":"1","configurationName":"Default"}],
          "devices": [{"deviceId":"device-1","deviceName":"My Mac"}],
          "testRuns": [{"name":"testFoo()","nodeType":"Test Case"}],
          "testResult": "Passed",
          "hasPerformanceMetrics": false,
          "hasMediaAttachments": false
        }
        """
        let shell = CapturingCommandline(response: Data(json.utf8))
        let client = XCResultToolClient(shell: shell)
        let path = URL(fileURLWithPath: "/tmp/test.xcresult")

        let result = try client.getTestDetails(path: path, testId: "A/B")

        #expect(result.testName == "testFoo()")
        #expect(shell.lastArguments == [
            "xcresulttool", "get", "test-results", "test-details",
            "--path", "/tmp/test.xcresult",
            "--test-id", "A/B"
        ])
    }

    @Test
    func testGetMetricsDecodesObjectAsSingleElementArray() throws {
        let json = """
        {
          "testIdentifier": "PerfTests/testExample()",
          "testRuns": [
            {
              "testPlanConfiguration": {
                "configurationId": "1",
                "configurationName": "Default"
              },
              "device": {
                "deviceId": "device-1",
                "deviceName": "My Mac"
              },
              "metrics": [
                {
                  "displayName": "Clock Time",
                  "unitOfMeasurement": "s",
                  "measurements": [1.2, 1.3]
                }
              ]
            }
          ]
        }
        """
        let shell = CapturingCommandline(response: Data(json.utf8))
        let client = XCResultToolClient(shell: shell)

        let result = try client.getMetrics(path: URL(fileURLWithPath: "/tmp/test.xcresult"), testId: "PerfTests/testExample()")

        #expect(result.count == 1)
        #expect(result[0].testRuns.count == 1)
        #expect(result[0].testRuns[0].metrics[0].displayName == "Clock Time")
    }

    @Test
    func testGetMetricsDecodesEmptyArray() throws {
        let shell = CapturingCommandline(response: Data("[]".utf8))
        let client = XCResultToolClient(shell: shell)

        let result = try client.getMetrics(path: URL(fileURLWithPath: "/tmp/test.xcresult"), testId: "NoPerf/test")

        #expect(result.isEmpty)
    }

    @Test
    func testGetMetricsThrowsForUnexpectedPayload() throws {
        let shell = CapturingCommandline(response: Data("{\"foo\":\"bar\"}".utf8))
        let client = XCResultToolClient(shell: shell)

        do {
            _ = try client.getMetrics(path: URL(fileURLWithPath: "/tmp/test.xcresult"), testId: "NoPerf/test")
            Issue.record("Expected getMetrics to throw for unexpected payload.")
        } catch let error as XCResultToolClient.ToolClientError {
            switch error {
            case .unexpectedRootValue:
                #expect(true)
            default:
                Issue.record("Unexpected XCResultToolClient error: \(error)")
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }
}
