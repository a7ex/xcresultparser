import XCTest
@testable import XcresultparserLib

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

    func testCoverageConverter() throws {
        let xcresultFile = Bundle.module.url(forResource: "test", withExtension: "xcresult")!
        let projectRoot = ""
        let quiet = 1

        guard let converter = SonarCoverageConverter(with: xcresultFile,
                                                     projectRoot: projectRoot) else {
            XCTFail("Unable to create CoverageConverter from \(xcresultFile)")
            return
        }
        let rslt = try converter.xmlString(quiet: quiet == 1)
        XCTAssertTrue(rslt.starts(with: "<coverage version=\"1\">"))
    }

    func testJunitXMLSonar() throws {
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
        assertXmlTestReportsAreEqual(expectedFileName: "sonarTestExecution", actual: junitXML)
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
        assertXmlTestReportsAreEqual(expectedFileName: "junit", actual: junitXML)
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

        sut = OutputFormat(string: "")
        XCTAssertEqual(OutputFormat.cli, sut)

        sut = OutputFormat(string: "xyz")
        XCTAssertEqual(OutputFormat.cli, sut)
    }
    
    // MARK: helper functions
    
    func assertXmlTestReportsAreEqual(expectedFileName: String, actual: XmlSerializable) {
        
        let expectedResultFile =  Bundle.module.url(forResource: expectedFileName, withExtension: "xml")!

        let actualXMLDocument = try! XMLDocument.init(data: Data("\(actual.xmlString)\n".utf8), options: [])
        let expectedXMLDocument = try! XMLDocument.init(contentsOf: expectedResultFile, options: [])

        XCTAssertEqual(actualXMLDocument.xmlString, expectedXMLDocument.xmlString)
    }
}
