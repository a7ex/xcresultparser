//
//  main.swift
//  xcresultparser
//
//  Created by Alex da Franca on 11.06.21.
//

import Foundation
import ArgumentParser

private let marketingVersion = "0.1"

enum ParseError: Error {
    case argumentError
}

struct xcresultparser: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Interpret binary .xcresult files and print summary in different formats: txt, xml, html or colored cli output."
    )
    
    @Option(name: .shortAndLong, help: "The output format. It can be either 'txt', 'cli', 'html' or 'xml'. In case of 'xml' JUnit format for test results and generic format (Sonarqube) for coverage data is used.")
    var outputFormat: String?
    
    @Option(name: .shortAndLong, help: "The name of the project root. If present paths and urls are relative to the specified directory.")
    var projectRoot: String?
    
    @Flag(name: .shortAndLong, help: "Whether to print coverage data.")
    var coverage: Int
    
    @Flag(name: .shortAndLong, help: "Print version.")
    var version: Int
    
    @Argument(help: "The path to the .xcresult file.")
    var xcresultFile: String
    
    mutating func run() throws {
        guard version != 1 else {
            printVersion()
            return
        }
        if outputFormat == "xml" {
            if coverage == 1 {
                try outputSonarXML()
            } else {
                try outputJUnitXML()
            }
        } else {
            try outputDescription()
        }
    }
    
    private func printVersion() {
        print("xcresultparser \(marketingVersion)")
    }
    
    private func outputSonarXML() throws {
        guard let converter = CoverageConverter(with: URL(fileURLWithPath: xcresultFile), projectRoot: projectRoot ?? "") else {
            throw ParseError.argumentError
        }
        print(converter.xmlString)
    }
    
    private func outputJUnitXML() throws {
        guard let junitXML = JunitXML(with: URL(fileURLWithPath: xcresultFile), projectRoot: projectRoot ?? "") else {
            throw ParseError.argumentError
        }
        print(junitXML.xmlString)
    }
    
    private func outputDescription() throws {
        guard let resultParser = XCResultFormatter(
                with: URL(fileURLWithPath: xcresultFile),
                formatter: outputFormatter) else {
            throw ParseError.argumentError
        }
        print(resultParser.documentPrefix(title: "XCResults"))
        print(resultParser.summary)
        print(resultParser.divider)
        print(resultParser.testDetails)
        if coverage == 1 {
            print(resultParser.coverageDetails)
        }
        print(resultParser.documentSuffix)
    }
    
    private var outputFormatter: XCResultFormatting {
        let fmt = OutputFormat(string: outputFormat)
        switch fmt {
        case .cli:
            return CLIResultFormatter()
        case .html:
            return HTMLResultFormatter()
        case .txt:
            return TextResultFormatter()
        }
    }
}

xcresultparser.main()

