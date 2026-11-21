//
//  CoverageConverter.swift
//  xcresult2text
//
//  Created by Alex da Franca on 11.06.21.
//

public import Foundation

struct PrefetchedCoverageInputs {
    let report: CoverageReport
    let startTime: Double?
    let data: FileCoverage
}

public enum CoverageConverterError: LocalizedError, Equatable {
    case couldNotLoadCoverageReport
    case unknownCoverageTargets(requested: [String], available: [String])
    case notImplemented

    public var errorDescription: String? {
        switch self {
        case .couldNotLoadCoverageReport:
            return "Could not load coverage report from xcresult archive."
        case let .unknownCoverageTargets(requested, available):
            let requestedList = requested.joined(separator: ", ")
            let availableList = available.joined(separator: ", ")
            return "Unknown coverage target(s): \(requestedList). Available targets: \(availableList)"
        case .notImplemented:
            return "xmlString(quiet:) must be implemented by a CoverageConverter subclass."
        }
    }
}

/// Convert coverage data in a xcresult archive to xml (exact format determined by subclass)
///
/// ~~ Unfortunately converting to the coverage xml format suited for e.g. sonarqube is a tedious task.
/// It requires us to invoke the xccov binary for each single file in the project.
/// First we get a list of source files with coverage data from the archive, using xccov --file-list
/// and then we need to invoke xccov for each single file. That takes a considerable amount of time.
/// So at least we spread it over different threads, so that it executes way faster overall~~
///
/// ~~Until now we use [xccov-to-sonarqube-generic.sh]( https://github.com/SonarSource/sonar-scanning-examples/blob/master/swift-coverage/swift-coverage-example/xccov-to-sonarqube-generic.sh)
/// which does the same job just in a shell script. It has the same problem
/// and since it can not spawn it to different threads, it takes about 5x the time.~~
///
/// With Xcode 15 the xccov command line tool can output the entire coverage data in JSON format!
/// Read the Readme for further info on this.
///
public class CoverageConverter {
    let resultFileURL: URL
    let projectRoot: String
    let coverageTargets: Set<String>
    let coverageReport: CoverageReport
    let filesForIncludedTargets: Set<String>
    let excludedPaths: Set<String>
    let strictPathnames: Bool
    let startTime: Double?
    private let prefetchedCoverage: FileCoverage?

    // MARK: - Dependencies

    let xcresultToolClient: any XCResultToolProviding
    let xccovClient: any XCCovProviding

    public convenience init(
        with url: URL,
        projectRoot: String = "",
        coverageTargets: [String] = [],
        excludedPaths: [String] = [],
        strictPathnames: Bool
    ) throws {
        try self.init(
            with: url,
            projectRoot: projectRoot,
            coverageTargets: coverageTargets,
            excludedPaths: excludedPaths,
            strictPathnames: strictPathnames,
            xcResultToolClient: XCResultToolClient(),
            xcCovClient: XCCovClient()
        )
    }

    /// Runs xccov and xcresulttool concurrently.
    /// If the coverage report fails to load or a requested target doesn't exist,
    /// the runs still in progress are terminated.
    package convenience init(
        loadingConcurrently url: URL,
        projectRoot: String = "",
        coverageTargets: [String] = [],
        excludedPaths: [String] = [],
        strictPathnames: Bool
    ) async throws {
        async let fetchedReport = try await XCCovClient().coverageReport(path: url)
        async let fetchedStartTime = try? await XCResultToolClient().testSummary(path: url).startTime
        async let fetchedData = try await XCCovClient().coverageData(path: url)

        let report: CoverageReport
        do {
            report = try await fetchedReport
        } catch {
            throw CoverageConverterError.couldNotLoadCoverageReport
        }
        // Report unknown targets before waiting for the other runs, as the synchronous initialiser does.
        _ = try CoverageConverter.selectCoverageTargets(coverageTargets, in: report)
        let startTime = await fetchedStartTime
        let data = try await fetchedData
        try self.init(
            with: url,
            projectRoot: projectRoot,
            coverageTargets: coverageTargets,
            excludedPaths: excludedPaths,
            strictPathnames: strictPathnames,
            xcResultToolClient: XCResultToolClient(),
            xcCovClient: XCCovClient(),
            prefetchedInputs: PrefetchedCoverageInputs(report: report, startTime: startTime, data: data)
        )
    }

