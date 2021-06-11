//
//  CoverageConverter.swift
//  xcresult2text
//
//  Created by Alex da Franca on 11.06.21.
//

import Foundation
import XCResultKit

/// we need to convert the format which xccov retrieves from xcresult to the
/// format required for sonarqube in xml format
/// Both formats are pretty different. Only an approximation can be made
/// as the xcresult format doesn't break it down to single lines
/// instead it lists functions with only their number of executable lines
/// and the number of covered lines, so that it is not clear, which line exactly
/// is covered. We know the linenumber of the function start and can "count" from there onwards
/// Additionally the listing of functions is linear, while in fact its format is nested:
/// Closures in a function have their startin linenumber within the range of the
/// enclosing function.
///
/// The sonarqube format however just wants a list of line numbers and a boolean value
/// whether the line was covered once or not.
/// (while xcresult carries info about how often the function was covered)
///
/// So this is just a naive approach of listing line numbers with the
/// right proportion of covered and uncovered lines.
/// While it looks like the format into which we convert knows, which line exactly
/// is covered and which not, in reality it is an assumption based on the informatioin we have in "runs" of covered/uncovered lines.

struct CoverageConverter {
    private let resultFile: XCResultFile
    private let projectRoot: String
    private let codeCoverage: CodeCoverage
    
    init?(with url: URL,
          projectRoot: String = "") {
        resultFile = XCResultFile(url: url)
        guard let record = resultFile.getCodeCoverage() else {
            return nil
        }
        self.projectRoot = projectRoot
        codeCoverage = record
    }
    
    var xmlString: String {
        let coverageXML = XMLElement(name: "coverage")
        coverageXML.addAttribute(name: "version", stringValue: "1")
        for target in codeCoverage.targets {
            for file in target.files {
                coverageXML.addChild(file.coverageXML(relativeTo: projectRoot))
            }
        }
        return coverageXML.xmlString(options: [.nodePrettyPrint, .nodeCompactEmptyElement])
    }
}

private extension CodeCoverageFile {
    func coverageXML(relativeTo projectRoot: String) -> XMLElement {
        let xmlFile = XMLElement(name: "file")
        xmlFile.addAttribute(name: "path", stringValue: path(relativeTo: projectRoot))
        
        // use a temporary list to stack the covered lines together:
        var lines = [Int]()
        for function in functions {
            let advance = function.lineNumber - lines.count - 1
            if advance > 0 {
                lines += Array(repeating: 0, count: advance)
            }
            lines.insert(contentsOf: function.linearResult, at: function.lineNumber - 1)
        }
        // ...now use the above helper list to create the (inaccurate) lines list
        for (index, line) in lines.enumerated() {
            guard line > 0 else { continue }
            let lineXML = XMLElement(name: "lineToCover")
            lineXML.addAttribute(name: "lineNumber", stringValue: "\(index)")
            let covered = line == 2 ? "true": "false"
            lineXML.addAttribute(name: "covered", stringValue: covered)
            xmlFile.addChild(lineXML)
        }
        return xmlFile
    }
    private func path(relativeTo projectRoot: String) -> String {
        return projectRoot.isEmpty ? path:
            path.components(separatedBy: "/\(projectRoot)/").last ?? path
    }
}

private extension CodeCoverageFileFunction {
    var linearResult: [Int] {
        return Array(repeating: 2, count: coveredLines) +
            Array(repeating: 1, count: executableLines - coveredLines)
    }
}
