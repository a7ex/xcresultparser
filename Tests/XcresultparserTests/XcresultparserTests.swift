import Foundation
@testable import XcresultparserLib
import XCResultKit
import Testing

@MainActor
struct XcresultparserTests {
    @Test
    func testTextResultFormatter() throws {
        let xcresultFile = Bundle.module.url(forResource: "test", withExtension: "xcresult")!

        guard let resultParser = XCResultFormatter(
            with: xcresultFile,
            formatter: TextResultFormatter(),
            coverageTargets: []
        ) else {
            Issue.record("Unable to create XCResultFormatter with \(xcresultFile)")
            return
        }
        #expect(resultParser.documentPrefix(title: "XCResults") == "")

        let expectedSummary = """
        Summary
          Number of errors = 0
          Number of warnings = 3
          Number of analyzer warnings = 0
          Number of tests = 7
          Number of failed tests = 1
          Number of skipped tests = 0
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

        guard let resultParser = XCResultFormatter(
            with: xcresultFile,
            formatter: TextResultFormatter(),
            coverageTargets: [],
            coverageReportFormat: .totals
        ) else {
            Issue.record("Unable to create XCResultFormatter with \(xcresultFile)")
            return
        }
        #expect("" == resultParser.documentPrefix(title: "XCResults"))

        let expectedSummary = """
        Summary
          Number of errors = 0
          Number of warnings = 3
          Number of analyzer warnings = 0
          Number of tests = 7
          Number of failed tests = 1
          Number of skipped tests = 0
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

        guard let resultParser = XCResultFormatter(
            with: xcresultFile,
            formatter: TextResultFormatter(),
            coverageTargets: [],
            coverageReportFormat: .methods
        ) else {
            Issue.record("Unable to create XCResultFormatter with \(xcresultFile)")
            return
        }
        #expect(resultParser.documentPrefix(title: "XCResults") == "")

        let expectedSummary = """
        Summary
          Number of errors = 0
          Number of warnings = 3
          Number of analyzer warnings = 0
          Number of tests = 7
          Number of failed tests = 1
          Number of skipped tests = 0
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
    func testCLIResultFormatter() throws {
        let xcresultFile = Bundle.module.url(forResource: "test", withExtension: "xcresult")!

        guard let resultParser = XCResultFormatter(
            with: xcresultFile,
            formatter: CLIResultFormatter(),
            coverageTargets: []
        ) else {
            Issue.record("Unable to create XCResultFormatter with \(xcresultFile)")
            return
        }
        #expect(resultParser.documentPrefix(title: "XCResults") == "")

        let expectedSummary = """
        \u{001B}[1mSummary\u{001B}[0m
          Number of errors = 0\u{001B}[0m
        \u{001B}[33m  Number of warnings = 3\u{001B}[0m
          Number of analyzer warnings = 0\u{001B}[0m
          Number of tests = 7\u{001B}[0m
        \u{001B}[31m  Number of failed tests = 1\u{001B}[0m
          Number of skipped tests = 0\u{001B}[0m
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

        guard let resultParser = XCResultFormatter(
            with: xcresultFile,
            formatter: HTMLResultFormatter(),
            coverageTargets: []
        ) else {
            Issue.record("Unable to create XCResultFormatter with \(xcresultFile)")
            return
        }
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
        """
        #expect(resultParser.summary == expectedSummary)
        #expect(resultParser.divider == "<hr>")
        #expect(resultParser.testDetails.starts(with: "<h2>Test Scheme Action</h2>"))
        #expect(resultParser.coverageDetails.starts(with: "<h2>Coverage report</h2>"))
        #expect(resultParser.documentSuffix.hasSuffix("</html>"))
    }

    @Test
    func testMDResultFormatter() throws {
        let xcresultFile = Bundle.module.url(forResource: "test", withExtension: "xcresult")!

        guard let resultParser = XCResultFormatter(
            with: xcresultFile,
            formatter: MDResultFormatter(),
            coverageTargets: []
        ) else {
            Issue.record("Unable to create XCResultFormatter with \(xcresultFile)")
            return
        }
        #expect(resultParser.documentPrefix(title: "XCResults") == "")

        let expectedSummary = "Errors: 0; Warnings: 3; Analyzer Warnings: 0; Tests: 7; Failed: 1; Skipped: 0"
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

    @Test(arguments: [true, false])
    func testCoverageConverter(strictPathnames: Bool) throws {
        let xcresultFile = Bundle.module.url(forResource: "test", withExtension: "xcresult")!
        let projectRoot = ""

        guard let converter = CoverageConverter(
            with: xcresultFile,
            projectRoot: projectRoot,
            strictPathnames: strictPathnames
        ) else {
            Issue.record("Unable to create CoverageConverter from \(xcresultFile)")
            return
        }
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

    @Test(arguments: [true, false])
    func testCoverageConverterPathnames(strictPathnames: Bool) throws {
        let xcresultFile = Bundle.module.url(forResource: "test", withExtension: "xcresult")!
        let projectRoot = "/Users/notexistant/code/xcresultparser"

        guard let converter = SonarCoverageConverter(
            with: xcresultFile,
            projectRoot: projectRoot,
            strictPathnames: strictPathnames
        ) else {
            Issue.record("Unable to create CoverageConverter from \(xcresultFile)")
            return
        }

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

        guard let converter = SonarCoverageConverter(
            with: xcresultFile,
            projectRoot: projectRoot,
            strictPathnames: strictPathnames
        ) else {
            Issue.record("Unable to create CoverageConverter from \(xcresultFile)")
            return
        }
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
    func testSonarCoverageConverterExcludeFiles() throws {
        let xcresultFile = Bundle.module.url(forResource: "test", withExtension: "xcresult")!
        let projectRoot = ""
        let quiet = 1

        guard let converter = SonarCoverageConverter(
            with: xcresultFile,
            projectRoot: projectRoot,
            excludedPaths: ["OutputFormatting/Formatters"],
            strictPathnames: false
        ) else {
            Issue.record("Unable to create CoverageConverter from \(xcresultFile)")
            return
        }
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

        guard let converter = CoberturaCoverageConverter(
            with: xcresultFile,
            projectRoot: projectRoot,
            strictPathnames: false
        ) else {
            Issue.record("Unable to create CoverageConverter from \(xcresultFile)")
            return
        }
        try assertXmlTestReportsAreEqual(expectedFileName: "cobertura", actual: converter)
    }

    @Test
    func testCoberturaConverterExcludeFiles() throws {
        let xcresultFile = Bundle.module.url(forResource: "test", withExtension: "xcresult")!
        let projectRoot = ""

        guard let converter = CoberturaCoverageConverter(
            with: xcresultFile,
            projectRoot: projectRoot,
            excludedPaths: ["OutputFormatting/Formatters"],
            strictPathnames: false
        ) else {
            Issue.record("Unable to create CoverageConverter from \(xcresultFile)")
            return
        }
        try assertXmlTestReportsAreEqual(expectedFileName: "coberturaExcludingDirectory", actual: converter)
    }

    @Test
    func testJunitXMLSonar() throws {
        JunitXML.resetCachedPathnames()
        let xcresultFile = Bundle.module.url(forResource: "test", withExtension: "xcresult")!
        let projectRoot = ""
        guard let junitXML = JunitXML(
            with: xcresultFile,
            projectRoot: projectRoot,
            format: .sonar
        ) else {
            Issue.record("Unable to create JunitXML from \(xcresultFile)")
            return
        }
        try assertXmlTestReportsAreEqual(expectedFileName: "sonarTestExecution", actual: junitXML)
    }

    @Test
    func testJunitXMLSonarRelativePaths() throws {
        JunitXML.resetCachedPathnames()
        let cliResult = """
        ./Tests/XcresultparserTests.swift:class XcresultparserTests
        """
        let savedFilemanger = SharedInstances.fileManager
        let savedShellFactory = DependencyFactory.createShell

        SharedInstances.fileManager = MockedFileManager(fileExists: true, isPathDirectory: true)

        let mockedShell = MockedShell(response: Data(cliResult.utf8), error: nil)
        DependencyFactory.createShell = {
            mockedShell
        }
        mockedShell.argumentValidation = { arguments in
            return arguments.last == "."
        }

        let xcresultFile = Bundle.module.url(forResource: "test", withExtension: "xcresult")!
        let projectRoot = "/Users/imaginary/project"
        guard let junitXML = JunitXML(
            with: xcresultFile,
            projectRoot: projectRoot,
            format: .sonar,
            relativePathNames: true
        ) else {
            Issue.record("Unable to create JunitXML from \(xcresultFile)")
            return
        }
        try assertXmlTestReportsAreEqual(expectedFileName: "sonarTestExecutionWithProjectRootRelative", actual: junitXML)

        SharedInstances.fileManager = savedFilemanger
        DependencyFactory.createShell = savedShellFactory
    }

    @Test
    func testJunitXMLSonarAbsolutePaths() throws {
        JunitXML.resetCachedPathnames()
        let cliResult = """
        /Users/actual/project/Tests/XcresultparserTests.swift:class XcresultparserTests
        """

        let savedFilemanger = SharedInstances.fileManager
        let savedShellFactory = DependencyFactory.createShell

        SharedInstances.fileManager = MockedFileManager(fileExists: true, isPathDirectory: true)

        let mockedShell = MockedShell(response: Data(cliResult.utf8), error: nil)
        DependencyFactory.createShell = {
            mockedShell
        }
        mockedShell.argumentValidation = { arguments in
            return arguments.last != "."
        }

        let xcresultFile = Bundle.module.url(forResource: "test", withExtension: "xcresult")!
        let projectRoot = "/Users/imaginary/project"
        guard let junitXML = JunitXML(
            with: xcresultFile,
            projectRoot: projectRoot,
            format: .sonar,
            relativePathNames: false
        ) else {
            Issue.record("Unable to create JunitXML from \(xcresultFile)")
            return
        }
        try assertXmlTestReportsAreEqual(expectedFileName: "sonarTestExecutionWithProjectRootAbsolute", actual: junitXML)

        SharedInstances.fileManager = savedFilemanger
        DependencyFactory.createShell = savedShellFactory
    }

    @Test
    func testJunitXMLJunit() throws {
        let xcresultFile = Bundle.module.url(forResource: "test", withExtension: "xcresult")!
        let projectRoot = ""
        guard let junitXML = JunitXML(
            with: xcresultFile,
            projectRoot: projectRoot,
            format: .junit
        ) else {
            Issue.record("Unable to create JunitXML from \(xcresultFile)")
            return
        }
        try assertXmlTestReportsAreEqual(expectedFileName: "junit", actual: junitXML)
    }

    @Test
    func testJunitXMLMergedJunit() throws {
        let xcresultFile = Bundle.module.url(forResource: "test_merged", withExtension: "xcresult")!
        let projectRoot = ""
        guard let junitXML = JunitXML(
            with: xcresultFile,
            projectRoot: projectRoot,
            format: .junit
        ) else {
            Issue.record("Unable to create JunitXML from \(xcresultFile)")
            return
        }
        try assertXmlTestReportsAreEqual(expectedFileName: "junit_merged", actual: junitXML)
    }

    @Test
    func testJunitXMLRepeated() throws {
        let xcresultFile = Bundle.module.url(forResource: "test_repeated", withExtension: "xcresult")!
        let projectRoot = ""
        guard let junitXML = JunitXML(
            with: xcresultFile,
            projectRoot: projectRoot,
            format: .junit
        ) else {
            Issue.record("Unable to create JunitXML from \(xcresultFile)")
            return
        }
        try assertXmlTestReportsAreEqual(expectedFileName: "junit_repeated", actual: junitXML)
    }

    @Test
    func testFailureSummariesReturnsAllMatchingFailures() throws {
        let testMetadata = try makeTestMetadata()

        let matchingFailure1 = try makeFailureSummary(
            testCaseName: "TestClass.testMethod",
            message: "First assertion failed"
        )
        let matchingFailure2 = try makeFailureSummary(
            testCaseName: "TestClass.testMethod",
            message: "Second assertion failed"
        )
        let nonMatchingFailure = try makeFailureSummary(
            testCaseName: "OtherClass.otherMethod",
            message: "Unrelated failure"
        )

        let result = testMetadata.failureSummaries(in: [matchingFailure1, nonMatchingFailure, matchingFailure2])

        #expect(result.count == 2)
        #expect(result[0].message == "First assertion failed")
        #expect(result[1].message == "Second assertion failed")
    }

    @Test
    func testFailureSummariesWithBracketNotation() throws {
        let testMetadata = try makeTestMetadata()

        // Objective-C bracket notation: -[TestClass testMethod]
        let bracketFailure1 = try makeFailureSummary(
            testCaseName: "-[TestClass testMethod]",
            message: "Bracket notation failure 1"
        )
        let bracketFailure2 = try makeFailureSummary(
            testCaseName: "-[TestClass testMethod]",
            message: "Bracket notation failure 2"
        )

        let result = testMetadata.failureSummaries(in: [bracketFailure1, bracketFailure2])

        #expect(result.count == 2)
        #expect(result[0].message == "Bracket notation failure 1")
        #expect(result[1].message == "Bracket notation failure 2")
    }

    @Test
    func testFailureSummariesReturnsEmptyForNoMatches() throws {
        let testMetadata = try makeTestMetadata()
        let nonMatchingFailure = try makeFailureSummary(
            testCaseName: "OtherClass.otherMethod",
            message: "Unrelated failure"
        )

        let result = testMetadata.failureSummaries(in: [nonMatchingFailure])

        #expect(result.isEmpty)
    }

    @Test
    func testFailureSummariesWithEmptyArray() throws {
        let testMetadata = try makeTestMetadata()

        let result = testMetadata.failureSummaries(in: [])

        #expect(result.isEmpty)
    }

    @Test
    func testCleanCodeWarnings() throws {
        let xcresultFile = Bundle.module.url(forResource: "test", withExtension: "xcresult")!
        guard let converter = IssuesJSON(with: xcresultFile) else {
            Issue.record("Unable to create warnings json from \(xcresultFile)")
            return
        }
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
        guard let converter = IssuesJSON(with: xcresultFile, projectRoot: "xcresultparser/") else {
            Issue.record("Unable to create warnings json from \(xcresultFile)")
            return
        }
        let rslt = try converter.jsonString(format: .warnings, quiet: true)
        let result = try JSONDecoder().decode([XcresultparserLib.Issue].self, from: Data(rslt.utf8))
            .sorted { lhs, rhs in
                lhs.location.path > rhs.location.path
            }
        #expect(result.first?.location.path == "Tests/XcresultparserTests/XcresultparserTests.swift")
    }

    func testCleanCodeWarningsExcludingFiles() throws {
        let xcresultFile = Bundle.module.url(forResource: "test", withExtension: "xcresult")!
        guard let converter = IssuesJSON(with: xcresultFile, excludedPaths: ["Tests/XcresultparserTests"]) else {
            Issue.record("Unable to create warnings json from \(xcresultFile)")
            return
        }
        let rslt = try converter.jsonString(format: .warnings, quiet: true)
        let result = try JSONDecoder().decode([XcresultparserLib.Issue].self, from: Data(rslt.utf8))
        #expect(result.count == 0)
    }

    @Test
    func testCleanCodeNoErrors() throws {
        let xcresultFile = Bundle.module.url(forResource: "test", withExtension: "xcresult")!
        guard let converter = IssuesJSON(with: xcresultFile) else {
            Issue.record("Unable to create warnings json from \(xcresultFile)")
            return
        }
        let rslt = try converter.jsonString(format: .errors, quiet: true)
        #expect(rslt == "[\n\n]")
    }

    @Test
    func testCleanCodeErrors() throws {
        let xcresultFile = Bundle.module.url(forResource: "resultWithCompileError", withExtension: "xcresult")!
        guard let converter = IssuesJSON(with: xcresultFile) else {
            Issue.record("Unable to create warnings json from \(xcresultFile)")
            return
        }
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

    // MARK: helper functions

    private func makeTestMetadata(
        identifier: String = "TestClass/testMethod",
        name: String = "testMethod",
        status: String = "Failure",
        duration: String = "0.5"
    ) throws -> ActionTestMetadata {
        let json: [String: AnyObject] = [
            "_type": ["_name": "ActionTestMetadata"] as AnyObject,
            "identifier": ["_type": ["_name": "String"], "_value": identifier] as AnyObject,
            "name": ["_type": ["_name": "String"], "_value": name] as AnyObject,
            "testStatus": ["_type": ["_name": "String"], "_value": status] as AnyObject,
            "duration": ["_type": ["_name": "Double"], "_value": duration] as AnyObject
        ]
        return try #require(ActionTestMetadata(json))
    }

    private func makeFailureSummary(
        testCaseName: String,
        message: String = "Assertion failed",
        issueType: String = "Assertion Failure"
    ) throws -> TestFailureIssueSummary {
        let json: [String: AnyObject] = [
            "_type": ["_name": "TestFailureIssueSummary"] as AnyObject,
            "testCaseName": ["_type": ["_name": "String"], "_value": testCaseName] as AnyObject,
            "issueType": ["_type": ["_name": "String"], "_value": issueType] as AnyObject,
            "message": ["_type": ["_name": "String"], "_value": message] as AnyObject
        ]
        return try #require(TestFailureIssueSummary(json))
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
