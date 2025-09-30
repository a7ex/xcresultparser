import Foundation
@testable import XcresultparserLib
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
    func testCoberturaDTDCompliance() throws {
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
        
        let xmlString = try converter.xmlString(quiet: true)
        let xmlDocument = try XMLDocument(data: Data(xmlString.utf8), options: [])
        
        // Test root coverage element exists
        guard let rootElement = xmlDocument.rootElement(), rootElement.name == "coverage" else {
            Issue.record("Root element should be 'coverage'")
            return
        }
        
        // Test DTD compliance: integer attributes
        let linesCovered = rootElement.attribute(forName: "lines-covered")?.stringValue ?? ""
        let linesValid = rootElement.attribute(forName: "lines-valid")?.stringValue ?? ""
        let branchesCovered = rootElement.attribute(forName: "branches-covered")?.stringValue ?? ""
        let branchesValid = rootElement.attribute(forName: "branches-valid")?.stringValue ?? ""
        
        // Verify these are integers, not floats like "1.0"
        #expect(Int(linesCovered) != nil, "lines-covered should be integer, got: \(linesCovered)")
        #expect(Int(linesValid) != nil, "lines-valid should be integer, got: \(linesValid)")
        #expect(Int(branchesCovered) != nil, "branches-covered should be integer, got: \(branchesCovered)")
        #expect(Int(branchesValid) != nil, "branches-valid should be integer, got: \(branchesValid)")
        
        // Test DTD compliance: decimal rates with reasonable precision
        let lineRate = rootElement.attribute(forName: "line-rate")?.stringValue ?? ""
        let branchRate = rootElement.attribute(forName: "branch-rate")?.stringValue ?? ""
        
        #expect(Double(lineRate) != nil, "line-rate should be decimal, got: \(lineRate)")
        #expect(Double(branchRate) != nil, "branch-rate should be decimal, got: \(branchRate)")
        
        // Verify precision is reasonable (not excessive)
        let linePrecision = lineRate.split(separator: ".").last?.count ?? 0
        let branchPrecision = branchRate.split(separator: ".").last?.count ?? 0
        #expect(linePrecision <= 6, "line-rate precision should be <= 6 digits, got: \(linePrecision)")
        #expect(branchPrecision <= 6, "branch-rate precision should be <= 6 digits, got: \(branchPrecision)")
        
        // Test version is sensible (not "diff_coverage 0.1")
        let version = rootElement.attribute(forName: "version")?.stringValue ?? ""
        #expect(!version.contains("diff_coverage"), "version should not contain 'diff_coverage', got: \(version)")
        #expect(version.contains("xcresultparser"), "version should contain 'xcresultparser', got: \(version)")
        
        // Test timestamp is integer epoch seconds (not float like 1672825221.218)
        let timestamp = rootElement.attribute(forName: "timestamp")?.stringValue ?? ""
        #expect(Int(timestamp) != nil, "timestamp should be integer epoch seconds, got: \(timestamp)")
        #expect(!timestamp.contains("."), "timestamp should not have decimal point, got: \(timestamp)")
        
        // Verify branch values are 0 (since we don't track branches)
        #expect(branchesCovered == "0", "branches-covered should be 0, got: \(branchesCovered)")
        #expect(branchesValid == "0", "branches-valid should be 0, got: \(branchesValid)")
        #expect(branchRate == "0.000000", "branch-rate should be 0.000000, got: \(branchRate)")
    }
    
    @Test
    func testCoberturaPathNormalizationWithCoverageBasePath() throws {
        let xcresultFile = Bundle.module.url(forResource: "test", withExtension: "xcresult")!
        let projectRoot = ""
        let coverageBasePath = "/Users/test/workspace"
        let sourcesRoot = "."

        guard let converter = CoberturaCoverageConverter(
            with: xcresultFile,
            projectRoot: projectRoot,
            strictPathnames: false,
            coverageBasePath: coverageBasePath,
            sourcesRoot: sourcesRoot
        ) else {
            Issue.record("Unable to create CoverageConverter with new parameters")
            return
        }
        
        let xmlString = try converter.xmlString(quiet: true)
        let xmlDocument = try XMLDocument(data: Data(xmlString.utf8), options: [])
        
        // Test sources root is used
        guard let rootElement = xmlDocument.rootElement(),
              let sourcesElement = rootElement.elements(forName: "sources").first,
              let sourceElement = sourcesElement.elements(forName: "source").first,
              let sourceValue = sourceElement.stringValue else {
            Issue.record("Could not find sources/source element")
            return
        }
        
        #expect(sourceValue == sourcesRoot, "source value should match sourcesRoot, got: \(sourceValue)")
    }
    
    @Test
    func testCoberturaXMLWellFormedness() throws {
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
        
        let xmlString = try converter.xmlString(quiet: true)
        
        // Test that XML is well-formed
        _ = try XMLDocument(data: Data(xmlString.utf8), options: [])
        
        // Test that DOCTYPE is present and correct
        #expect(xmlString.contains("<!DOCTYPE coverage SYSTEM"), "XML should contain DOCTYPE declaration")
        #expect(xmlString.contains("coverage-04.dtd"), "XML should reference coverage-04.dtd")
        
        // Test basic structure is present
        #expect(xmlString.contains("<coverage"), "XML should contain coverage element")
        #expect(xmlString.contains("<sources>"), "XML should contain sources element")
        #expect(xmlString.contains("<packages>"), "XML should contain packages element")
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
