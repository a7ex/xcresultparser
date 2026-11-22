import Foundation
import Testing
@testable import XcresultparserLib

@MainActor
struct XCCovClientTests {
    @Test
    func testGetCoverageDataUsesExpectedCommandAndDecodes() async throws {
        let json = """
        {
          "/tmp/Foo.swift": [
            {
              "isExecutable": true,
              "line": 1,
              "executionCount": 2
            }
          ]
        }
        """
        let shell = CapturingCommandline(response: Data(json.utf8))
        let client = XCCovClient(shell: shell)
        let path = URL(fileURLWithPath: "/tmp/test.xcresult")

        let result = try await client.getCoverageData(path: path)

        #expect(result.files["/tmp/Foo.swift"]?.count == 1)
        #expect(await shell.lastProgram == "/usr/bin/xcrun")
        #expect(await shell.lastArguments == ["xccov", "view", "--archive", "--json", "/tmp/test.xcresult"])
    }

    @Test
    func testGetCoverageReportUsesExpectedCommandAndDecodes() async throws {
        let json = """
        {
          "coveredLines": 1,
          "executableLines": 2,
          "lineCoverage": 0.5,
          "targets": [
            {
              "name": "MyTarget",
              "lineCoverage": 0.5,
              "executableLines": 2,
              "coveredLines": 1,
              "files": [
                {
                  "name": "Foo.swift",
                  "path": "/tmp/Foo.swift",
                  "lineCoverage": 0.5,
                  "executableLines": 2,
                  "coveredLines": 1,
                  "functions": [
                    {
                      "name": "foo()",
                      "lineNumber": 1,
                      "lineCoverage": 0.5,
                      "executableLines": 2,
                      "coveredLines": 1,
                      "executionCount": 1
                    }
                  ]
                }
              ]
            }
          ]
        }
        """
        let shell = CapturingCommandline(response: Data(json.utf8))
        let client = XCCovClient(shell: shell)
        let path = URL(fileURLWithPath: "/tmp/test.xcresult")

        let result = try await client.getCoverageReport(path: path)

        #expect(result.targets.first?.name == "MyTarget")
        #expect(result.targets.first?.files.first?.functions.map(\.name) == ["foo()"])
        #expect(await shell.lastProgram == "/usr/bin/xcrun")
        #expect(await shell.lastArguments == ["xccov", "view", "--report", "--json", "/tmp/test.xcresult"])
    }

    @Test
    func testGetCoverageForFileUsesExpectedCommand() async throws {
        let shell = CapturingCommandline(response: Data("  1: 1\n".utf8))
        let client = XCCovClient(shell: shell)
        let path = URL(fileURLWithPath: "/tmp/test.xcresult")

        let result = try await client.getCoverageForFile(path: path, filePath: "/tmp/Foo.swift")

        #expect(result == "  1: 1\n")
        #expect(await shell.lastProgram == "/usr/bin/xcrun")
        #expect(await shell.lastArguments == ["xccov", "view", "--archive", "--file", "/tmp/Foo.swift", "/tmp/test.xcresult"])
    }

    @Test
    func testGetCoverageFileListUsesExpectedCommand() async throws {
        let shell = CapturingCommandline(response: Data("/tmp/Foo.swift\n/tmp/Bar.swift\n".utf8))
        let client = XCCovClient(shell: shell)
        let path = URL(fileURLWithPath: "/tmp/test.xcresult")

        let result = try await client.getCoverageFileList(path: path)

        #expect(result == ["/tmp/Foo.swift", "/tmp/Bar.swift", ""])
        #expect(await shell.lastProgram == "/usr/bin/xcrun")
        #expect(await shell.lastArguments == ["xccov", "view", "--archive", "--file-list", "/tmp/test.xcresult"])
    }
}
