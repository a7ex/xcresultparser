//
//  CoberturaCoverageConverter.swift
//  xcresult2text
//
//  Created by Eliot Lash on 12.07.22.
//
/**
 MIT License

 Copyright (c) 2020 Thibault Wittemberg

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */

import Foundation
import XCResultKit

enum JSONParseError: Error {
    case convertError(code: Int, message: String)
}

// Subrange information struct
struct Subrange: Decodable {
    let column: Int
    let executionCount: Int
    let length: Int
}

// LineDetail information struct
struct LineDetail: Decodable {
    let isExecutable: Bool
    let line: Int
    let executionCount: Int?
    let subranges: [Subrange]?
}

// FileCoverage information struct
struct FileCoverage: Decodable {
    let files: [String: [LineDetail]]

    // Custom initializer to handle the top-level dictionary
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        var filesDict = [String: [LineDetail]]()

        for key in container.allKeys {
            let keyString = key.stringValue
            let lineDetails = try container.decode([LineDetail].self, forKey: key)
            filesDict[keyString] = lineDetails
        }
        self.files = filesDict
    }

    private struct CodingKeys: CodingKey {
        var stringValue: String
        var intValue: Int?

        init?(stringValue: String) {
            self.stringValue = stringValue
            self.intValue = nil
        }

        init?(intValue: Int) {
            return nil
        }
    }
}

public class CoberturaCoverageConverter: CoverageConverter, XmlSerializable {

    public var xmlString: String {
        do {
            return try xmlString(quiet: true)
        } catch {
            return "Error creating coverage xml: \(error.localizedDescription)"
        }
    }

    public override func xmlString(quiet: Bool) throws -> String {
        let dtd = readDTD()
        dtd.name = "coverage"
        dtd.systemID = "http://cobertura.sourceforge.net/xml/coverage-04.dtd"

        let rootElement = self.makeRootElement()

        let doc = XMLDocument(rootElement: rootElement)
        doc.version = "1.0"
        doc.dtd = dtd
        doc.documentContentKind = XMLDocument.ContentKind.xml

        let sourceElement = XMLElement(name: "sources")
        rootElement.addChild(sourceElement)
        sourceElement.addChild(XMLElement(name: "source", stringValue: projectRoot.isEmpty ? "." : projectRoot))

        let packagesElement = XMLElement(name: "packages")
        rootElement.addChild(packagesElement)

        // Get the xccov results as a JSON.
        var arguments = ["xccov", "view"]
        if resultFile.url.pathExtension == "xcresult" {
            arguments.append("--archive")
        }
        arguments.append("--json")
        arguments.append(resultFile.url.path)
        let coverageData = try Shell.execute(program: "/usr/bin/xcrun", with: arguments)
        let resultsString = String(decoding: coverageData, as: UTF8.self)
        guard let jsonData = resultsString.data(using: String.Encoding.utf8) else {
            writeToStdError("Failed to convert to Data")
            throw JSONParseError.convertError(code: 0, message: "Failed to convert to Data object")
        }
        guard let coverageJson = try? JSONDecoder().decode(FileCoverage.self, from: jsonData) else {
            writeToStdError("Failed to convert to JSON")
            throw JSONParseError.convertError(code: 0, message: "Failed to convert to JSON Object")
        }

        let fileInfoSemaphore = DispatchSemaphore(value: 1)
        var fileInfo: [FileInfo] = []
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = ProcessInfo.processInfo.processorCount //Deadlock if this is = 1
        queue.qualityOfService = .userInitiated
        for (fileName, value) in coverageJson.files {
            let op = BlockOperation {
                var fileLines = [LineInfo]() // This will store information about each line.

                for lineData in value {
                    let lineNum = lineData.line
                    guard var covered = lineData.executionCount else {
                        continue
                    }
                    // If the line coverage count is a MAX_INT, just set it to 1
                    if covered == Int.max {
                        covered = 1
                    }
                    let line = LineInfo(lineNumber: String(lineNum), coverage: covered)
                    fileLines.append(line)
                }

                let fileInfoInst = FileInfo(path: self.relativePath(for: fileName, relativeTo: self.projectRoot), lines: fileLines)
                fileInfoSemaphore.wait()
                fileInfo.append(fileInfoInst)
                fileInfoSemaphore.signal()
            }
            queue.addOperation(op)
        }
        // This will block until all our operation have compleated (or been canceled)
        queue.waitUntilAllOperationsAreFinished()
        // Sort files to avoid duplicated packages
        fileInfo.sort { $0.path > $1.path }
        
        var currentPackage = ""
        var currentPackageElement: XMLElement!
        var isNewPackage = false

        var currentClassesElement = XMLElement()
        
        fileInfo.forEach { file in
            let pathComponents = file.path.split(separator: "/")
            let packageName = pathComponents[0..<pathComponents.count - 1].joined(separator: ".")

            isNewPackage = currentPackage != packageName

            if isNewPackage {
                currentPackageElement = XMLElement(name: "package")
                currentClassesElement = XMLElement()
                packagesElement.addChild(currentPackageElement)
            }

            currentPackage = packageName
            if isNewPackage {
                currentPackageElement.addAttribute(XMLNode.nodeAttribute(withName: "name", stringValue: packageName))
                currentPackageElement.addAttribute(XMLNode.nodeAttribute(withName: "line-rate", stringValue: "1.0"))
                currentPackageElement.addAttribute(XMLNode.nodeAttribute(withName: "branch-rate", stringValue: "1.0"))
                currentPackageElement.addAttribute(XMLNode.nodeAttribute(withName: "complexity", stringValue: "0.0"))
                currentClassesElement = XMLElement(name: "classes")
                currentPackageElement.addChild(currentClassesElement)
            }

            let classElement = XMLElement(name: "class")
            classElement.addAttribute(XMLNode.nodeAttribute(withName: "name",
                                                            stringValue: "\(packageName).\((file.path as NSString).deletingPathExtension)"))
            classElement.addAttribute(XMLNode.nodeAttribute(withName: "filename", stringValue: "\(file.path)"))
            
            let fileLineCoverage = Float(file.lines.filter { $0.coverage > 0 }.count) / Float(file.lines.count)
            classElement.addAttribute(XMLNode.nodeAttribute(withName: "line-rate", stringValue: "\(fileLineCoverage)"))
            classElement.addAttribute(XMLNode.nodeAttribute(withName: "branch-rate", stringValue: "1.0"))
            classElement.addAttribute(XMLNode.nodeAttribute(withName: "complexity", stringValue: "0.0"))
            currentClassesElement.addChild(classElement)

            let linesElement = XMLElement(name: "lines")
            classElement.addChild(linesElement)

            for line in file.lines {
                let lineElement = XMLElement(kind: .element, options: .nodeCompactEmptyElement)
                lineElement.name = "line"
                lineElement.addAttribute(XMLNode.nodeAttribute(withName: "number", stringValue: "\(line.lineNumber)"))
                lineElement.addAttribute(XMLNode.nodeAttribute(withName: "branch", stringValue: "false"))

                lineElement.addAttribute(XMLNode.nodeAttribute(withName: "hits", stringValue: "\(line.coverage)"))
                linesElement.addChild(lineElement)
            }
        }

        return doc.xmlString(options: [.nodePrettyPrint, .nodeCompactEmptyElement])
    }

