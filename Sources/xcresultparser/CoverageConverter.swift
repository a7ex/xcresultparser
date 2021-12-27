//
//  CoverageConverter.swift
//  xcresult2text
//
//  Created by Alex da Franca on 11.06.21.
//

import Foundation
import XCResultKit

/// Convert coverage data in a xcresult archive to xml suited for use in sonarqube
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
public struct CoverageConverter {
    private let resultFile: XCResultFile
    private let projectRoot: String
    private let codeCoverage: CodeCoverage
    
    public init?(with url: URL,
          projectRoot: String = "") {
        resultFile = XCResultFile(url: url)
        guard let record = resultFile.getCodeCoverage() else {
            return nil
        }
        self.projectRoot = projectRoot
        codeCoverage = record
    }
    
    public func xmlString(quiet: Bool) throws -> String {
        let coverageXML = XMLElement(name: "coverage")
        coverageXML.addAttribute(name: "version", stringValue: "1")
        let files = try coverageFileList()
        
        // since we need to invoke xccov for each file, it takes pretty much time
        // so we invoke it in parallel on 8 threads, that speeds up things considerably
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 8 //Deadlock if this is = 1
        queue.qualityOfService = .userInitiated
        for file in files {
            guard !file.isEmpty else { continue }
            if !quiet {
                writeToStdError("Coverage for: \(file)\n")
            }
            let op = BlockOperation {
                do {
                    let coverage = try fileCoverageXML(for: file, relativeTo: projectRoot)
                    coverageXML.addChild(coverage)
                } catch {
                    writeToStdErrorLn(error.localizedDescription)
                }
            }
            queue.addOperation(op)
        }
        // This will block until all our operation have compleated (or been canceled)
        queue.waitUntilAllOperationsAreFinished()
        return coverageXML.xmlString(options: [.nodePrettyPrint, .nodeCompactEmptyElement])
    }

    private func writeToStdErrorLn(_ str: String) {
        writeToStdError("\(str)\n")
    }
    
    private func writeToStdError(_ str: String) {
        let handle = FileHandle.standardError

        if let data = str.data(using: String.Encoding.utf8) {
            handle.write(data)
        }
    }
    
    private func fileCoverageXML(for file: String, relativeTo projectRoot: String) throws -> XMLElement {
        let coverageData = try coverageForFile(path: file)
        let fileElement = XMLElement(name: "file")
        fileElement.addAttribute(name: "path", stringValue: relativePath(for: file, relativeTo: projectRoot))
        let pattern = #"(\d+):\s*(\d)"#
        let regex = try NSRegularExpression(pattern: pattern, options: .anchorsMatchLines)
        let nsrange = NSRange(coverageData.startIndex..<coverageData.endIndex,
                              in: coverageData)
        regex.enumerateMatches(in: coverageData, options: [], range: nsrange) { match, flags, stop in
            guard let match = match else { return }
            
            let lineNumber = coverageData.text(in: match.range(at: 1))
            let coverage = coverageData.text(in: match.range(at: 2))
            
            let line = XMLElement(name: "lineToCover")
            line.addAttribute(name: "lineNumber", stringValue: lineNumber)
            line.addAttribute(name: "covered", stringValue: (coverage == "0" ? "false": "true"))
            
            fileElement.addChild(line)
            
        }
        return fileElement
    }
    
    private func relativePath(for path: String, relativeTo projectRoot: String) -> String {
        guard !projectRoot.isEmpty else {
            return path
        }
        let parts = path.components(separatedBy: "/\(projectRoot)")
        guard parts.count > 1 else {
            return path
        }
        let relative = parts[parts.count - 1]
        return relative.starts(with: "/") ?
            String(relative.dropFirst()):
            relative
    }
    
    
    private func coverageFileList() throws -> [String] {
        var arguments = ["xccov", "view"]
        if resultFile.url.pathExtension == "xcresult" {
            arguments.append("--archive")
        }
        arguments.append("--file-list")
        arguments.append(resultFile.url.path)
        let filelistData = try execute(program: "/usr/bin/xcrun", with: arguments)
        return String(decoding: filelistData, as: UTF8.self).components(separatedBy: "\n")
    }
    
    private func coverageForFile(path: String) throws -> String {
        var arguments = ["xccov", "view"]
        if resultFile.url.pathExtension == "xcresult" {
            arguments.append("--archive")
        }
        arguments.append("--file")
        arguments.append(path)
        arguments.append(resultFile.url.path)
        let coverageData = try execute(program: "/usr/bin/xcrun", with: arguments)
        return String(decoding: coverageData, as: UTF8.self)
    }
    
    private func execute(program: String, with arguments: [String]) throws -> Data {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: program)
        task.arguments = arguments
        let errorPipe = Pipe()
        task.standardError = errorPipe
        let outPipe = Pipe()
        task.standardOutput = outPipe // to capture standard error, use task.standardError = outPipe
        try task.run()
        let fileHandle = outPipe.fileHandleForReading
        let data = fileHandle.readDataToEndOfFile()
        task.waitUntilExit()
        let status = task.terminationStatus
        if status != 0 {
            throw CLIError.executionError(code: Int(status))
        } else {
            return data
        }
    }
    
    enum CLIError: Error {
        case executionError(code: Int)
    }
}

extension String {
    func text(in range: NSRange) -> String {
        let idx1 = index(startIndex, offsetBy: range.location)
        let idx2 = index(idx1, offsetBy: range.length)
        return String(self[idx1..<idx2])
    }
}
