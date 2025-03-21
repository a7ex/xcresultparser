@testable import XcresultparserLib
import XCTest

final class XcresultparserTests: XCTestCase {
    func testTextResultFormatter() throws {
        let xcresultFile = Bundle.module.url(forResource: "test", withExtension: "xcresult")!

        guard let resultParser = XCResultFormatter(
            with: xcresultFile,
            formatter: TextResultFormatter(),
            coverageTargets: []
        ) else {
            XCTFail("Unable to create XCResultFormatter with \(xcresultFile)")
            return
        }
        XCTAssertEqual("", resultParser.documentPrefix(title: "XCResults"))

        let expectedSummary = """
        Summary
          Number of errors = 0
          Number of warnings = 3
          Number of analyzer warnings = 0
          Number of tests = 7
          Number of failed tests = 1
          Number of skipped tests = 0
        """
        XCTAssertEqual(expectedSummary, resultParser.summary)
        XCTAssertEqual("---------------------\n", resultParser.divider)
        XCTAssertTrue(resultParser.testDetails.starts(with: "Test Scheme Action"))

        XCTAssertTrue(resultParser.coverageDetails.starts(with: "Coverage report"))
        XCTAssertEqual("", resultParser.documentSuffix)
    }

    func testTextResultFormatterTotalCoverageReportFormat() throws {
        let xcresultFile = Bundle.module.url(forResource: "test", withExtension: "xcresult")!

        guard let resultParser = XCResultFormatter(
            with: xcresultFile,
            formatter: TextResultFormatter(),
            coverageTargets: [],
            coverageReportFormat: .totals
        ) else {
            XCTFail("Unable to create XCResultFormatter with \(xcresultFile)")
            return
        }
        XCTAssertEqual("", resultParser.documentPrefix(title: "XCResults"))

        let expectedSummary = """
        Summary
          Number of errors = 0
          Number of warnings = 3
          Number of analyzer warnings = 0
          Number of tests = 7
          Number of failed tests = 1
          Number of skipped tests = 0
        """
        XCTAssertEqual(expectedSummary, resultParser.summary)
        XCTAssertEqual("---------------------\n", resultParser.divider)
        XCTAssertTrue(resultParser.testDetails.starts(with: "Test Scheme Action"))

        let lines = resultParser.coverageDetails.components(separatedBy: "\n")
        XCTAssertEqual(2, lines.count)
        XCTAssertEqual("Coverage report", lines.first)
        XCTAssertTrue(lines.last?.starts(with: "Total coverage:") == true)
    }

    func testTextResultFormatterMethodsCoverageReportFormat() throws {
        let xcresultFile = Bundle.module.url(forResource: "test", withExtension: "xcresult")!

        guard let resultParser = XCResultFormatter(
            with: xcresultFile,
            formatter: TextResultFormatter(),
            coverageTargets: [],
            coverageReportFormat: .methods
        ) else {
            XCTFail("Unable to create XCResultFormatter with \(xcresultFile)")
            return
        }
        XCTAssertEqual("", resultParser.documentPrefix(title: "XCResults"))

        let expectedSummary = """
        Summary
          Number of errors = 0
          Number of warnings = 3
          Number of analyzer warnings = 0
          Number of tests = 7
          Number of failed tests = 1
          Number of skipped tests = 0
        """
        XCTAssertEqual(expectedSummary, resultParser.summary)
        XCTAssertEqual("---------------------\n", resultParser.divider)
        XCTAssertTrue(resultParser.testDetails.starts(with: "Test Scheme Action"))

        let lines = resultParser.coverageDetails.components(separatedBy: "\n")
        XCTAssertEqual(473, lines.count)
        XCTAssertEqual("Coverage report", lines.first)
        XCTAssertTrue(lines[1].starts(with: "Total coverage:") == true)
        XCTAssertTrue(lines[2].starts(with: "XcresultparserLib:") == true)
        XCTAssertTrue(lines[3].contains("CLIResultFormatter.swift:") == true)
    }

