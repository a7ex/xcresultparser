import Foundation
@testable import XcresultparserLib
import Testing

struct XcresultparserTests {
    @Test
    func testTextResultFormatter() throws {
        let xcresultFile = Bundle.module.url(forResource: "test", withExtension: "xcresult")!
        let durationValue = executionTimeValue(for: xcresultFile)
        let dateValue = executionDateValue(for: xcresultFile)

        let resultParser = try XCResultFormatter(
            with: xcresultFile,
            formatter: TextResultFormatter(),
            coverageTargets: []
        )
        #expect(resultParser.documentPrefix(title: "XCResults") == "")

        let expectedSummary = """
        Summary
          Number of errors = 0
          Number of warnings = 3
          Number of analyzer warnings = 0
          Number of tests = 7
          Number of failed tests = 1
          Number of skipped tests = 0
          Execution time = \(durationValue)s
          Execution date = \(dateValue)
        """
        #expect(resultParser.summary == expectedSummary)
        #expect(resultParser.divider == "---------------------\n")
        #expect(resultParser.testDetails.starts(with: "Test Scheme Action"))

        #expect(resultParser.coverageDetails.starts(with: "Coverage report"))
        #expect(resultParser.documentSuffix == "")
    }

    @Test
    func testTextResultFormatterTotalCoverageReportFormat() throws {
        let xcresultFile = Bundle.module.url(forResource: "test", withExtension: "xcresult")!
        let durationValue = executionTimeValue(for: xcresultFile)
        let dateValue = executionDateValue(for: xcresultFile)

        let resultParser = try XCResultFormatter(
            with: xcresultFile,
            formatter: TextResultFormatter(),
            coverageTargets: [],
            coverageReportFormat: .totals
        )
        #expect("" == resultParser.documentPrefix(title: "XCResults"))

        let expectedSummary = """
        Summary
          Number of errors = 0
          Number of warnings = 3
          Number of analyzer warnings = 0
          Number of tests = 7
          Number of failed tests = 1
          Number of skipped tests = 0
          Execution time = \(durationValue)s
          Execution date = \(dateValue)
        """
        #expect(expectedSummary == resultParser.summary)
        #expect(resultParser.divider == "---------------------\n")
        #expect(resultParser.testDetails.starts(with: "Test Scheme Action"))

        let lines = resultParser.coverageDetails.components(separatedBy: "\n")
        #expect(lines.count == 2)
        #expect(lines.first == "Coverage report")
        #expect(lines.last?.starts(with: "Total coverage:") == true)
    }

    @Test
    func testTextResultFormatterMethodsCoverageReportFormat() throws {
        let xcresultFile = Bundle.module.url(forResource: "test", withExtension: "xcresult")!
        let durationValue = executionTimeValue(for: xcresultFile)
        let dateValue = executionDateValue(for: xcresultFile)

        let resultParser = try XCResultFormatter(
            with: xcresultFile,
            formatter: TextResultFormatter(),
            coverageTargets: [],
            coverageReportFormat: .methods
        )
        #expect(resultParser.documentPrefix(title: "XCResults") == "")

        let expectedSummary = """
        Summary
          Number of errors = 0
          Number of warnings = 3
          Number of analyzer warnings = 0
          Number of tests = 7
          Number of failed tests = 1
          Number of skipped tests = 0
          Execution time = \(durationValue)s
          Execution date = \(dateValue)
        """
        #expect(resultParser.summary == expectedSummary)
        #expect(resultParser.divider == "---------------------\n")
        #expect(resultParser.testDetails.starts(with: "Test Scheme Action"))

        let lines = resultParser.coverageDetails.components(separatedBy: "\n")
        #expect(lines.count == 473)
        #expect(lines.first == "Coverage report")
        #expect(lines[1].starts(with: "Total coverage:") == true)
        #expect(lines[2].starts(with: "XcresultparserLib:") == true)
        #expect(lines[3].contains("CLIResultFormatter.swift:") == true)
    }

    @Test
    func testTextResultFormatterCanExcludeDateAndDurationFromSummary() throws {
        let xcresultFile = Bundle.module.url(forResource: "test", withExtension: "xcresult")!

        let resultParser = try XCResultFormatter(
            with: xcresultFile,
            formatter: TextResultFormatter(),
            coverageTargets: [],
            summaryFields: "errors|warnings|analyzerWarnings|tests|failed|skipped"
        )

        #expect(resultParser.summary.contains("Number of tests = 7"))
        #expect(!resultParser.summary.contains("Execution time = "))
        #expect(!resultParser.summary.contains("Execution date = "))
    }

    @Test
    func testCLIResultFormatter() throws {
        let xcresultFile = Bundle.module.url(forResource: "test", withExtension: "xcresult")!
        let durationValue = executionTimeValue(for: xcresultFile)
        let dateValue = executionDateValue(for: xcresultFile)

        let resultParser = try XCResultFormatter(
            with: xcresultFile,
            formatter: CLIResultFormatter(),
            coverageTargets: []
        )
        #expect(resultParser.documentPrefix(title: "XCResults") == "")

        let expectedSummary = """
        \u{001B}[1mSummary\u{001B}[0m
          Number of errors = 0\u{001B}[0m
        \u{001B}[33m  Number of warnings = 3\u{001B}[0m
          Number of analyzer warnings = 0\u{001B}[0m
          Number of tests = 7\u{001B}[0m
        \u{001B}[31m  Number of failed tests = 1\u{001B}[0m
          Number of skipped tests = 0\u{001B}[0m
          Execution time = \(durationValue)s\u{001B}[0m
          Execution date = \(dateValue)\u{001B}[0m
        """
        #expect(resultParser.summary == expectedSummary)
        #expect(resultParser.divider == "-----------------\n")

        #expect(resultParser.testDetails.starts(with: "\u{001B}[1mTest Scheme Action\u{001B}[0m"))

        #expect(resultParser.coverageDetails.starts(with: "\u{001B}[1mCoverage report\u{001B}[0m"))

        #expect(resultParser.documentSuffix == "")
    }