    private func readDTD() -> XMLDTD {
        if let dtdUrl = URL(string: "http://cobertura.sourceforge.net/xml/coverage-04.dtd"),
           let dtd = try? XMLDTD(contentsOf: dtdUrl) {
            return dtd
        }
        if let dtdUrl = Bundle.module.url(forResource: "coverage-04", withExtension: "dtd"),
           let dtd = try? XMLDTD(contentsOf: dtdUrl) {
            return dtd
        }
        fatalError("DTD could not be constructed")
    }
    
    private func fileCoverage(for file: String, relativeTo projectRoot: String) throws -> FileInfo {
        let coverageData = try coverageForFile(path: file)
        var file = FileInfo(path: relativePath(for: file, relativeTo: projectRoot), lines: [])
        let nsrange = NSRange(coverageData.startIndex..<coverageData.endIndex,
                              in: coverageData)
        coverageRegexp!.enumerateMatches(in: coverageData, options: [], range: nsrange) { match, flags, stop in
            guard let match = match else { return }
            
            let lineNumber = coverageData.text(in: match.range(at: 1))
            let coverage = coverageData.text(in: match.range(at: 2))
            
            let line = LineInfo(lineNumber: lineNumber, coverage: Int(coverage) ?? 0)
            file.lines.append(line)
        }
        return file
    }
    
    func makeRootElement() -> XMLElement {
        // TODO some of these values are B.S. - figure out how to calculate, or better to omit if we don't know?
        let testAction = invocationRecord.actions.first { $0.schemeCommandName == "Test" }
        let timeStamp = (testAction?.startedTime.timeIntervalSince1970) ?? Date().timeIntervalSince1970
        let rootElement = XMLElement(name: "coverage")
        rootElement.addAttribute(XMLNode.nodeAttribute(withName: "line-rate", stringValue: "\(codeCoverage.lineCoverage)"))
        rootElement.addAttribute(XMLNode.nodeAttribute(withName: "branch-rate", stringValue: "1.0"))
        rootElement.addAttribute(XMLNode.nodeAttribute(withName: "lines-covered", stringValue: "\(codeCoverage.coveredLines)"))
        rootElement.addAttribute(XMLNode.nodeAttribute(withName: "lines-valid", stringValue: "\(codeCoverage.executableLines)"))
        rootElement.addAttribute(XMLNode.nodeAttribute(withName: "timestamp", stringValue: "\(timeStamp)"))
        rootElement.addAttribute(XMLNode.nodeAttribute(withName: "version", stringValue: "diff_coverage 0.1"))
        rootElement.addAttribute(XMLNode.nodeAttribute(withName: "complexity", stringValue: "0.0"))
        rootElement.addAttribute(XMLNode.nodeAttribute(withName: "branches-valid", stringValue: "1.0"))
        rootElement.addAttribute(XMLNode.nodeAttribute(withName: "branches-covered", stringValue: "1.0"))

        return rootElement
    }
}

struct LineInfo {
    let lineNumber: String
    let coverage: Int
}

struct FileInfo {
    let path: String
    var lines: [LineInfo]
}

extension XMLNode {
    static func nodeAttribute(withName name: String, stringValue value: String) -> XMLNode {
        guard let attribute = XMLNode.attribute(withName: name, stringValue: value) as? XMLNode else {
            return XMLNode()
        }

        return attribute
    }
}
