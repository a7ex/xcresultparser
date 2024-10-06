//
//  CoverageConverter.swift
//  xcresult2text
//
//  Created by Alex da Franca on 11.06.21.
//

import Foundation
import XCResultKit

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
    let resultFile: XCResultFile
    let projectRoot: String
    let codeCoverage: CodeCoverage
    let invocationRecord: ActionsInvocationRecord
    let coverageTargets: Set<String>
    let excludedPaths: Set<String>

    public init?(
        with url: URL,
        projectRoot: String = "",
        coverageTargets: [String] = [],
        excludedPaths: [String] = []
    ) {
        resultFile = XCResultFile(url: url)
        guard let record = resultFile.getCodeCoverage() else {
            return nil
        }
        self.projectRoot = projectRoot
        codeCoverage = record
        guard let invocationRecord = resultFile.getInvocationRecord() else {
            return nil
        }
        self.invocationRecord = invocationRecord
        self.coverageTargets = record.targets(filteredBy: coverageTargets)
        self.excludedPaths = Set(excludedPaths)
    }

    public func xmlString(quiet: Bool) throws -> String {
        fatalError("xmlString is not implemented")
    }

    public var targetsInfo: String {
        return codeCoverage.targets.reduce("") { rslt, item in
            return "\(rslt)\n\(item.name)"
        }
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
        if resultFile.url.pathExtension == "xcresult" {
            arguments.append("--archive")
        }
        arguments.append("--json")
        arguments.append(resultFile.url.path)
        let coverageData = try Shell.execute(program: "/usr/bin/xcrun", with: arguments)
        return try JSONDecoder().decode(FileCoverage.self, from: coverageData)
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
        if resultFile.url.pathExtension == "xcresult" {
            arguments.append("--archive")
        }
        arguments.append("--file")
        arguments.append(path)
        arguments.append(resultFile.url.path)
        let coverageData = try Shell.execute(program: "/usr/bin/xcrun", with: arguments)
        return String(decoding: coverageData, as: UTF8.self)
    }

    // This method was replaced by going through all files in all targets
    // That allows us to filter by targets easier
    // It is not used at the moment, but is left here just to cover this xccov function
    func coverageFileList() throws -> [String] {
        var arguments = ["xccov", "view"]
        if resultFile.url.pathExtension == "xcresult" {
            arguments.append("--archive")
        }
        arguments.append("--file-list")
        arguments.append(resultFile.url.path)
        let filelistData = try Shell.execute(program: "/usr/bin/xcrun", with: arguments)
        return String(decoding: filelistData, as: UTF8.self).components(separatedBy: "\n")
    }
}
