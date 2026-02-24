import Foundation
@testable import XcresultparserLib
import Testing

@MainActor
struct XCResultToolJunitXMLDataProviderTests {
    @Test
    func testProviderMapsSummaryAndTestNodes() throws {
        let summaryJSON = """
        {
          "title": "Test - Demo",
          "environmentDescription": "Demo",
          "topInsights": [],
          "result": "Failed",
          "totalTestCount": 2,
          "passedTests": 1,
          "failedTests": 1,
          "skippedTests": 0,
          "expectedFailures": 0,
          "statistics": [],
          "devicesAndConfigurations": [],
          "testFailures": [
            {
              "failureText": "failed - expected true",
              "targetName": "DemoTests",
              "testIdentifier": 1,
              "testIdentifierString": "DemoTests/testFail()",
              "testIdentifierURL": "test://com.apple.xcode/Demo/DemoTests/testFail",
              "testName": "testFail()"
            }
          ],
          "startTime": 100.0,
          "finishTime": 120.0
        }
        """

        let testsJSON = """
        {
          "testPlanConfigurations": [
            {
              "configurationId": "1",
              "configurationName": "Default"
            }
          ],
          "devices": [
            {
              "deviceId": "device-1",
              "deviceName": "My Mac"
            }
          ],
          "testNodes": [
            {
              "name": "Test Plan",
              "nodeType": "Test Plan",
              "children": [
                {
                  "name": "Default",
                  "nodeType": "Test Plan Configuration",
                  "children": [
                    {
                      "name": "DemoTests.xctest",
                      "nodeType": "Unit test bundle",
                      "durationInSeconds": 3.0,
                      "children": [
                        {
                          "name": "DemoTests",
                          "nodeType": "Test Suite",
                          "durationInSeconds": 3.0,
                          "children": [
                            {
                              "name": "testPass()",
                              "nodeType": "Test Case",
                              "result": "Passed",
                              "durationInSeconds": 1.0
                            },
                            {
                              "name": "testFail()",
                              "nodeType": "Test Case",
                              "result": "Failed",
                              "durationInSeconds": 2.0
                            }
                          ]
                        }
                      ]
                    }
                  ]
                }
              ]
            }
          ]
        }
        """

        let shell = LookupShell(
            responses: [
                "xcresulttool get test-results summary --path /tmp/test.xcresult": .success(Data(summaryJSON.utf8)),
                "xcresulttool get test-results tests --path /tmp/test.xcresult": .success(Data(testsJSON.utf8))
            ]
        )
        let client = XCResultToolClient(shell: shell)
        let provider = try XCResultToolJunitXMLDataProvider(
            url: URL(fileURLWithPath: "/tmp/test.xcresult"),
            client: client
        )

        #expect(provider.metrics.testsCount == 2)
        #expect(provider.metrics.testsFailedCount == 1)

        let action = try #require(provider.testActions.first)
        #expect(action.startedTime.timeIntervalSince1970 == 100.0)
        #expect(action.endedTime.timeIntervalSince1970 == 120.0)

        let plan = try #require(action.testPlanRunSummaries.first)
        #expect(plan.name == "Default")
        let rootGroup = try #require(plan.testableSummaries.first?.tests.first)
        #expect(rootGroup.name == "DemoTests.xctest")
        #expect(rootGroup.subtestGroups.count == 1)

        let suite = try #require(rootGroup.subtestGroups.first)
        #expect(suite.subtests.count == 2)
        #expect(suite.subtests[0].name == "testPass()")
        #expect(suite.subtests[1].isFailed == true)
        #expect(action.failureSummaries.first?.testCaseName == "DemoTests.testFail()")
    }