    func testCLIResultFormatter() throws {
        let xcresultFile = Bundle.module.url(forResource: "test", withExtension: "xcresult")!

        guard let resultParser = XCResultFormatter(
            with: xcresultFile,
            formatter: CLIResultFormatter(),
            coverageTargets: []
        ) else {
            XCTFail("Unable to create XCResultFormatter with \(xcresultFile)")
            return
        }
        XCTAssertEqual("", resultParser.documentPrefix(title: "XCResults"))

        let expectedSummary = """
        \u{001B}[1mSummary\u{001B}[0m
          Number of errors = 0\u{001B}[0m
        \u{001B}[33m  Number of warnings = 3\u{001B}[0m
          Number of analyzer warnings = 0\u{001B}[0m
          Number of tests = 7\u{001B}[0m
        \u{001B}[31m  Number of failed tests = 1\u{001B}[0m
          Number of skipped tests = 0\u{001B}[0m
        """
        XCTAssertEqual(expectedSummary, resultParser.summary)
        XCTAssertEqual("-----------------\n", resultParser.divider)

        XCTAssertTrue(resultParser.testDetails.starts(with: "\u{001B}[1mTest Scheme Action\u{001B}[0m"))

        XCTAssertTrue(resultParser.coverageDetails.starts(with: "\u{001B}[1mCoverage report\u{001B}[0m"))

        XCTAssertEqual("", resultParser.documentSuffix)
    }

    func testHTMLResultFormatter() throws {
        let xcresultFile = Bundle.module.url(forResource: "test", withExtension: "xcresult")!

        guard let resultParser = XCResultFormatter(
            with: xcresultFile,
            formatter: HTMLResultFormatter(),
            coverageTargets: []
        ) else {
            XCTFail("Unable to create XCResultFormatter with \(xcresultFile)")
            return
        }
        let documentPrefix = """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="utf-8">
            <title>XCResults</title>
        """
        XCTAssertTrue(resultParser.documentPrefix(title: "XCResults").starts(with: documentPrefix))

        let expectedSummary = """
        <h2>Summary</h2>
        <p class="resultSummaryLineSuccess">Number of errors = 0</p>
        <p class="resultSummaryLineWarning">Number of warnings = 3</p>
        <p class="resultSummaryLineSuccess">Number of analyzer warnings = 0</p>
        <p class="resultSummaryLineSuccess">Number of tests = 7</p>
        <p class="resultSummaryLineFailed">Number of failed tests = 1</p>
        <p class="resultSummaryLineSuccess">Number of skipped tests = 0</p>
        """
        XCTAssertEqual(expectedSummary, resultParser.summary)
        XCTAssertEqual("<hr>", resultParser.divider)
        XCTAssertTrue(resultParser.testDetails.starts(with: "<h2>Test Scheme Action</h2>"))
        XCTAssertTrue(resultParser.coverageDetails.starts(with: "<h2>Coverage report</h2>"))
        XCTAssertTrue(resultParser.documentSuffix.hasSuffix("</html>"))
    }

    func testMDResultFormatter() throws {
        let xcresultFile = Bundle.module.url(forResource: "test", withExtension: "xcresult")!

        guard let resultParser = XCResultFormatter(
            with: xcresultFile,
            formatter: MDResultFormatter(),
            coverageTargets: []
        ) else {
            XCTFail("Unable to create XCResultFormatter with \(xcresultFile)")
            return
        }
        XCTAssertEqual("", resultParser.documentPrefix(title: "XCResults"))

        let expectedSummary = "Errors: 0; Warnings: 3; Analyzer Warnings: 0; Tests: 7; Failed: 1; Skipped: 0"
        XCTAssertEqual(expectedSummary, resultParser.summary)
        XCTAssertEqual("\n---------------------\n", resultParser.divider)

        let lines = resultParser.testDetails.components(separatedBy: .newlines)
        XCTAssertTrue(lines[2].starts(with: "### XcresultparserTests.xctest"))
        XCTAssertTrue(lines[3].starts(with: "### XcresultparserTests"))
        XCTAssertTrue(lines[4].starts(with: "* <span"))

        let cLines = resultParser.coverageDetails.components(separatedBy: .newlines)
        XCTAssertTrue(cLines[1].starts(with: "Total coverage:"))
        XCTAssertTrue(cLines[2].starts(with: "XcresultparserLib:"))
        XCTAssertTrue(cLines[3].starts(with: "## CLIResultFormatter.swift:"))

        XCTAssertEqual("", resultParser.documentSuffix)
    }

