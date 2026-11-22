//
//  XCResultToolClient.swift
//  Xcresultparser
//
//  Created by Alex da Franca on 20.02.26.
//

import Foundation

protocol XCResultToolProviding: Sendable {
    func getBuildResults(path: URL) async throws -> XCBuildResults
    func getTestSummary(path: URL) async throws -> XCSummary
    func getTests(path: URL) async throws -> XCTests
    func getTestDetails(path: URL, testId: String) async throws -> XCTestDetails
    func getActivities(path: URL, testId: String) async throws -> XCActivities
    func getMetrics(path: URL, testId: String) async throws -> [XCTestWithMetrics]
}

struct XCResultToolClient: XCResultToolProviding {
    enum ToolClientError: Error, Equatable {
        case invalidUTF8
        case unexpectedRootValue(String)
    }

    private let shell: any Commandline
    private let decoder: JSONDecoder

    init(
        shell: any Commandline = Shell(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.shell = shell
        self.decoder = decoder
    }

    func getBuildResults(path: URL) async throws -> XCBuildResults {
        let data = try await execute(arguments: ["get", "build-results", "--path", path.path])
        return try decode(XCBuildResults.self, from: data)
    }

    func getTestSummary(path: URL) async throws -> XCSummary {
        let data = try await execute(arguments: testSummaryArguments(for: path))
        return try decode(XCSummary.self, from: data)
    }

    func getTests(path: URL) async throws -> XCTests {
        let data = try await execute(arguments: ["get", "test-results", "tests", "--path", path.path])
        return try decode(XCTests.self, from: data)
    }

    func getTestDetails(path: URL, testId: String) async throws -> XCTestDetails {
        let data = try await execute(
            arguments: ["get", "test-results", "test-details", "--path", path.path, "--test-id", testId]
        )
        return try decode(XCTestDetails.self, from: data)
    }

    func getActivities(path: URL, testId: String) async throws -> XCActivities {
        let data = try await execute(
            arguments: ["get", "test-results", "activities", "--path", path.path, "--test-id", testId]
        )
        return try decode(XCActivities.self, from: data)
    }

    // xcresulttool currently returns [] for tests without performance metrics.
    func getMetrics(path: URL, testId: String) async throws -> [XCTestWithMetrics] {
        let data = try await execute(
            arguments: ["get", "test-results", "metrics", "--path", path.path, "--test-id", testId]
        )

        if let object = try? decode(XCTestWithMetrics.self, from: data) {
            return [object]
        }
        if let array = try? decode([XCTestWithMetrics].self, from: data) {
            return array
        }

        if let raw = String(data: data, encoding: .utf8) {
            throw ToolClientError.unexpectedRootValue(raw)
        }
        throw ToolClientError.invalidUTF8
    }

    private func testSummaryArguments(for path: URL) -> [String] {
        ["get", "test-results", "summary", "--path", path.path]
    }

    private func execute(arguments: [String]) async throws -> Data {
        // Compact JSON carries the same data in about 40% fewer bytes, which is faster to read and decode.
        try await shell.execute(program: "/usr/bin/xcrun", with: ["xcresulttool"] + arguments + ["--compact"])
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        try decoder.decode(type, from: data)
    }
}