    @Test
    func testProviderAddsFailureDocumentLocation() throws {
        let summaryJSON = """
        {
          "title": "Test - Demo",
          "environmentDescription": "Demo",
          "topInsights": [],
          "result": "Failed",
          "totalTestCount": 1,
          "passedTests": 0,
          "failedTests": 1,
          "skippedTests": 0,
          "expectedFailures": 0,
          "statistics": [],
          "devicesAndConfigurations": [],
          "testFailures": [
            {
              "failureText": "failed - expected true",
              "targetName": "DemoTests",
              "testIdentifier": 1,
              "testIdentifierString": "DemoTests/testFail()",
              "testIdentifierURL": "test://com.apple.xcode/Demo/DemoTests/testFail",
              "testName": "testFail()"
            }
          ],
          "startTime": 100.0,
          "finishTime": 120.0
        }
        """

        let testsJSON = """
        {
          "testPlanConfigurations": [
            {
              "configurationId": "1",
              "configurationName": "Default"
            }
          ],
          "devices": [],
          "testNodes": [
            {
              "name": "Test Plan",
              "nodeType": "Test Plan",
              "children": [
                {
                  "name": "Default",
                  "nodeType": "Test Plan Configuration",
                  "children": [
                    {
                      "name": "DemoTests.xctest",
                      "nodeType": "Unit test bundle",
                      "children": [
                        {
                          "name": "DemoTests",
                          "nodeType": "Test Suite",
                          "children": [
                            {
                              "name": "testFail()",
                              "nodeType": "Test Case",
                              "result": "Failed",
                              "children": [
                                {
                                  "name": "DemoTests.swift:42: failed - expected true",
                                  "nodeType": "Failure Message"
                                }
                              ]
                            }
                          ]
                        }
                      ]
                    }
                  ]
                }
              ]
            }
          ]
        }
        """

        let shell = LookupShell(
            responses: [
                "xcresulttool get test-results summary --path /tmp/test.xcresult": .success(Data(summaryJSON.utf8)),
                "xcresulttool get test-results tests --path /tmp/test.xcresult": .success(Data(testsJSON.utf8))
            ]
        )
        let client = XCResultToolClient(shell: shell)
        let provider = try XCResultToolJunitXMLDataProvider(
            url: URL(fileURLWithPath: "/tmp/test.xcresult"),
            client: client
        )

        let action = try #require(provider.testActions.first)
        let summary = try #require(action.failureSummaries.first)
        #expect(summary.documentLocation == "DemoTests.swift:42")
    }

