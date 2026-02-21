//
//  CoverageConverter.swift
//  xcresult2text
//
//  Created by Alex da Franca on 11.06.21.
//

import Foundation

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

    // MARK: - Dependencies

    let shell: Commandline
    let xcresultToolClient: XCResultToolClient

    public init?(
        with url: URL,
        projectRoot: String = "",
        coverageTargets: [String] = [],
        excludedPaths: [String] = [],
        strictPathnames: Bool
    ) {
        let shell = Shell()
        let xcresultToolClient = XCResultToolClient(shell: shell)
        guard let report = try? CoverageConverter.getCoverageReportAsJSON(resultFileURL: url, shell: shell) else {
            return nil
        }

        self.shell = shell
        self.xcresultToolClient = xcresultToolClient
        resultFileURL = url
        coverageReport = report
        self.projectRoot = projectRoot
        self.strictPathnames = projectRoot.isEmpty ? false : strictPathnames
        let selectedCoverageTargets = CoverageConverter.targets(
            filteredBy: coverageTargets,
            availableTargets: report.targets.map(\.name)
        )
        self.coverageTargets = selectedCoverageTargets
        filesForIncludedTargets = Set(
            report.targets
                .filter { selectedCoverageTargets.contains($0.name) }
                .flatMap { $0.files.map(\.path) }
        )
        self.excludedPaths = Set(excludedPaths)
        if let summary = try? xcresultToolClient.getTestSummary(path: url) {
            startTime = summary.startTime
        } else {
            startTime = nil
        }
    }

    public func xmlString(quiet: Bool) throws -> String {
        fatalError("xmlString is not implemented")
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
        var arguments = ["xccov", "view"]
        if resultFileURL.pathExtension == "xcresult" {
            arguments.append("--archive")
        }
        arguments.append("--json")
        arguments.append(resultFileURL.path)
        let coverageData = try shell.execute(program: "/usr/bin/xcrun", with: arguments)
        return try CoverageConverter.decodeJSON(FileCoverage.self, from: coverageData)
    }

    func isTargetIncluded(forFile file: String) -> Bool {
        filesForIncludedTargets.contains(file)
    }

    func isPathExcluded(_ path: String) -> Bool {
        for excludedPath in excludedPaths where path.contains(excludedPath) {
            return true
        }
        return false
    }

    // MARK: - unused and only here for reference

    // This method was replaced by getCoverageDataAsJSON()
    // Instead of requiring to get the coverage data for each single code file
    // we now can obtain all information for all targets and all files in one call to xccov
    // That is of course much faster, than calling xccov for each file, as we needed to in older times
    // It is not used at the moment, but is left here just to cover this xccov function
    func coverageForFile(path: String) throws -> String {
        var arguments = ["xccov", "view"]
        if resultFileURL.pathExtension == "xcresult" {
            arguments.append("--archive")
        }
        arguments.append("--file")
        arguments.append(path)
        arguments.append(resultFileURL.path)
        let coverageData = try shell.execute(program: "/usr/bin/xcrun", with: arguments)
        return String(decoding: coverageData, as: UTF8.self)
    }

    // This method was replaced by going through all files in all targets
    // That allows us to filter by targets easier
    // It is not used at the moment, but is left here just to cover this xccov function
    func coverageFileList() throws -> [String] {
        var arguments = ["xccov", "view"]
        if resultFileURL.pathExtension == "xcresult" {
            arguments.append("--archive")
        }
        arguments.append("--file-list")
        arguments.append(resultFileURL.path)
        let filelistData = try shell.execute(program: "/usr/bin/xcrun", with: arguments)
        return String(decoding: filelistData, as: UTF8.self).components(separatedBy: "\n")
    }

    private static func getCoverageReportAsJSON(resultFileURL: URL, shell: Commandline) throws -> CoverageReport {
        var arguments = ["xccov", "view"]
        arguments.append("--report")
        arguments.append("--json")
        arguments.append(resultFileURL.path)
        let coverageData = try shell.execute(program: "/usr/bin/xcrun", with: arguments)
        return try decodeJSON(CoverageReport.self, from: coverageData)
    }

    private static func targets(filteredBy filter: [String], availableTargets: [String]) -> Set<String> {
        guard !filter.isEmpty else {
            return Set(availableTargets)
        }
        let filterSet = Set(filter)
        let filtered = availableTargets.filter { thisTarget in
            guard let stripped = thisTarget.split(separator: ".").first else { return true }
            return filterSet.contains(String(stripped))
        }
        return Set(filtered)
    }

    private static func decodeJSON<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        let decoder = JSONDecoder()
        return try decoder.decode(type, from: data)
    }
}