    func testCoverageConverter() throws {
        let xcresultFile = Bundle.module.url(forResource: "test", withExtension: "xcresult")!
        let projectRoot = ""

        guard let converter = CoverageConverter(
            with: xcresultFile,
            projectRoot: projectRoot
        ) else {
            XCTFail("Unable to create CoverageConverter from \(xcresultFile)")
            return
        }
        let info = converter.targetsInfo
        XCTAssertEqual("\nXcresultparserLib\nXcresultparserTests", info)

        let fileCoverage = try converter.getCoverageDataAsJSON()
        XCTAssertEqual(13, fileCoverage.files.count)
        let firstKey = try XCTUnwrap(fileCoverage.files.keys.sorted().first)
        XCTAssertEqual(
            "/Users/fhaeser/code/xcresultparser/Sources/xcresultparser/CoberturaCoverageConverter.swift",
            firstKey
        )
        let firstItem = try XCTUnwrap(fileCoverage.files[firstKey])
        XCTAssertEqual(199, firstItem.count)
        let firstLineDetail = try XCTUnwrap(firstItem.first)
        XCTAssertFalse(firstLineDetail.isExecutable)
        XCTAssertEqual(1, firstLineDetail.line)
        XCTAssertNil(firstLineDetail.executionCount)
        XCTAssertNil(firstLineDetail.subranges)

        let otherLineDetail = firstItem[50]
        XCTAssertTrue(otherLineDetail.isExecutable)
        XCTAssertEqual(51, otherLineDetail.line)
        XCTAssertEqual(0, otherLineDetail.executionCount)
        XCTAssertNil(otherLineDetail.subranges)

        // Deprecated methods

        let fileList = try converter.coverageFileList()
        XCTAssertEqual(14, fileList.count)
        let firstFile = "/Users/fhaeser/code/xcresultparser/Sources/xcresultparser/CoberturaCoverageConverter.swift"
        XCTAssertEqual(firstFile, fileList.first)
        let coverageForFile = try converter.coverageForFile(path: firstFile)
        XCTAssertTrue(coverageForFile.starts(with: "  1: *\n  2: *\n  3: *"))
        XCTAssertTrue(coverageForFile.contains(" 35: 0"))
    }

    func testSonarCoverageConverter() throws {
        let xcresultFile = Bundle.module.url(forResource: "test", withExtension: "xcresult")!
        let projectRoot = ""
        let quiet = 1

        guard let converter = SonarCoverageConverter(
            with: xcresultFile,
            projectRoot: projectRoot
        ) else {
            XCTFail("Unable to create CoverageConverter from \(xcresultFile)")
            return
        }
        let rslt = try converter.xmlString(quiet: quiet == 1)
        XCTAssertTrue(rslt.starts(with: "<coverage version=\"1\">"))
        let lines = rslt.components(separatedBy: .newlines)
        XCTAssertEqual(1492, lines.count)
        let pos = try XCTUnwrap(lines.firstIndex(of: "<file path=\"/Users/fhaeser/code/xcresultparser/Sources/xcresultparser/OutputFormatting/Formatters/XCResultFormatting.swift\">"))
        XCTAssertEqual("    <lineToCover lineNumber=\"36\" covered=\"true\"/>", lines[pos + 1])
        XCTAssertEqual("    <lineToCover lineNumber=\"37\" covered=\"true\"/>", lines[pos + 2])

        let pos2 = try XCTUnwrap(lines.firstIndex(of: "<file path=\"/Users/fhaeser/code/xcresultparser/Sources/xcresultparser/Shell.swift\">"))
        XCTAssertEqual("    <lineToCover lineNumber=\"15\" covered=\"false\"/>", lines[pos2 + 1])
        XCTAssertEqual("    <lineToCover lineNumber=\"16\" covered=\"false\"/>", lines[pos2 + 2])
    }