    init(
        with url: URL,
        projectRoot: String = "",
        coverageTargets: [String] = [],
        excludedPaths: [String] = [],
        strictPathnames: Bool,
        xcResultToolClient: any XCResultToolProviding,
        xcCovClient: any XCCovProviding,
        prefetchedInputs: PrefetchedCoverageInputs? = nil
    ) throws {
        let report: CoverageReport
        if let prefetchedInputs {
            report = prefetchedInputs.report
        } else {
            do {
                report = try xcCovClient.getCoverageReport(path: url)
            } catch {
                throw CoverageConverterError.couldNotLoadCoverageReport
            }
        }

        self.xcresultToolClient = xcResultToolClient
        xccovClient = xcCovClient
        resultFileURL = url
        coverageReport = report
        self.projectRoot = projectRoot
        self.strictPathnames = projectRoot.isEmpty ? false : strictPathnames
        let selectedCoverageTargets = try CoverageConverter.selectCoverageTargets(coverageTargets, in: report)
        self.coverageTargets = selectedCoverageTargets
        let includedTargetFiles = report.targets
            .filter { selectedCoverageTargets.contains($0.name) }
            .flatMap { $0.files.map(\.path) }
        filesForIncludedTargets = CoverageConverter.normalizedFilePaths(
            for: includedTargetFiles,
            projectRoot: projectRoot
        )
        self.excludedPaths = Set(excludedPaths)
        if let prefetchedInputs {
            startTime = prefetchedInputs.startTime
            prefetchedCoverage = prefetchedInputs.data
        } else {
            startTime = try? xcResultToolClient.getTestSummary(path: url).startTime
            prefetchedCoverage = nil
        }
    }

    static func selectCoverageTargets(_ targets: [String], in report: CoverageReport) throws -> Set<String> {
        let selection = CoverageTargetSelection(with: targets, from: report.targets.map(\.name))
        if !selection.unmatchedRequested.isEmpty {
            throw CoverageConverterError.unknownCoverageTargets(
                requested: selection.unmatchedRequested.sorted(),
                available: selection.availableTargets.sorted()
            )
        }
        return selection.selectedTargets
    }

    public func xmlString(quiet: Bool) throws -> String {
        throw CoverageConverterError.notImplemented
    }

    public var targetsInfo: String {
        return coverageReport.targets.reduce("") { rslt, item in
            return "\(rslt)\n\(item.name)"
        }
    }

    var lineCoverage: Double {
        coverageReport.lineCoverage
    }

    var coveredLines: Int {
        coverageReport.coveredLines
    }

    var executableLines: Int {
        coverageReport.executableLines
    }

    func writeToStdErrorLn(_ str: String) {
        writeToStdError("\(str)\n")
    }

    func writeToStdError(_ str: String) {
        let handle = FileHandle.standardError

        if let data = str.data(using: String.Encoding.utf8) {
            handle.write(data)
        }
    }

    // Use the xccov commandline tool to get results as JSON.
    func getCoverageDataAsJSON() throws -> FileCoverage {
        if let prefetchedCoverage {
            return prefetchedCoverage
        }
        return try xccovClient.getCoverageData(path: resultFileURL)
    }

    func isTargetIncluded(forFile file: String) -> Bool {
        if filesForIncludedTargets.contains(file) {
            return true
        }
        let normalized = CoverageConverter.normalizedFilePaths(for: [file], projectRoot: projectRoot)
        return !filesForIncludedTargets.isDisjoint(with: normalized)
    }

    func isPathExcluded(_ path: String) -> Bool {
        for excludedPath in excludedPaths where path.contains(excludedPath) {
            return true
        }
        return false
    }

    // Maintained to support the public API used by tests and existing consumers.
    func coverageForFile(path: String) throws -> String {
        try xccovClient.getCoverageForFile(path: resultFileURL, filePath: path)
    }

    // Maintained to support the public API used by tests and existing consumers.
    func coverageFileList() throws -> [String] {
        try xccovClient.getCoverageFileList(path: resultFileURL)
    }

    static func normalizedFilePaths(for paths: [String], projectRoot: String) -> Set<String> {
        var result = Set<String>()
        for path in paths {
            result.insert(path)
            guard !projectRoot.isEmpty else {
                continue
            }
            if path.hasPrefix(projectRoot) {
                var relative = String(path.dropFirst(projectRoot.count))
                if relative.hasPrefix("/") {
                    relative.removeFirst()
                }
                if !relative.isEmpty {
                    result.insert(relative)
                }
            } else if !path.hasPrefix("/") {
                let joined = (projectRoot as NSString).appendingPathComponent(path)
                result.insert(joined)
            }
        }
        return result
    }
}
