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
        let data = try execute(arguments: viewArguments(for: path) + ["--json", path.path])
        return try decode(FileCoverage.self, from: data)
    }

    func getCoverageReport(path: URL) throws -> CoverageReport {
        let data = try execute(arguments: ["view", "--report", "--json", path.path])
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

    private func execute(arguments: [String]) throws -> Data {
        try shell.execute(program: "/usr/bin/xcrun", with: ["xccov"] + arguments)
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        try decoder.decode(type, from: data)
    }
}
