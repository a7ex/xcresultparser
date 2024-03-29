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
/// Unfortunately converting to the coverage xml format suited for e.g. sonarqube is a tedious task.
/// It requires us to invoke the xccov binary for each single file in the project.
/// First we get a list of source files with coverage data from the archive, using xccov --file-list
/// and then we need to invoke xccov for each single file. That takes a considerable amount of time.
/// So at least we spread it over different threads, so that it executes way faster overall
///
/// Until now we use [xccov-to-sonarqube-generic.sh]( https://github.com/SonarSource/sonar-scanning-examples/blob/master/swift-coverage/swift-coverage-example/xccov-to-sonarqube-generic.sh)
/// which does the same job just in a shell script. It has the same problem
/// and since it can not spawn it to different threads, it takes about 5x the time.
public class CoverageConverter {
    let resultFile: XCResultFile
    let projectRoot: String
    let codeCoverage: CodeCoverage
    let invocationRecord: ActionsInvocationRecord
    let coverageRegexp: NSRegularExpression?
    let coverageTargets: Set<String>
    
    public init?(
        with url: URL,
        projectRoot: String = "",
        coverageTargets: [String] = []
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
        
        let pattern = #"(\d+):\s*(\d)"#
        coverageRegexp = try? NSRegularExpression(pattern: pattern, options: .anchorsMatchLines)
    }
    
    public func xmlString(quiet: Bool) throws -> String {
        fatalError("xmlString is not implemented")
    }

    public var targetsInfo: String {
        return codeCoverage.targets.reduce("") {rslt, item in
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
    
    func relativePath(for path: String, relativeTo projectRoot: String) -> String {
        guard !projectRoot.isEmpty else {
            return path
        }
        let projectRootTrimmed = projectRoot.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let parts = path.components(separatedBy: "/\(projectRootTrimmed)")
        guard parts.count > 1 else {
            return path
        }
        let relative = parts[parts.count - 1]
        return relative.starts(with: "/") ?
            String(relative.dropFirst()):
            relative
    }
    
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

extension String {
    func text(in range: NSRange) -> String {
        let idx1 = index(startIndex, offsetBy: range.location)
        let idx2 = index(idx1, offsetBy: range.length)
        return String(self[idx1..<idx2])
    }
}