    @Test
    func testHTMLResultFormatter() throws {
        let xcresultFile = Bundle.module.url(forResource: "test", withExtension: "xcresult")!
        let durationValue = executionTimeValue(for: xcresultFile)
        let dateValue = executionDateValue(for: xcresultFile)

        let resultParser = try XCResultFormatter(
            with: xcresultFile,
            formatter: HTMLResultFormatter(),
            coverageTargets: []
        )
        let documentPrefix = """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="utf-8">
            <title>XCResults</title>
        """
        #expect(resultParser.documentPrefix(title: "XCResults").starts(with: documentPrefix))

        let expectedSummary = """
        <h2>Summary</h2>
        <p class="resultSummaryLineSuccess">Number of errors = 0</p>
        <p class="resultSummaryLineWarning">Number of warnings = 3</p>
        <p class="resultSummaryLineSuccess">Number of analyzer warnings = 0</p>
        <p class="resultSummaryLineSuccess">Number of tests = 7</p>
        <p class="resultSummaryLineFailed">Number of failed tests = 1</p>
        <p class="resultSummaryLineSuccess">Number of skipped tests = 0</p>
        <p class="resultSummaryLineSuccess">Execution time = \(durationValue)s</p>
        <p class="resultSummaryLineSuccess">Execution date = \(dateValue)</p>
        """
        #expect(resultParser.summary == expectedSummary)
        #expect(resultParser.divider == "<hr>")
        #expect(resultParser.testDetails.starts(with: "<h2>Test Scheme Action</h2>"))
        #expect(resultParser.coverageDetails.starts(with: "<h2>Coverage report</h2>"))
        #expect(resultParser.documentSuffix.hasSuffix("</html>"))
    }