    func testSonarCoverageConverterExcludeFiles() throws {
        let xcresultFile = Bundle.module.url(forResource: "test", withExtension: "xcresult")!
        let projectRoot = ""
        let quiet = 1

        guard let converter = SonarCoverageConverter(
            with: xcresultFile,
            projectRoot: projectRoot,
            excludedPaths: ["OutputFormatting/Formatters"]
        ) else {
            XCTFail("Unable to create CoverageConverter from \(xcresultFile)")
            return
        }
        let rslt = try converter.xmlString(quiet: quiet == 1)
        XCTAssertTrue(rslt.starts(with: "<coverage version=\"1\">"))
        let lines = rslt.components(separatedBy: .newlines)
        XCTAssertEqual(1082, lines.count)
        let pos = lines.firstIndex(of: "<file path=\"/Users/fhaeser/code/xcresultparser/Sources/xcresultparser/OutputFormatting/Formatters/XCResultFormatting.swift\">")
        XCTAssertNil(pos)

        let pos2 = try XCTUnwrap(lines.firstIndex(of: "<file path=\"/Users/fhaeser/code/xcresultparser/Sources/xcresultparser/Shell.swift\">"))
        XCTAssertEqual("    <lineToCover lineNumber=\"15\" covered=\"false\"/>", lines[pos2 + 1])
        XCTAssertEqual("    <lineToCover lineNumber=\"16\" covered=\"false\"/>", lines[pos2 + 2])
    }

    func testCoberturaConverter() throws {
        let xcresultFile = Bundle.module.url(forResource: "test", withExtension: "xcresult")!
        let projectRoot = ""

        guard let converter = CoberturaCoverageConverter(
            with: xcresultFile,
            projectRoot: projectRoot
        ) else {
            XCTFail("Unable to create CoverageConverter from \(xcresultFile)")
            return
        }
        try assertXmlTestReportsAreEqual(expectedFileName: "cobertura", actual: converter)
    }

    func testCoberturaConverterExcludeFiles() throws {
        let xcresultFile = Bundle.module.url(forResource: "test", withExtension: "xcresult")!
        let projectRoot = ""

        guard let converter = CoberturaCoverageConverter(
            with: xcresultFile,
            projectRoot: projectRoot,
            excludedPaths: ["OutputFormatting/Formatters"]
        ) else {
            XCTFail("Unable to create CoverageConverter from \(xcresultFile)")
            return
        }
        try assertXmlTestReportsAreEqual(expectedFileName: "coberturaExcludingDirectory", actual: converter)
    }

