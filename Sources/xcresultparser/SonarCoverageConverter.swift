//
//  SonarCoverageConverter.swift
//  xcresult2text
//
//  Created by Alex da Franca on 11.06.21.
//

import Foundation
import XCResultKit

public class SonarCoverageConverter: CoverageConverter, XmlSerializable {

    public var xmlString: String {
        return try! xmlString(quiet: true)
    }

    public override func xmlString(quiet: Bool) throws -> String {
        let coverageXML = XMLElement(name: "coverage")
        coverageXML.addAttribute(name: "version", stringValue: "1")
        let coverageXMLSemaphore = DispatchSemaphore(value: 1)
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
            let op = BlockOperation { [self] in
                do {
                    let coverage = try fileCoverageXML(for: file, relativeTo: projectRoot)
                    coverageXMLSemaphore.wait()
                    coverageXML.addChild(coverage)
                    coverageXMLSemaphore.signal()
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
    
    private func fileCoverageXML(for file: String, relativeTo projectRoot: String) throws -> XMLElement {
        let coverageData = try coverageForFile(path: file)
        let fileElement = XMLElement(name: "file")
        fileElement.addAttribute(name: "path", stringValue: relativePath(for: file, relativeTo: projectRoot))
        let nsrange = NSRange(coverageData.startIndex..<coverageData.endIndex,
                              in: coverageData)
        coverageRegexp!.enumerateMatches(in: coverageData, options: [], range: nsrange) { match, flags, stop in
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
}
