//
//  CoverageReport.swift
//
//  Created by Codex on 21.02.26.
//

import Foundation

struct CoverageReport: Decodable {
    let coveredLines: Int
    let executableLines: Int
    let lineCoverage: Double
    let targets: [CoverageTarget]
}

struct CoverageTarget: Decodable {
    let name: String
    let lineCoverage: Double
    let executableLines: Int
    let coveredLines: Int
    let files: [CoverageReportFile]
}

struct CoverageReportFile: Decodable {
    let name: String
    let path: String
    let lineCoverage: Double
    let executableLines: Int
    let coveredLines: Int
    let functions: [CoverageReportFunction]
}

struct CoverageReportFunction: Decodable {
    let name: String
    let lineNumber: Int
    let lineCoverage: Double
    let executableLines: Int
    let coveredLines: Int
    let executionCount: Int
}