    func testJunitXMLSonar() throws {
        JunitXML.resetCachedPathnames()
        let xcresultFile = Bundle.module.url(forResource: "test", withExtension: "xcresult")!
        let projectRoot = ""
        guard let junitXML = JunitXML(
            with: xcresultFile,
            projectRoot: projectRoot,
            format: .sonar
        ) else {
            XCTFail("Unable to create JunitXML from \(xcresultFile)")
            return
        }
        try assertXmlTestReportsAreEqual(expectedFileName: "sonarTestExecution", actual: junitXML)
    }

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
            XCTFail("Unable to create JunitXML from \(xcresultFile)")
            return
        }
        try assertXmlTestReportsAreEqual(expectedFileName: "sonarTestExecutionWithProjectRootRelative", actual: junitXML)

        SharedInstances.fileManager = savedFilemanger
        DependencyFactory.createShell = savedShellFactory
    }

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
            XCTFail("Unable to create JunitXML from \(xcresultFile)")
            return
        }
        try assertXmlTestReportsAreEqual(expectedFileName: "sonarTestExecutionWithProjectRootAbsolute", actual: junitXML)

        SharedInstances.fileManager = savedFilemanger
        DependencyFactory.createShell = savedShellFactory
    }

    func testJunitXMLJunit() throws {
        let xcresultFile = Bundle.module.url(forResource: "test", withExtension: "xcresult")!
        let projectRoot = ""
        guard let junitXML = JunitXML(
            with: xcresultFile,
            projectRoot: projectRoot,
            format: .junit
        ) else {
            XCTFail("Unable to create JunitXML from \(xcresultFile)")
            return
        }
        try assertXmlTestReportsAreEqual(expectedFileName: "junit", actual: junitXML)
    }

    func testJunitXMLMergedJunit() throws {
        let xcresultFile = Bundle.module.url(forResource: "test_merged", withExtension: "xcresult")!
        let projectRoot = ""
        guard let junitXML = JunitXML(
            with: xcresultFile,
            projectRoot: projectRoot,
            format: .junit
        ) else {
            XCTFail("Unable to create JunitXML from \(xcresultFile)")
            return
        }
        try assertXmlTestReportsAreEqual(expectedFileName: "junit_merged", actual: junitXML)
    }

    func testJunitXMLRepeated() throws {
        let xcresultFile = Bundle.module.url(forResource: "test_repeated", withExtension: "xcresult")!
        let projectRoot = ""
        guard let junitXML = JunitXML(
            with: xcresultFile,
            projectRoot: projectRoot,
            format: .junit
        ) else {
            XCTFail("Unable to create JunitXML from \(xcresultFile)")
            return
        }
        try assertXmlTestReportsAreEqual(expectedFileName: "junit_repeated", actual: junitXML)
    }

    func testCleanCodeWarnings() throws {
        let xcresultFile = Bundle.module.url(forResource: "test", withExtension: "xcresult")!
        guard let converter = IssuesJSON(with: xcresultFile) else {
            XCTFail("Unable to create warnings json from \(xcresultFile)")
            return
        }
        let rslt = try converter.jsonString(format: .warnings, quiet: true)
        let result = try JSONDecoder().decode([Issue].self, from: Data(rslt.utf8))

        let expectedFile = Bundle.module.url(forResource: "warnings", withExtension: "json")!
        let expectedData = try Data(contentsOf: expectedFile)
        let expectedObject = try JSONDecoder().decode([Issue].self, from: expectedData)

        XCTAssertEqual(result.count, expectedObject.count)
        let first = try XCTUnwrap(result.first)
        let last = try XCTUnwrap(result.last)
        XCTAssertNotNil(expectedObject.first(where: { $0.checkName == first.checkName && $0.location == first.location }))
        XCTAssertNotNil(expectedObject.first(where: { $0.checkName == last.checkName && $0.location == last.location }))
    }

    func testCleanCodeWarningsWithRelativePath() throws {
        let xcresultFile = Bundle.module.url(forResource: "test", withExtension: "xcresult")!
        guard let converter = IssuesJSON(with: xcresultFile, projectRoot: "xcresultparser/") else {
            XCTFail("Unable to create warnings json from \(xcresultFile)")
            return
        }
        let rslt = try converter.jsonString(format: .warnings, quiet: true)
        let result = try JSONDecoder().decode([Issue].self, from: Data(rslt.utf8))
            .sorted { lhs, rhs in
                lhs.location.path > rhs.location.path
            }
        XCTAssertEqual("Tests/XcresultparserTests/XcresultparserTests.swift", result.first?.location.path)
    }

    func testCleanCodeWarningsExcludingFiles() throws {
        let xcresultFile = Bundle.module.url(forResource: "test", withExtension: "xcresult")!
        guard let converter = IssuesJSON(with: xcresultFile, excludedPaths: ["Tests/XcresultparserTests"]) else {
            XCTFail("Unable to create warnings json from \(xcresultFile)")
            return
        }
        let rslt = try converter.jsonString(format: .warnings, quiet: true)
        let result = try JSONDecoder().decode([Issue].self, from: Data(rslt.utf8))
        XCTAssertEqual(0, result.count)
    }

    func testCleanCodeNoErrors() throws {
        let xcresultFile = Bundle.module.url(forResource: "test", withExtension: "xcresult")!
        guard let converter = IssuesJSON(with: xcresultFile) else {
            XCTFail("Unable to create warnings json from \(xcresultFile)")
            return
        }
        let rslt = try converter.jsonString(format: .errors, quiet: true)
        XCTAssertEqual("[\n\n]", rslt)
    }

    func testCleanCodeErrors() throws {
        let xcresultFile = Bundle.module.url(forResource: "resultWithCompileError", withExtension: "xcresult")!
        guard let converter = IssuesJSON(with: xcresultFile) else {
            XCTFail("Unable to create warnings json from \(xcresultFile)")
            return
        }
        let rslt = try converter.jsonString(format: .errors, quiet: true)
        let result = try JSONDecoder().decode([Issue].self, from: Data(rslt.utf8))
            .sorted { lhs, rhs in
                lhs.location.path > rhs.location.path
            }
        XCTAssertEqual(2, result.count)
        let compileError = try XCTUnwrap(result.first)
        XCTAssertEqual("Swift Compiler Error • Cannot find 'xmlString1' in scope", compileError.description)
        XCTAssertEqual(.blocker, compileError.severity)
        XCTAssertTrue(compileError.location.path.contains("Sources/xcresultparser/CoberturaCoverageConverter.swift"))
        XCTAssertEqual(.issue, compileError.type)
        XCTAssertEqual("Swift Compiler Error • Cannot find 'xmlString1' in scope", compileError.content.body)
        XCTAssertEqual(0, compileError.categories.count)
    }

    func testOutputFormat() {
        var sut = OutputFormat(string: "txt")
        XCTAssertEqual(OutputFormat.txt, sut)

        sut = OutputFormat(string: "xml")
        XCTAssertEqual(OutputFormat.xml, sut)

        sut = OutputFormat(string: "html")
        XCTAssertEqual(OutputFormat.html, sut)

        sut = OutputFormat(string: "cli")
        XCTAssertEqual(OutputFormat.cli, sut)

        sut = OutputFormat(string: "cobertura")
        XCTAssertEqual(OutputFormat.cobertura, sut)

        sut = OutputFormat(string: "junit")
        XCTAssertEqual(OutputFormat.junit, sut)

        sut = OutputFormat(string: "md")
        XCTAssertEqual(OutputFormat.md, sut)

        sut = OutputFormat(string: "warnings")
        XCTAssertEqual(OutputFormat.warnings, sut)

        sut = OutputFormat(string: "errors")
        XCTAssertEqual(OutputFormat.errors, sut)

        sut = OutputFormat(string: "warnings-and-errors")
        XCTAssertEqual(OutputFormat.warningsAndErrors, sut)

        sut = OutputFormat(string: "")
        XCTAssertEqual(OutputFormat.cli, sut)

        sut = OutputFormat(string: "xyz")
        XCTAssertEqual(OutputFormat.cli, sut)
    }

    func testCoverageReportFormat() {
        var sut = CoverageReportFormat(string: "methods")
        XCTAssertEqual(CoverageReportFormat.methods, sut)

        sut = CoverageReportFormat(string: "classes")
        XCTAssertEqual(CoverageReportFormat.classes, sut)

        sut = CoverageReportFormat(string: "targets")
        XCTAssertEqual(CoverageReportFormat.targets, sut)

        sut = CoverageReportFormat(string: "totals")
        XCTAssertEqual(CoverageReportFormat.totals, sut)

        sut = CoverageReportFormat(string: "not existing")
        XCTAssertEqual(CoverageReportFormat.methods, sut)

        sut = CoverageReportFormat(string: "")
        XCTAssertEqual(CoverageReportFormat.methods, sut)

        sut = CoverageReportFormat(string: "Classes")
        XCTAssertEqual(CoverageReportFormat.classes, sut)

        sut = CoverageReportFormat(string: "CLASSES")
        XCTAssertEqual(CoverageReportFormat.classes, sut)

        sut = CoverageReportFormat(string: "clASSeS")
        XCTAssertEqual(CoverageReportFormat.classes, sut)
    }

    // MARK: helper functions

    func assertXmlTestReportsAreEqual(
        expectedFileName: String,
        actual: XmlSerializable,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let expectedResultFile = Bundle.module.url(forResource: expectedFileName, withExtension: "xml")!

        let actualXMLDocument = try XMLDocument(data: Data("\(actual.xmlString)\n".utf8), options: [])
        let expectedXMLDocument = try XMLDocument(contentsOf: expectedResultFile, options: [])

        XCTAssertEqual(actualXMLDocument.xmlString, expectedXMLDocument.xmlString, file: file, line: line)
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