    @Test
    func testHTMLResultFormatterParameterizedArguments() throws {
        let xcresultFile = Bundle.module.url(forResource: "parametrized", withExtension: "xcresult")!

        let resultParser = try XCResultFormatter(
            with: xcresultFile,
            formatter: HTMLResultFormatter(),
            coverageTargets: []
        )

        #expect(
            resultParser.testDetails.contains(
                "testCoverageConverterPathnames(strictPathnames: false, projectRoot: \"/Users/fhaser/code/\")"
            )
        )
    }

    @Test
    func testMDResultFormatter() throws {
        let xcresultFile = Bundle.module.url(forResource: "test", withExtension: "xcresult")!
        let durationValue = executionTimeValue(for: xcresultFile)
        let dateValue = executionDateValue(for: xcresultFile)

        let resultParser = try XCResultFormatter(
            with: xcresultFile,
            formatter: MDResultFormatter(),
            coverageTargets: []
        )
        #expect(resultParser.documentPrefix(title: "XCResults") == "")

        let expectedSummary = "Errors: 0; Warnings: 3; Analyzer Warnings: 0; Tests: 7; Failed: 1; Skipped: 0; Execution time = \(durationValue)s; Execution date = \(dateValue)"
        #expect(resultParser.summary == expectedSummary)
        #expect(resultParser.divider == "\n---------------------\n")

        let lines = resultParser.testDetails.components(separatedBy: .newlines)
        #expect(lines[2].starts(with: "### XcresultparserTests.xctest"))
        #expect(lines[3].starts(with: "### XcresultparserTests"))
        #expect(lines[4].starts(with: "* <span"))

        let cLines = resultParser.coverageDetails.components(separatedBy: .newlines)
        #expect(cLines[1].starts(with: "Total coverage:"))
        #expect(cLines[2].starts(with: "XcresultparserLib:"))
        #expect(cLines[3].starts(with: "## CLIResultFormatter.swift:"))

        #expect(resultParser.documentSuffix == "")
    }

    @Test
    func testMDResultFormatterParameterizedArguments() throws {
        let xcresultFile = Bundle.module.url(forResource: "parametrized", withExtension: "xcresult")!

        let resultParser = try XCResultFormatter(
            with: xcresultFile,
            formatter: MDResultFormatter(),
            coverageTargets: []
        )

        #expect(
            resultParser.testDetails.contains(
                "testCoverageConverterPathnames(strictPathnames: false, projectRoot: \\\"/Users/fhaser/code/\\\")"
            )
        )
    }

    @Test
    func testTextResultFormatterParameterizedArguments() throws {
        let xcresultFile = Bundle.module.url(forResource: "parametrized", withExtension: "xcresult")!

        let resultParser = try XCResultFormatter(
            with: xcresultFile,
            formatter: TextResultFormatter(),
            coverageTargets: []
        )

        #expect(
            resultParser.testDetails.contains(
                "testCoverageConverterPathnames(strictPathnames: false, projectRoot: \"/Users/fhaser/code/\")"
            )
        )
    }

    @Test(arguments: [true, false])
    func testCoverageConverter(strictPathnames: Bool) throws {
        let xcresultFile = Bundle.module.url(forResource: "test", withExtension: "xcresult")!
        let projectRoot = ""

        let converter = try CoverageConverter(
            with: xcresultFile,
            projectRoot: projectRoot,
            strictPathnames: strictPathnames
        )
        let info = converter.targetsInfo
        #expect(info == "\nXcresultparserLib\nXcresultparserTests")

        let fileCoverage = try converter.getCoverageDataAsJSON()
        #expect(fileCoverage.files.count == 13)
        let firstKey = try #require(fileCoverage.files.keys.sorted().first)
        #expect(
            "/Users/fhaeser/code/xcresultparser/Sources/xcresultparser/CoberturaCoverageConverter.swift" ==
            firstKey
        )
        let firstItem = try #require(fileCoverage.files[firstKey])
        #expect(firstItem.count == 199)
        let firstLineDetail = try #require(firstItem.first)
        #expect(firstLineDetail.isExecutable == false)
        #expect(firstLineDetail.line == 1)
        #expect(firstLineDetail.executionCount == nil)
        #expect(firstLineDetail.subranges == nil)

        let otherLineDetail = firstItem[50]
        #expect(otherLineDetail.isExecutable)
        #expect(otherLineDetail.line == 51)
        #expect(otherLineDetail.executionCount == 0)
        #expect(otherLineDetail.subranges == nil)

        // Deprecated methods

        let fileList = try converter.coverageFileList()
        #expect(fileList.count == 14)
        let firstFile = "/Users/fhaeser/code/xcresultparser/Sources/xcresultparser/CoberturaCoverageConverter.swift"
        #expect(fileList.first == firstFile)
        let coverageForFile = try converter.coverageForFile(path: firstFile)
        #expect(coverageForFile.starts(with: "  1: *\n  2: *\n  3: *"))
        #expect(coverageForFile.contains(" 35: 0"))
    }

    @Test(arguments: [true, false], ["/Users/notexistant/code/xcresultparser", "/Users/fhaser/code/"])
    func testCoverageConverterPathnames(strictPathnames: Bool, projectRoot: String) throws {
        let xcresultFile = Bundle.module.url(forResource: "test", withExtension: "xcresult")!

        let converter = try SonarCoverageConverter(
            with: xcresultFile,
            projectRoot: projectRoot,
            strictPathnames: strictPathnames
        )

        let xml = try converter.xmlString(quiet: true)

        if strictPathnames {
            #expect(xml == "<coverage version=\"1\"/>")
        } else {
            #expect(xml.contains("/Users/fhaeser/code/xcresultparser/Sources/xcresultparser/OutputFormatting/Formatters/CLI/CLIResultFormatter.swift"))
        }

    }

    @Test(arguments: [true, false])
    func testSonarCoverageConverter(strictPathnames: Bool) throws {
        let xcresultFile = Bundle.module.url(forResource: "test", withExtension: "xcresult")!
        let projectRoot = ""
        let quiet = 1

        let converter = try SonarCoverageConverter(
            with: xcresultFile,
            projectRoot: projectRoot,
            strictPathnames: strictPathnames
        )
        let rslt = try converter.xmlString(quiet: quiet == 1)
        #expect(rslt.starts(with: "<coverage version=\"1\">"))
        let lines = rslt.components(separatedBy: .newlines)
        #expect(lines.count == 1492)
        let pos = try #require(lines.firstIndex(of: "<file path=\"/Users/fhaeser/code/xcresultparser/Sources/xcresultparser/OutputFormatting/Formatters/XCResultFormatting.swift\">"))
        #expect(lines[pos + 1] == "    <lineToCover lineNumber=\"36\" covered=\"true\"/>")
        #expect(lines[pos + 2] == "    <lineToCover lineNumber=\"37\" covered=\"true\"/>")

        let pos2 = try #require(lines.firstIndex(of: "<file path=\"/Users/fhaeser/code/xcresultparser/Sources/xcresultparser/Shell.swift\">"))
        #expect(lines[pos2 + 1] == "    <lineToCover lineNumber=\"15\" covered=\"false\"/>")
        #expect(lines[pos2 + 2] == "    <lineToCover lineNumber=\"16\" covered=\"false\"/>")
    }

    @Test
    func testCoverageTargetFilterWithNoMatchesThrowsError() throws {
        let xcresultFile = Bundle.module.url(forResource: "test", withExtension: "xcresult")!

        do {
            _ = try SonarCoverageConverter(
                with: xcresultFile,
                projectRoot: "",
                coverageTargets: ["NonExistingTarget"],
                strictPathnames: false
            )
            Issue.record("Expected unknown coverage target error")
        } catch let error as CoverageConverterError {
            switch error {
            case let .unknownCoverageTargets(requested, available):
                #expect(requested == ["NonExistingTarget"])
                #expect(!available.isEmpty)
            case .couldNotLoadCoverageReport:
                Issue.record("Unexpected coverage report loading error")
            case .notImplemented:
                Issue.record("Unexpected notImplemented case.")
            }
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test
    func testCoverageTargetFilterWithPartialUnknownThrowsError() throws {
        let xcresultFile = Bundle.module.url(forResource: "test", withExtension: "xcresult")!

        do {
            _ = try SonarCoverageConverter(
                with: xcresultFile,
                projectRoot: "",
                coverageTargets: ["XcresultparserLib", "MissingTarget"],
                strictPathnames: false
            )
            Issue.record("Expected unknown coverage target error")
        } catch let error as CoverageConverterError {
            switch error {
            case let .unknownCoverageTargets(requested, _):
                #expect(requested == ["MissingTarget"])
            case .couldNotLoadCoverageReport:
                Issue.record("Unexpected coverage report loading error")
            case .notImplemented:
                Issue.record("Unexpected notImplemented case.")
            }
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test
    func testFormatterInitFailsForUnknownCoverageTarget() {
        let xcresultFile = Bundle.module.url(forResource: "test", withExtension: "xcresult")!

        #expect(throws: CoverageConverterError.self) {
            try XCResultFormatter(
                with: xcresultFile,
                formatter: TextResultFormatter(),
                coverageTargets: ["NonExistingTarget"]
            )
        }
    }

    @Test
    func testSonarCoverageConverterExcludeFiles() throws {
        let xcresultFile = Bundle.module.url(forResource: "test", withExtension: "xcresult")!
        let projectRoot = ""
        let quiet = 1

        let converter = try SonarCoverageConverter(
            with: xcresultFile,
            projectRoot: projectRoot,
            excludedPaths: ["OutputFormatting/Formatters"],
            strictPathnames: false
        )
        let rslt = try converter.xmlString(quiet: quiet == 1)
        #expect(rslt.starts(with: "<coverage version=\"1\">"))
        let lines = rslt.components(separatedBy: .newlines)
        #expect(lines.count == 1082)
        let pos = lines.firstIndex(of: "<file path=\"/Users/fhaeser/code/xcresultparser/Sources/xcresultparser/OutputFormatting/Formatters/XCResultFormatting.swift\">")
        #expect(pos == nil)

        let pos2 = try #require(lines.firstIndex(of: "<file path=\"/Users/fhaeser/code/xcresultparser/Sources/xcresultparser/Shell.swift\">"))
        #expect(lines[pos2 + 1] == "    <lineToCover lineNumber=\"15\" covered=\"false\"/>")
        #expect(lines[pos2 + 2] == "    <lineToCover lineNumber=\"16\" covered=\"false\"/>")
    }

    @Test
    func testCoberturaConverter() throws {
        let xcresultFile = Bundle.module.url(forResource: "test", withExtension: "xcresult")!
        let projectRoot = ""

        let converter = try CoberturaCoverageConverter(
            with: xcresultFile,
            projectRoot: projectRoot,
            strictPathnames: false
        )
        try assertXmlTestReportsAreEqual(expectedFileName: "cobertura", actual: converter)
    }

    @Test
    func testCoberturaConverterExcludeFiles() throws {
        let xcresultFile = Bundle.module.url(forResource: "test", withExtension: "xcresult")!
        let projectRoot = ""

        let converter = try CoberturaCoverageConverter(
            with: xcresultFile,
            projectRoot: projectRoot,
            excludedPaths: ["OutputFormatting/Formatters"],
            strictPathnames: false
        )
        try assertXmlTestReportsAreEqual(expectedFileName: "coberturaExcludingDirectory", actual: converter)
    }

    @Test
    func testCoberturaCoverageTargetFilterWithNoMatchesThrowsError() throws {
        let xcresultFile = Bundle.module.url(forResource: "test", withExtension: "xcresult")!

        do {
            _ = try CoberturaCoverageConverter(
                with: xcresultFile,
                projectRoot: "",
                coverageTargets: ["NonExistingTarget"],
                strictPathnames: false
            )
            Issue.record("Expected unknown coverage target error")
        } catch let error as CoverageConverterError {
            switch error {
            case let .unknownCoverageTargets(requested, _):
                #expect(requested == ["NonExistingTarget"])
            case .couldNotLoadCoverageReport:
                Issue.record("Unexpected coverage report loading error")
            case .notImplemented:
                Issue.record("Unexpected notImplemented case.")
            }
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test
    func testCoverageConverterNormalizesTargetFilePaths() {
        let projectRoot = "/Users/demo/project"
        let paths = [
            "/Users/demo/project/Sources/Foo.swift",
            "Sources/Bar.swift"
        ]

        let normalized = CoverageConverter.normalizedFilePaths(for: paths, projectRoot: projectRoot)

        #expect(normalized.contains("/Users/demo/project/Sources/Foo.swift"))
        #expect(normalized.contains("Sources/Foo.swift"))
        #expect(normalized.contains("Sources/Bar.swift"))
        #expect(normalized.contains("/Users/demo/project/Sources/Bar.swift"))
    }

    @Test
    func testJunitXMLSonar() throws {
        JunitXML.resetCachedPathnames()
        let xcresultFile = Bundle.module.url(forResource: "test", withExtension: "xcresult")!
        let projectRoot = ""
        let junitXML = try JunitXML(
            with: xcresultFile,
            projectRoot: projectRoot,
            format: .sonar
        )
        try assertXmlTestReportsAreEqual(expectedFileName: "sonarTestExecution", actual: junitXML)
    }

    @Test
    func testJunitXMLSonarRelativePaths() throws {
        JunitXML.resetCachedPathnames()
        let cliResult = """
        ./Tests/XcresultparserTests.swift:class XcresultparserTests
        """
        let savedFilemanger = SharedInstances.fileManager
        SharedInstances.fileManager = MockedFileManager(fileExists: true, isPathDirectory: true)
        defer { SharedInstances.fileManager = savedFilemanger }

        let xcresultFile = Bundle.module.url(forResource: "test", withExtension: "xcresult")!
        let projectRoot = "/Users/imaginary/project"
        let dataProvider = try XCResultToolJunitXMLDataProvider(url: xcresultFile)
        let mockedShell = MockedShell(response: Data(cliResult.utf8), error: nil)
        mockedShell.argumentValidation = { arguments in
            return arguments.last == "."
        }
        let junitXML = JunitXML(
            dataProvider: dataProvider,
            projectRoot: projectRoot,
            format: .sonar,
            relativePathNames: true,
            shell: mockedShell
        )
        try assertXmlTestReportsAreEqual(expectedFileName: "sonarTestExecutionWithProjectRootRelative", actual: junitXML)
    }

    @Test
    func testJunitXMLSonarAbsolutePaths() throws {
        JunitXML.resetCachedPathnames()
        let cliResult = """
        /Users/actual/project/Tests/XcresultparserTests.swift:class XcresultparserTests
        """

        let savedFilemanger = SharedInstances.fileManager
        SharedInstances.fileManager = MockedFileManager(fileExists: true, isPathDirectory: true)
        defer { SharedInstances.fileManager = savedFilemanger }

        let xcresultFile = Bundle.module.url(forResource: "test", withExtension: "xcresult")!
        let projectRoot = "/Users/imaginary/project"
        let dataProvider = try XCResultToolJunitXMLDataProvider(url: xcresultFile)
        let mockedShell = MockedShell(response: Data(cliResult.utf8), error: nil)
        mockedShell.argumentValidation = { arguments in
            return arguments.last != "."
        }
        let junitXML = JunitXML(
            dataProvider: dataProvider,
            projectRoot: projectRoot,
            format: .sonar,
            relativePathNames: false,
            shell: mockedShell
        )
        try assertXmlTestReportsAreEqual(expectedFileName: "sonarTestExecutionWithProjectRootAbsolute", actual: junitXML)
    }

    @Test
    func testJunitXMLJunit() throws {
        let xcresultFile = Bundle.module.url(forResource: "test", withExtension: "xcresult")!
        let projectRoot = ""
        let junitXML = try JunitXML(
            with: xcresultFile,
            projectRoot: projectRoot,
            format: .junit
        )
        try assertXmlTestReportsAreEqual(expectedFileName: "junit", actual: junitXML)
    }

    @Test
    func testJunitXMLMergedJunit() throws {
        let xcresultFile = Bundle.module.url(forResource: "test_merged", withExtension: "xcresult")!
        let projectRoot = ""
        let junitXML = try JunitXML(
            with: xcresultFile,
            projectRoot: projectRoot,
            format: .junit
        )
        try assertXmlTestReportsAreEqual(expectedFileName: "junit_merged", actual: junitXML)
    }

    @Test
    func testJunitXMLRepeated() throws {
        let xcresultFile = Bundle.module.url(forResource: "test_repeated", withExtension: "xcresult")!
        let projectRoot = ""
        let junitXML = try JunitXML(
            with: xcresultFile,
            projectRoot: projectRoot,
            format: .junit
        )
        try assertXmlTestReportsAreEqual(expectedFileName: "junit_repeated", actual: junitXML)
    }

    @Test
    func testJunitXMLIncludesParameterizedArguments() throws {
        let xcresultFile = Bundle.module.url(forResource: "parametrized", withExtension: "xcresult")!
        let projectRoot = ""
        let junitXML = try JunitXML(
            with: xcresultFile,
            projectRoot: projectRoot,
            format: .junit
        )

        let xmlString = junitXML.xmlString
        #expect(xmlString.contains("testCoverageConverter(strictPathnames: false)"))
        #expect(xmlString.contains("testCoverageConverter(strictPathnames: true)"))
        #expect(
            xmlString.contains(
                "testCoverageConverterPathnames(strictPathnames: false, projectRoot: &quot;/Users/fhaser/code/&quot;)"
            )
        )
        #expect(
            xmlString.contains(
                "testCoverageConverterPathnames(strictPathnames: true, projectRoot: &quot;/Users/notexistant/code/xcresultparser&quot;)"
            )
        )
    }

    @Test
    func testFailureSummariesReturnsAllMatchingFailures() throws {
        let test = makeJunitTest()

        let matchingFailure1 = makeJunitFailureSummary(
            testCaseName: "TestClass.testMethod",
            message: "First assertion failed"
        )
        let matchingFailure2 = makeJunitFailureSummary(
            testCaseName: "TestClass.testMethod",
            message: "Second assertion failed"
        )
        let nonMatchingFailure = makeJunitFailureSummary(
            testCaseName: "OtherClass.otherMethod",
            message: "Unrelated failure"
        )

        let result = test.failureSummaries(in: [matchingFailure1, nonMatchingFailure, matchingFailure2])

        #expect(result.count == 2)
        #expect(result[0].message == "First assertion failed")
        #expect(result[1].message == "Second assertion failed")
    }

    @Test
    func testFailureSummariesWithBracketNotation() throws {
        let test = makeJunitTest()

        // Objective-C bracket notation: -[TestClass testMethod]
        let bracketFailure1 = makeJunitFailureSummary(
            testCaseName: "-[TestClass testMethod]",
            message: "Bracket notation failure 1"
        )
        let bracketFailure2 = makeJunitFailureSummary(
            testCaseName: "-[TestClass testMethod]",
            message: "Bracket notation failure 2"
        )

        let result = test.failureSummaries(in: [bracketFailure1, bracketFailure2])

        #expect(result.count == 2)
        #expect(result[0].message == "Bracket notation failure 1")
        #expect(result[1].message == "Bracket notation failure 2")
    }

    @Test
    func testFailureSummariesReturnsEmptyForNoMatches() throws {
        let test = makeJunitTest()
        let nonMatchingFailure = makeJunitFailureSummary(
            testCaseName: "OtherClass.otherMethod",
            message: "Unrelated failure"
        )

        let result = test.failureSummaries(in: [nonMatchingFailure])

        #expect(result.isEmpty)
    }

    @Test
    func testFailureSummariesWithEmptyArray() throws {
        let test = makeJunitTest()

        let result = test.failureSummaries(in: [])

        #expect(result.isEmpty)
    }

    @Test
    func testCleanCodeWarnings() throws {
        let xcresultFile = Bundle.module.url(forResource: "test", withExtension: "xcresult")!
        let converter = try IssuesJSON(with: xcresultFile)
        let rslt = try converter.jsonString(format: .warnings, quiet: true)
        let result = try JSONDecoder().decode([XcresultparserLib.Issue].self, from: Data(rslt.utf8))

        let expectedFile = Bundle.module.url(forResource: "warnings", withExtension: "json")!
        let expectedData = try Data(contentsOf: expectedFile)
        let expectedObject = try JSONDecoder().decode([XcresultparserLib.Issue].self, from: expectedData)

        #expect(expectedObject.count == result.count)
        let first = try #require(result.first)
        let last = try #require(result.last)
        #expect(expectedObject.first(where: { $0.checkName == first.checkName && $0.location == first.location }) != nil)
        #expect(expectedObject.first(where: { $0.checkName == last.checkName && $0.location == last.location }) != nil)
    }

    @Test
    func testCleanCodeWarningsWithRelativePath() throws {
        let xcresultFile = Bundle.module.url(forResource: "test", withExtension: "xcresult")!
        let converter = try IssuesJSON(with: xcresultFile, projectRoot: "xcresultparser/")
        let rslt = try converter.jsonString(format: .warnings, quiet: true)
        let result = try JSONDecoder().decode([XcresultparserLib.Issue].self, from: Data(rslt.utf8))
            .sorted { lhs, rhs in
                lhs.location.path > rhs.location.path
            }
        #expect(result.first?.location.path == "Tests/XcresultparserTests/XcresultparserTests.swift")
    }

    func testCleanCodeWarningsExcludingFiles() throws {
        let xcresultFile = Bundle.module.url(forResource: "test", withExtension: "xcresult")!
        let converter = try IssuesJSON(with: xcresultFile, excludedPaths: ["Tests/XcresultparserTests"])
        let rslt = try converter.jsonString(format: .warnings, quiet: true)
        let result = try JSONDecoder().decode([XcresultparserLib.Issue].self, from: Data(rslt.utf8))
        #expect(result.count == 0)
    }

    @Test
    func testCleanCodeNoErrors() throws {
        let xcresultFile = Bundle.module.url(forResource: "test", withExtension: "xcresult")!
        let converter = try IssuesJSON(with: xcresultFile)
        let rslt = try converter.jsonString(format: .errors, quiet: true)
        #expect(rslt == "[\n\n]")
    }

    @Test
    func testCleanCodeErrors() throws {
        let xcresultFile = Bundle.module.url(forResource: "resultWithCompileError", withExtension: "xcresult")!
        let converter = try IssuesJSON(with: xcresultFile)
        let rslt = try converter.jsonString(format: .errors, quiet: true)
        let result = try JSONDecoder().decode([XcresultparserLib.Issue].self, from: Data(rslt.utf8))
            .sorted { lhs, rhs in
                lhs.location.path > rhs.location.path
            }
        #expect(result.count == 2)
        let compileError = try #require(result.first)
        #expect(compileError.description == "Swift Compiler Error • Cannot find 'xmlString1' in scope")
        #expect(compileError.severity == .blocker)
        #expect(compileError.location.path.contains("Sources/xcresultparser/CoberturaCoverageConverter.swift"))
        #expect(compileError.type == .issue)
        #expect(compileError.content.body == "Swift Compiler Error • Cannot find 'xmlString1' in scope")
        #expect(compileError.categories.count == 0)
    }

    @Test
    func testOutputFormat() {
        var sut = OutputFormat(string: "txt")
        #expect(sut == OutputFormat.txt)

        sut = OutputFormat(string: "xml")
        #expect(sut == OutputFormat.xml)

        sut = OutputFormat(string: "html")
        #expect(sut == OutputFormat.html)

        sut = OutputFormat(string: "cli")
        #expect(sut == OutputFormat.cli)

        sut = OutputFormat(string: "cobertura")
        #expect(sut == OutputFormat.cobertura)

        sut = OutputFormat(string: "junit")
        #expect(sut == OutputFormat.junit)

        sut = OutputFormat(string: "md")
        #expect(sut == OutputFormat.md)

        sut = OutputFormat(string: "warnings")
        #expect(sut == OutputFormat.warnings)

        sut = OutputFormat(string: "errors")
        #expect(sut == OutputFormat.errors)

        sut = OutputFormat(string: "warnings-and-errors")
        #expect(sut == OutputFormat.warningsAndErrors)

        sut = OutputFormat(string: "")
        #expect(sut == OutputFormat.cli)

        sut = OutputFormat(string: "xyz")
        #expect(sut == OutputFormat.cli)
    }

    @Test
    func testCoverageReportFormat() {
        var sut = CoverageReportFormat(string: "methods")
        #expect(sut == CoverageReportFormat.methods)

        sut = CoverageReportFormat(string: "classes")
        #expect(sut == CoverageReportFormat.classes)

        sut = CoverageReportFormat(string: "targets")
        #expect(sut == CoverageReportFormat.targets)

        sut = CoverageReportFormat(string: "totals")
        #expect(sut == CoverageReportFormat.totals)

        sut = CoverageReportFormat(string: "not existing")
        #expect(sut == CoverageReportFormat.methods)

        sut = CoverageReportFormat(string: "")
        #expect(sut == CoverageReportFormat.methods)

        sut = CoverageReportFormat(string: "Classes")
        #expect(sut == CoverageReportFormat.classes)

        sut = CoverageReportFormat(string: "CLASSES")
        #expect(sut == CoverageReportFormat.classes)

        sut = CoverageReportFormat(string: "clASSeS")
        #expect(sut == CoverageReportFormat.classes)
    }

    @Test
    func testXCResultToolSummaryModelDecoding() throws {
        let json = """
        {
          "devicesAndConfigurations": [
            {
              "device": {
                "architecture": "arm64",
                "deviceId": "00006000-001869EC3623801E",
                "deviceName": "My Mac",
                "modelName": "MacBook Pro",
                "osBuildNumber": "22C65",
                "osVersion": "13.1",
                "platform": "macOS"
              },
              "expectedFailures": 0,
              "failedTests": 1,
              "passedTests": 6,
              "skippedTests": 0,
              "testPlanConfiguration": {
                "configurationId": "1",
                "configurationName": "Test Scheme Action"
              }
            }
          ],
          "environmentDescription": "Xcresultparser-Package · Built with macOS 13.1",
          "expectedFailures": 0,
          "failedTests": 1,
          "finishTime": 1672825230.228,
          "passedTests": 6,
          "result": "Failed",
          "skippedTests": 0,
          "startTime": 1672825221.218,
          "statistics": [],
          "testFailures": [
            {
              "failureText": "failed - example",
              "targetName": "XcresultparserTests",
              "testIdentifier": 2,
              "testIdentifierString": "XcresultparserTests/testCoverageConverter()",
              "testIdentifierURL": "test://com.apple.xcode/Xcresultparser/XcresultparserTests/XcresultparserTests/testCoverageConverter",
              "testName": "testCoverageConverter()"
            }
          ],
          "title": "Test - Xcresultparser-Package",
          "topInsights": [],
          "totalTestCount": 7
        }
        """
        let summary = try JSONDecoder().decode(XCSummary.self, from: Data(json.utf8))
        #expect(summary.failedTests == 1)
        #expect(summary.devicesAndConfigurations.count == 1)
        #expect(summary.testFailures.count == 1)
    }

    @Test
    func testXCResultToolTestsModelDecoding() throws {
        let json = """
        {
          "devices": [
            {
              "architecture": "arm64",
              "deviceId": "00006000-001869EC3623801E",
              "deviceName": "My Mac",
              "modelName": "MacBook Pro",
              "osBuildNumber": "22C65",
              "osVersion": "13.1",
              "platform": "macOS"
            }
          ],
          "testNodes": [
            {
              "children": [
                {
                  "children": [],
                  "duration": "0,31s",
                  "durationInSeconds": 0.30731201171875,
                  "name": "testCLIResultFormatter()",
                  "nodeType": "Test Case",
                  "result": "Passed"
                }
              ],
              "name": "Test Plan",
              "nodeType": "Test Plan",
              "result": "Failed"
            }
          ],
          "testPlanConfigurations": [
            {
              "configurationId": "1",
              "configurationName": "Test Scheme Action"
            }
          ]
        }
        """
        let testResults = try JSONDecoder().decode(XCTests.self, from: Data(json.utf8))
        #expect(testResults.devices.count == 1)
        #expect(testResults.testNodes.count == 1)
        let firstNode = try #require(testResults.testNodes.first)
        let children = firstNode.children ?? []
        #expect(children.count == 1)
        #expect(children.first?.nodeType == .testCase)
    }

    @Test
    func testXCResultToolInsightsModelDecoding() throws {
        let json = """
        {
          "commonFailureInsights": [],
          "failureDistributionInsights": [],
          "longestTestRunsInsights": []
        }
        """
        let insights = try JSONDecoder().decode(XCInsights.self, from: Data(json.utf8))
        #expect(insights.commonFailureInsights.isEmpty)
        #expect(insights.failureDistributionInsights.isEmpty)
        #expect(insights.longestTestRunsInsights.isEmpty)
    }

    @Test
    func testXCResultToolBuildResultsModelDecoding() throws {
        let json = """
        {
          "analyzerWarningCount": 0,
          "analyzerWarnings": [],
          "destination": {
            "architecture": "arm64",
            "deviceId": "00006000-001869EC3623801E",
            "deviceName": "My Mac",
            "modelName": "MacBook Pro",
            "osBuildNumber": "22C65",
            "osVersion": "13.1",
            "platform": "macOS"
          },
          "endTime": 1672825230.228,
          "errorCount": 0,
          "errors": [],
          "startTime": 1672825221.218,
          "status": "succeeded",
          "warningCount": 3,
          "warnings": [
            {
              "className": "DVTTextDocumentLocation",
              "issueType": "No-usage",
              "message": "Initialization warning",
              "sourceURL": "file:///tmp/example.swift#L1"
            }
          ]
        }
        """
        let buildResults = try JSONDecoder().decode(XCBuildResults.self, from: Data(json.utf8))
        #expect(buildResults.warningCount == 3)
        #expect(buildResults.warnings.count == 1)
        #expect(buildResults.destination.deviceName == "My Mac")
    }

    @Test
    func testXCResultToolTestDetailsModelDecoding() throws {
        let json = """
        {
          "devices": [
            {
              "architecture": "arm64",
              "deviceId": "00006000-001869EC3623801E",
              "deviceName": "My Mac",
              "modelName": "MacBook Pro",
              "osBuildNumber": "22C65",
              "osVersion": "13.1",
              "platform": "macOS"
            }
          ],
          "duration": "Ran for 2,8 seconds",
          "durationInSeconds": 2.8180439472198486,
          "hasMediaAttachments": false,
          "hasPerformanceMetrics": false,
          "testDescription": "Test case with 1 run",
          "testIdentifier": "XcresultparserTests/testCoverageConverter()",
          "testIdentifierURL": "test://com.apple.xcode/Xcresultparser/XcresultparserTests/XcresultparserTests/testCoverageConverter",
          "testName": "testCoverageConverter()",
          "testPlanConfigurations": [
            {
              "configurationId": "1",
              "configurationName": "Test Scheme Action"
            }
          ],
          "testResult": "Failed",
          "testRuns": [
            {
              "details": "macOS 13.1",
              "duration": "2s",
              "durationInSeconds": 2.8180439472198486,
              "name": "MacBook Pro",
              "nodeIdentifier": "00006000-001869EC3623801E",
              "nodeType": "Device",
              "result": "Failed"
            }
          ]
        }
        """
        let details = try JSONDecoder().decode(XCTestDetails.self, from: Data(json.utf8))
        #expect(details.testIdentifier == "XcresultparserTests/testCoverageConverter()")
        #expect(details.testRuns.count == 1)
        #expect(details.hasMediaAttachments == false)
    }

    @Test
    func testXCResultToolActivitiesModelDecoding() throws {
        let json = """
        {
          "testIdentifier": "XcresultparserTests/testCoverageConverter()",
          "testIdentifierURL": "test://com.apple.xcode/Xcresultparser/XcresultparserTests/XcresultparserTests/testCoverageConverter",
          "testName": "testCoverageConverter()",
          "testRuns": [
            {
              "activities": [
                {
                  "attachments": [
                    {
                      "lifetime": "",
                      "name": "Complete Issue Description.txt",
                      "uuid": "AB4FA017-B76D-490D-87D3-F55A5B9BE79E"
                    }
                  ],
                  "childActivities": [
                    {
                      "isAssociatedWithFailure": false,
                      "title": "Complete Issue Description"
                    }
                  ],
                  "isAssociatedWithFailure": true,
                  "startTime": 1672825226.088,
                  "title": "failed - Unable to create CoverageConverter"
                }
              ],
              "device": {
                "architecture": "arm64",
                "deviceId": "00006000-001869EC3623801E",
                "deviceName": "My Mac",
                "modelName": "MacBook Pro",
                "osBuildNumber": "22C65",
                "osVersion": "13.1",
                "platform": "macOS"
              },
              "testPlanConfiguration": {
                "configurationId": "1",
                "configurationName": "Test Scheme Action"
              }
            }
          ]
        }
        """
        let activities = try JSONDecoder().decode(XCActivities.self, from: Data(json.utf8))
        #expect(activities.testRuns.count == 1)
        #expect(activities.testRuns[0].activities.count == 1)
        #expect(activities.testRuns[0].device.deviceName == "My Mac")
    }

    @Test
    func testXCResultToolMetricsModelDecoding() throws {
        let json = """
        {
          "testIdentifier": "PerfTests/testExample()",
          "testIdentifierURL": "test://com.apple.xcode/PerfTests/testExample",
          "testRuns": [
            {
              "testPlanConfiguration": {
                "configurationId": "1",
                "configurationName": "Test Scheme Action"
              },
              "device": {
                "deviceId": "00006000-001869EC3623801E",
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
        let metrics = try JSONDecoder().decode(XCTestWithMetrics.self, from: Data(json.utf8))
        #expect(metrics.testRuns.count == 1)
        #expect(metrics.testRuns[0].metrics.count == 1)
        #expect(metrics.testRuns[0].metrics[0].displayName == "Clock Time")

        let emptyMetrics = try JSONDecoder().decode([XCTestWithMetrics].self, from: Data("[]".utf8))
        #expect(emptyMetrics.isEmpty)
    }

    // MARK: helper functions

    private func executionTimeValue(for xcresultFile: URL) -> String {
        guard let summary = try? XCResultToolClient().getTestSummary(path: xcresultFile),
              let start = summary.startTime,
              let finish = summary.finishTime else {
            return ""
        }
        let duration = max(0, finish - start)
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 4
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.unwrappedString(for: duration)
    }

    private func executionDateValue(for xcresultFile: URL) -> String {
        guard let summary = try? XCResultToolClient().getTestSummary(path: xcresultFile),
              let start = summary.startTime else {
            return ""
        }
        let date = Date(timeIntervalSince1970: start)
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: date)
    }

    private func makeJunitTest(
        identifier: String = "TestClass/testMethod",
        name: String = "testMethod",
        duration: Double = 0.5
    ) -> JunitTest {
        JunitTest(
            identifier: identifier,
            name: name,
            duration: duration,
            isFailed: true,
            isSkipped: false
        )
    }

    private func makeJunitFailureSummary(
        testCaseName: String,
        message: String = "Assertion failed",
        issueType: String = "Assertion Failure"
    ) -> JunitFailureSummary {
        JunitFailureSummary(
            message: message,
            testCaseName: testCaseName,
            issueType: issueType,
            producingTarget: nil,
            documentLocation: nil
        )
    }

    func assertXmlTestReportsAreEqual(
        expectedFileName: String,
        actual: XmlSerializable,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let expectedResultFile = Bundle.module.url(forResource: expectedFileName, withExtension: "xml")!

        let actualXMLDocument = try XMLDocument(data: Data("\(actual.xmlString)\n".utf8), options: [])
        let expectedXMLDocument = try XMLDocument(contentsOf: expectedResultFile, options: [])

        // Use consistent formatting options for comparison
        let formatOptions: XMLDocument.Options = [.nodePrettyPrint, .nodeCompactEmptyElement]
        let expectedXMLString = expectedXMLDocument.xmlString(options: formatOptions)
        let actualXMLString = actualXMLDocument.xmlString(options: formatOptions)

        #expect(expectedXMLString == actualXMLString)
    }

}

class MockedFileManager: FileManaging {
    var fileExists = true
    var isPathDirectory = true

    init(fileExists: Bool, isPathDirectory: Bool) {
        self.fileExists = fileExists
        self.isPathDirectory = isPathDirectory
    }

    func fileExists(atPath path: String, isDirectory: UnsafeMutablePointer<ObjCBool>?) -> Bool {
        if let isDirectory {
            isDirectory.pointee = ObjCBool(isPathDirectory)
        }
        return fileExists
    }
}

class MockedShell: Commandline {
    var response = Data()
    var error: Error?
    var argumentValidation: ([String]) -> Bool = { _ in true }

    init(response: Data, error: Error?) {
        self.response = response
        self.error = error
    }

    func execute(program: String, with arguments: [String], at executionPath: URL?) throws -> Data {
        if !argumentValidation(arguments) {
            throw NSError(domain: "error", code: 17)
        }
        if let error {
            throw error
        } else {
            return response
        }
    }
}
