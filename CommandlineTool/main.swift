//
//  main.swift
//  xcresultparser
//
//  Created by Alex da Franca on 11.06.21.
//

import Foundation
import ArgumentParser
import XcresultparserLib

private let marketingVersion = "1.1.1"

struct xcresultparser: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "xcresultparser \(marketingVersion)\nInterpret binary .xcresult files and print summary in different formats: txt, xml, html or colored cli output."
    )
    
    @Option(name: .shortAndLong, help: "The output format. It can be either 'txt', 'cli', 'html' or 'xml'. In case of 'xml' JUnit format for test results and generic format (Sonarqube) for coverage data is used.")
    var outputFormat: String?
    
    @Option(name: .shortAndLong, help: "The name of the project root. If present paths and urls are relative to the specified directory.")
    var projectRoot: String?
    
    @Option(name: [.customShort("t"), .customLong("coverage-targets")], help: "Specify which targets to calculate coverage from")
    var coverageTargets: [String] = []
    
    @Flag(name: .shortAndLong, help: "Whether to print coverage data.")
    var coverage: Int
    
    @Flag(name: .shortAndLong, help: "Whether to print test results.")
    var noTestResult: Int
    
    @Flag(name: .shortAndLong, help: "Quiet. Don't print status output.")
    var quiet: Int

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
        if format == .xml {
            if coverage == 1 {
                try outputSonarXML(for: xcresult)
            } else {
                try outputJUnitXML(for: xcresult)
            }
        } else {
            try outputDescription(for: xcresult)
        }
    }
    
    private func outputSonarXML(for xcresult: String) throws {
        guard let converter = CoverageConverter(with: URL(fileURLWithPath: xcresult), projectRoot: projectRoot ?? "") else {
            throw ParseError.argumentError
        }
        let rslt = try converter.xmlString(quiet: quiet == 1)
        writeToStdOut(rslt)
    }
    
    private func outputJUnitXML(for xcresult: String) throws {
        guard let junitXML = JunitXML(
            with: URL(fileURLWithPath: xcresult),
            projectRoot: projectRoot ?? "",
            format: .sonar
        ) else {
            throw ParseError.argumentError
        }
        writeToStdOut(junitXML.xmlString)
    }
    
    private func outputDescription(for xcresult: String) throws {
        guard let resultParser = XCResultFormatter(
            with: URL(fileURLWithPath: xcresult),
            formatter: outputFormatter,
            coverageTargets: coverageTargets
        ) else {
            throw ParseError.argumentError
        }
        writeToStdOutLn(resultParser.documentPrefix(title: "XCResults"))
        if noTestResult == 0 {
            writeToStdOutLn(resultParser.summary)
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
        case .xml:
            // outputFormatter is not used in case of .xml
            return TextResultFormatter()
        }
    }
}

enum ParseError: Error {
    case argumentError
}

xcresultparser.main()