    @Test
    func testProviderInitFailsIfXCResultToolFails() {
        let shell = LookupShell(
            responses: [
                "xcresulttool get test-results summary --path /tmp/test.xcresult": .failure(NSError(domain: "test", code: 42))
            ]
        )
        let client = XCResultToolClient(shell: shell)

        #expect(throws: (any Error).self) {
            try XCResultToolJunitXMLDataProvider(
                url: URL(fileURLWithPath: "/tmp/test.xcresult"),
                client: client
            )
        }
    }

    @Test
    func testProviderMapsParameterizedTests() throws {
        let summaryJSON = """
        {
          "title": "Test - Demo",
          "environmentDescription": "Demo",
          "topInsights": [],
          "result": "Failed",
          "totalTestCount": 2,
          "passedTests": 2,
          "failedTests": 0,
          "skippedTests": 0,
          "expectedFailures": 0,
          "statistics": [],
          "devicesAndConfigurations": [],
          "testFailures": [],
          "startTime": 100.0,
          "finishTime": 120.0
        }
        """

        let testsJSON = """
        {
          "testPlanConfigurations": [
            {
              "configurationId": "1",
              "configurationName": "Default"
            }
          ],
          "devices": [],
          "testNodes": [
            {
              "name": "Test Plan",
              "nodeType": "Test Plan",
              "children": [
                {
                  "name": "Default",
                  "nodeType": "Test Plan Configuration",
                  "children": [
                    {
                      "name": "DemoTests.xctest",
                      "nodeType": "Unit test bundle",
                      "children": [
                        {
                          "name": "DemoTests",
                          "nodeType": "Test Suite",
                          "children": [
                            {
                              "name": "testParametrized(value:)",
                              "nodeType": "Test Case",
                              "result": "Passed",
                              "children": [
                                {
                                  "name": "false",
                                  "nodeType": "Arguments",
                                  "result": "Passed",
                                  "durationInSeconds": 1.0
                                },
                                {
                                  "name": "true",
                                  "nodeType": "Arguments",
                                  "result": "Passed",
                                  "durationInSeconds": 2.0
                                }
                              ]
                            },
                            {
                              "name": "testMultiParam(value:count:)",
                              "nodeType": "Test Case",
                              "result": "Passed",
                              "children": [
                                {
                                  "name": "false, 3",
                                  "nodeType": "Arguments",
                                  "result": "Passed",
                                  "durationInSeconds": 1.0
                                }
                              ]
                            }
                          ]
                        }
                      ]
                    }
                  ]
                }
              ]
            }
          ]
        }
        """

        let shell = LookupShell(
            responses: [
                "xcresulttool get test-results summary --path /tmp/test.xcresult": .success(Data(summaryJSON.utf8)),
                "xcresulttool get test-results tests --path /tmp/test.xcresult": .success(Data(testsJSON.utf8))
            ]
        )
        let client = XCResultToolClient(shell: shell)
        let provider = try XCResultToolJunitXMLDataProvider(
            url: URL(fileURLWithPath: "/tmp/test.xcresult"),
            client: client
        )

        let action = try #require(provider.testActions.first)
        let plan = try #require(action.testPlanRunSummaries.first)
        let rootGroup = try #require(plan.testableSummaries.first?.tests.first)
        let suite = try #require(rootGroup.subtestGroups.first)
        #expect(suite.subtests.count == 3)
        #expect(suite.subtests[0].name == "testParametrized(value: false)")
        #expect(suite.subtests[1].name == "testParametrized(value: true)")
        #expect(suite.subtests[2].name == "testMultiParam(value: false, count: 3)")
    }

    @Test
    func testProviderDoesNotMapExpectedFailureAsSkipped() throws {
        let summaryJSON = """
        {
          "title": "Test - Demo",
          "environmentDescription": "Demo",
          "topInsights": [],
          "result": "Passed",
          "totalTestCount": 1,
          "passedTests": 1,
          "failedTests": 0,
          "skippedTests": 0,
          "expectedFailures": 1,
          "statistics": [],
          "devicesAndConfigurations": [],
          "testFailures": [],
          "startTime": 100.0,
          "finishTime": 101.0
        }
        """

        let testsJSON = """
        {
          "testPlanConfigurations": [
            {
              "configurationId": "1",
              "configurationName": "Default"
            }
          ],
          "devices": [],
          "testNodes": [
            {
              "name": "Test Plan",
              "nodeType": "Test Plan",
              "children": [
                {
                  "name": "Default",
                  "nodeType": "Test Plan Configuration",
                  "children": [
                    {
                      "name": "DemoTests.xctest",
                      "nodeType": "Unit test bundle",
                      "children": [
                        {
                          "name": "DemoTests",
                          "nodeType": "Test Suite",
                          "children": [
                            {
                              "name": "testExpected()",
                              "nodeType": "Test Case",
                              "result": "Expected Failure",
                              "durationInSeconds": 1.0
                            }
                          ]
                        }
                      ]
                    }
                  ]
                }
              ]
            }
          ]
        }
        """

        let shell = LookupShell(
            responses: [
                "xcresulttool get test-results summary --path /tmp/test.xcresult": .success(Data(summaryJSON.utf8)),
                "xcresulttool get test-results tests --path /tmp/test.xcresult": .success(Data(testsJSON.utf8))
            ]
        )
        let client = XCResultToolClient(shell: shell)
        let provider = try XCResultToolJunitXMLDataProvider(
            url: URL(fileURLWithPath: "/tmp/test.xcresult"),
            client: client
        )

        let action = try #require(provider.testActions.first)
        let plan = try #require(action.testPlanRunSummaries.first)
        let rootGroup = try #require(plan.testableSummaries.first?.tests.first)
        let suite = try #require(rootGroup.subtestGroups.first)
        let expectedFailureTest = try #require(suite.subtests.first)

        #expect(expectedFailureTest.isFailed == false)
        #expect(expectedFailureTest.isSkipped == false)
    }
}

private final class LookupShell: Commandline {
    let responses: [String: Result<Data, Error>]

    init(responses: [String: Result<Data, Error>]) {
        self.responses = responses
    }

    func execute(program: String, with arguments: [String], at executionPath: URL?) throws -> Data {
        #expect(program == "/usr/bin/xcrun")
        let key = arguments.joined(separator: " ")
        guard let response = responses[key] else {
            throw NSError(domain: "missing_response", code: 1)
        }
        switch response {
        case .success(let data):
            return data
        case .failure(let error):
            throw error
        }
    }
}
