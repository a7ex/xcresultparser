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
    let files: [CoverageReportFile]
}

struct CoverageReportFile: Decodable {
    let path: String
}
