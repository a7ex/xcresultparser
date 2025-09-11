//
//  main.swift
//  xcresultparser
//
//  Created by Alex da Franca on 11.06.21.
//

import ArgumentParser
import Foundation
import XcresultparserLib

private let marketingVersion = "1.9.0"

struct xcresultparser: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "xcresultparser \(marketingVersion)\nInterpret binary .xcresult files and print summary in different formats: txt, xml, html or colored cli output."
    )

    @Option(name: .long, help: "The coverage report format. The Default is 'methods', It can either be 'totals', 'targets', 'classes' or 'methods'")
    var coverageReportFormat: String?

    @Option(name: .shortAndLong, help: "The output format. It can be either 'txt', 'cli', 'html', 'md', 'xml', 'junit', 'cobertura', 'warnings', 'errors' and 'warnings-and-errors'. In case of 'xml' sonar generic format for test results and generic format (Sonarqube) for coverage data is used. In the case of 'cobertura', --coverage is implied.")
    var outputFormat: String?

    @Option(name: .shortAndLong, help: "The name of the project root. If present paths and urls are relative to the specified directory.")
    var projectRoot: String?

    @Option(name: [.customShort("t"), .customLong("coverage-targets")], help: "Specify which targets to calculate coverage from. You can use more than one -t option to specify a list of targets.")
    var coverageTargets: [String] = []

    @Option(name: [.customShort("e"), .customLong("excluded-path")], help: "Specify which path names to exclude. You can use more than one -e option to specify a list of path patterns to exclude. This option only has effect, if the format is either 'cobertura' or 'xml' with the --coverage (-c) option for a code coverage report or if the format is one of 'warnings', 'errors' or 'warnings-and-errors'.")
    var excludedPaths: [String] = []

    @Option(name: .shortAndLong, help: "The fields in the summary. Default is all: errors|warnings|analyzerWarnings|tests|failed|skipped")
    var summaryFields: String?

    @Flag(name: .shortAndLong, help: "Whether to print coverage data.")
    var coverage: Int

    @Flag(name: [.customShort("x"), .customLong("exclude-coverage-not-in-project")], help: "Omit elements with file pathes, which do not contain 'projectRoot'.")
    var strictPathnames: Int

    @Flag(name: .shortAndLong, help: "Whether to print test results.")
    var noTestResult: Int

    @Flag(name: .shortAndLong, help: "Whether to only print failed tests.")
    var failedTestsOnly: Int

    @Flag(name: .shortAndLong, help: "Quiet. Don't print status output.")
    var quiet: Int

    @Flag(name: [.customShort("i"), .customLong("target-info")], help: "Just print the targets contained in the xcresult.")
    var printTargets: Int

    @Flag(name: .shortAndLong, help: "Show version number.")
    var version: Int

    @Argument(help: "The path to the .xcresult file.")
    var xcresultFile: String?

    mutating func run() throws {
        guard version != 1 else {
            print(marketingVersion)
            return
        }
        guard let xcresult = xcresultFile,
              !xcresult.isEmpty else {
            throw ParseError.argumentError
        }
        guard printTargets != 1 else {
            try outputTargetNames(for: xcresult)
            return
        }
        switch format {
        case .xml:
            if coverage == 1 {
                try outputSonarXML(for: xcresult)
            } else {
                try outputJUnitXML(for: xcresult, with: .sonar)
            }
        case .junit:
            try outputJUnitXML(for: xcresult, with: .junit)
        case .cobertura:
            coverage = 1
            try outputCoberturaXML(for: xcresult)
        case .cli, .md, .txt, .html:
            try outputDescription(for: xcresult)
        case .warnings, .errors, .warningsAndErrors:
            try outputIssuesJSON(for: xcresult, format: format)
        }
    }

    private func outputSonarXML(for xcresult: String) throws {
        guard let converter = SonarCoverageConverter(
            with: URL(fileURLWithPath: xcresult),
            projectRoot: projectRoot ?? "",
            coverageTargets: coverageTargets,
            excludedPaths: excludedPaths,
            strictPathnames: strictPathnames == 1
        ) else {
            throw ParseError.argumentError
        }
        let rslt = try converter.xmlString(quiet: quiet == 1)
        writeToStdOut(rslt)
    }

    private func outputCoberturaXML(for xcresult: String) throws {
        guard let converter = CoberturaCoverageConverter(
            with: URL(fileURLWithPath: xcresult),
            projectRoot: projectRoot ?? "",
            coverageTargets: coverageTargets,
            excludedPaths: excludedPaths,
            strictPathnames: strictPathnames == 1
        ) else {
            throw ParseError.argumentError
        }
        let rslt = try converter.xmlString(quiet: quiet == 1)
        writeToStdOut(rslt)
    }

    private func outputIssuesJSON(for xcresult: String, format: OutputFormat) throws {
        guard let converter = IssuesJSON(
            with: URL(fileURLWithPath: xcresult),
            projectRoot: projectRoot ?? "",
            excludedPaths: excludedPaths
        ) else {
            throw ParseError.argumentError
        }
        let rslt = try converter.jsonString(format: format, quiet: quiet == 1)
        writeToStdOut(rslt)
    }

    private func outputTargetNames(for xcresult: String) throws {
        guard let converter = SonarCoverageConverter(
            with: URL(fileURLWithPath: xcresult),
            projectRoot: projectRoot ?? "",
            coverageTargets: coverageTargets,
            strictPathnames: strictPathnames == 1
        ) else {
            throw ParseError.argumentError
        }
        writeToStdOut(converter.targetsInfo)
    }

    private func outputJUnitXML(
        for xcresult: String,
        with format: TestReportFormat
    ) throws {
        guard let junitXML = JunitXML(
            with: URL(fileURLWithPath: xcresult),
            projectRoot: projectRoot ?? "",
            format: format
        ) else {
            throw ParseError.argumentError
        }
        writeToStdOut(junitXML.xmlString)
    }

    private func outputDescription(for xcresult: String) throws {
        guard let resultParser = XCResultFormatter(
            with: URL(fileURLWithPath: xcresult),
            formatter: outputFormatter,
            coverageTargets: coverageTargets,
            failedTestsOnly: failedTestsOnly == 1,
            summaryFields: summaryFields ?? "errors|warnings|analyzerWarnings|tests|failed|skipped",
            coverageReportFormat: CoverageReportFormat(string: coverageReportFormat)
        ) else {
            throw ParseError.argumentError
        }
        writeToStdOutLn(resultParser.documentPrefix(title: "XCResults"))
        writeToStdOutLn(resultParser.summary)
        if noTestResult == 0 {
            writeToStdOutLn(resultParser.divider)
            writeToStdOutLn(resultParser.testDetails)
        }
        if coverage == 1 {
            writeToStdOutLn(resultParser.coverageDetails)
        }
        writeToStdOutLn(resultParser.documentSuffix)
    }

    private var format: OutputFormat {
        return OutputFormat(string: outputFormat)
    }

    private var outputFormatter: XCResultFormatting {
        switch format {
        case .cli:
            return CLIResultFormatter()
        case .html:
            return HTMLResultFormatter()
        case .txt:
            return TextResultFormatter()
        case .cobertura, .junit, .xml, .warnings, .errors, .warningsAndErrors:
            // outputFormatter is not used in case of .xml
            return TextResultFormatter()
        case .md:
            return MDResultFormatter()
        }
    }
}

enum ParseError: Error {
    case argumentError
}

xcresultparser.main()
