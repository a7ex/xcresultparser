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

public class CoberturaCoverageConverter: CoverageConverter, XmlSerializable {

    public var xmlString: String {
        return try! xmlString(quiet: true)
    }

    public override func xmlString(quiet: Bool) throws -> String {
        guard
            let dtdUrl = URL(string: "http://cobertura.sourceforge.net/xml/coverage-04.dtd"),
            let dtd = try? XMLDTD(contentsOf: dtdUrl) else {
                fatalError("DTD could not be constructed")
        }

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

        let fileInfoSemaphore = DispatchSemaphore(value: 1)
        let files = try coverageFileList()
        var fileInfo: [FileInfo] = []
        
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
            let op = BlockOperation { [self] in
                do {
                    let coverage = try fileCoverage(for: file, relativeTo: projectRoot)
                    fileInfoSemaphore.wait()
                    fileInfo.append(coverage)
                    fileInfoSemaphore.signal()
                } catch {
                    writeToStdErrorLn(error.localizedDescription)
                }
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
        let timeStamp = testAction?.startedTime.timeIntervalSince1970
        let rootElement = XMLElement(name: "coverage")
        rootElement.addAttribute(XMLNode.nodeAttribute(withName: "line-rate", stringValue: "\(codeCoverage.lineCoverage)"))
        rootElement.addAttribute(XMLNode.nodeAttribute(withName: "branch-rate", stringValue: "1.0"))
        rootElement.addAttribute(XMLNode.nodeAttribute(withName: "lines-covered", stringValue: "\(codeCoverage.coveredLines)"))
        rootElement.addAttribute(XMLNode.nodeAttribute(withName: "lines-valid", stringValue: "\(codeCoverage.executableLines)"))
        rootElement.addAttribute(XMLNode.nodeAttribute(withName: "timestamp", stringValue: "\(timeStamp ?? Date().timeIntervalSince1970)"))
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
