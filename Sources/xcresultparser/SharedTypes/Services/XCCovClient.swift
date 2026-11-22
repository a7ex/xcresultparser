//
//  XCCovClient.swift
//  Xcresultparser
//
//  Created by Alex da Franca on 22.02.26.
//

import Foundation

protocol XCCovProviding: Sendable {
    func getCoverageData(path: URL) async throws -> FileCoverage
    func getCoverageReport(path: URL) async throws -> CoverageReport
    func getCoverageForFile(path: URL, filePath: String) async throws -> String
    func getCoverageFileList(path: URL) async throws -> [String]
}

struct XCCovClient: XCCovProviding {
    private let shell: any Commandline
    private let decoder: JSONDecoder

    init(
        shell: any Commandline = Shell(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.shell = shell
        self.decoder = decoder
    }

    func getCoverageData(path: URL) async throws -> FileCoverage {
        let data = try await execute(arguments: coverageDataArguments(for: path))
        return try decode(FileCoverage.self, from: data)
    }

    func getCoverageReport(path: URL) async throws -> CoverageReport {
        let data = try await execute(arguments: coverageReportArguments(for: path))
        return try decode(CoverageReport.self, from: data)
    }

    func getCoverageForFile(path: URL, filePath: String) async throws -> String {
        let data = try await execute(arguments: viewArguments(for: path) + ["--file", filePath, path.path])
        return String(decoding: data, as: UTF8.self)
    }

    func getCoverageFileList(path: URL) async throws -> [String] {
        let data = try await execute(arguments: viewArguments(for: path) + ["--file-list", path.path])
        return String(decoding: data, as: UTF8.self).components(separatedBy: "\n")
    }

    private func viewArguments(for path: URL) -> [String] {
        var arguments = ["view"]
        if path.pathExtension == "xcresult" {
            arguments.append("--archive")
        }
        return arguments
    }

    private func coverageDataArguments(for path: URL) -> [String] {
        viewArguments(for: path) + ["--json", path.path]
    }

    private func coverageReportArguments(for path: URL) -> [String] {
        ["view", "--report", "--json", path.path]
    }

    private func execute(arguments: [String]) async throws -> Data {
        try await shell.execute(program: "/usr/bin/xcrun", with: ["xccov"] + arguments)
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        try decoder.decode(type, from: data)
    }
}
