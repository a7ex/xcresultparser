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
        do {
            return try xmlString(quiet: true)
        } catch {
            return "Error creating coverage xml: \(error.localizedDescription)"
        }
    }

    override public func xmlString(quiet: Bool) throws -> String {
        let coverageXML = XMLElement(name: "coverage")
        coverageXML.addAttribute(name: "version", stringValue: "1")

        // Get the xccov results as a JSON.
        let coverageJson = try getCoverageDataAsJSON()
        for (file, lineData) in coverageJson.files {
            let coverage = try fileCoverageXML(for: file, coverageData: lineData, relativeTo: projectRoot)
            coverageXML.addChild(coverage)
        }

        return coverageXML.xmlString(options: [.nodePrettyPrint, .nodeCompactEmptyElement])
    }

    private func fileCoverageXML(
        for file: String,
        coverageData: [LineDetail],
        relativeTo projectRoot: String
    ) throws -> XMLElement {
        let fileElement = XMLElement(name: "file")
        fileElement.addAttribute(name: "path", stringValue: file.relativePath(relativeTo: projectRoot))
        for lineData in coverageData where lineData.isExecutable {
            let line = XMLElement(name: "lineToCover")
            line.addAttribute(name: "lineNumber", stringValue: String(lineData.line))
            let executionCount = lineData.executionCount ?? 0
            line.addAttribute(name: "covered", stringValue: executionCount == 0 ? "false" : "true")
            fileElement.addChild(line)
        }
        return fileElement
    }
}
