//
//  XCCovClient.swift
//  Xcresultparser
//
//  Created by Alex da Franca on 22.02.26.
//

import Foundation

protocol XCCovProviding {
    func getCoverageData(path: URL) throws -> FileCoverage
    func getCoverageReport(path: URL) throws -> CoverageReport
    func getCoverageForFile(path: URL, filePath: String) throws -> String
    func getCoverageFileList(path: URL) throws -> [String]
}

struct XCCovClient: XCCovProviding {
    private let shell: Commandline
    private let decoder: JSONDecoder

    init(
        shell: Commandline = Shell(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.shell = shell
        self.decoder = decoder
    }

    func getCoverageData(path: URL) throws -> FileCoverage {
        let data = try execute(arguments: coverageDataArguments(for: path))
        return try decode(FileCoverage.self, from: data)
    }

    func getCoverageReport(path: URL) throws -> CoverageReport {
        let data = try execute(arguments: coverageReportArguments(for: path))
        return try decode(CoverageReport.self, from: data)
    }

    /// Like `getCoverageData(path:)`, but terminates xccov if the task is cancelled.
    func coverageData(path: URL) async throws -> FileCoverage {
        let data = try await executeCancellable(arguments: coverageDataArguments(for: path))
        return try decode(FileCoverage.self, from: data)
    }

    /// Like `getCoverageReport(path:)`, but terminates xccov if the task is cancelled.
    func coverageReport(path: URL) async throws -> CoverageReport {
        let data = try await executeCancellable(arguments: coverageReportArguments(for: path))
        return try decode(CoverageReport.self, from: data)
    }

    func getCoverageForFile(path: URL, filePath: String) throws -> String {
        let data = try execute(arguments: viewArguments(for: path) + ["--file", filePath, path.path])
        return String(decoding: data, as: UTF8.self)
    }

    func getCoverageFileList(path: URL) throws -> [String] {
        let data = try execute(arguments: viewArguments(for: path) + ["--file-list", path.path])
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

    private func execute(arguments: [String]) throws -> Data {
        try shell.execute(program: "/usr/bin/xcrun", with: ["xccov"] + arguments)
    }

    private func executeCancellable(arguments: [String]) async throws -> Data {
        try await shell.executeCancellable(program: "/usr/bin/xcrun", with: ["xccov"] + arguments, at: nil)
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        try decoder.decode(type, from: data)
    }
}
