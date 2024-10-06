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

enum JSONParseError: Error {
    case convertError(code: Int, message: String)
}

public class CoberturaCoverageConverter: CoverageConverter, XmlSerializable {
    public var xmlString: String {
        do {
            return try xmlString(quiet: true)
        } catch {
            return "Error creating coverage xml: \(error.localizedDescription)"
        }
    }

    override public func xmlString(quiet: Bool) throws -> String {
        let dtd = readDTD()
        dtd.name = "coverage"
        // dtd.systemID = "http://cobertura.sourceforge.net/xml/coverage-04.dtd"
        dtd.systemID =
        "https://github.com/cobertura/cobertura/blob/master/cobertura/src/site/htdocs/xml/coverage-04.dtd"

        let rootElement = makeRootElement()

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
        let coverageJson = try getCoverageDataAsJSON()

        var fileInfo: [FileInfo] = []
        for (fileName, value) in coverageJson.files {
            guard !isPathExcluded(fileName) else {
                continue
            }
            var fileLines = [LineInfo]() // This will store information about each line.

            for lineData in value {
                let lineNum = lineData.line
                guard let covered = lineData.executionCount else {
                    continue
                }
                let line = LineInfo(lineNumber: String(lineNum), coverage: covered)
                fileLines.append(line)
            }

            let fileInfoInst = FileInfo(path: fileName.relativePath(relativeTo: projectRoot), lines: fileLines)
            fileInfo.append(fileInfoInst)
        }
        // Sort files to avoid duplicated packages
        fileInfo.sort { $0.path > $1.path }

        var currentPackage = ""
        var currentPackageElement: XMLElement!
        var isNewPackage = false

        var currentClassesElement = XMLElement()

        for file in fileInfo {
            let pathComponents = file.path.split(separator: "/")
            let packageName = pathComponents[0 ..< pathComponents.count - 1].joined(separator: ".")

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
            classElement.addAttribute(XMLNode.nodeAttribute(
                withName: "name",
                stringValue: "\(packageName).\((file.path as NSString).deletingPathExtension)"
            ))
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
        do {
            return try XMLDTD(data: Data(dtd04.utf8))
        } catch {
            fatalError("DTD could not be constructed. Error: \(error.localizedDescription)")
        }
    }

    private func makeRootElement() -> XMLElement {
        // TODO: some of these values are B.S. - figure out how to calculate, or better to omit if we don't know?
        let testAction = invocationRecord.actions.first { $0.schemeCommandName == "Test" }
        let timeStamp = (testAction?.startedTime.timeIntervalSince1970) ?? Date().timeIntervalSince1970
        let rootElement = XMLElement(name: "coverage")
        rootElement.addAttribute(
            XMLNode.nodeAttribute(withName: "line-rate", stringValue: "\(codeCoverage.lineCoverage)")
        )
        rootElement.addAttribute(XMLNode.nodeAttribute(withName: "branch-rate", stringValue: "1.0"))
        rootElement.addAttribute(
            XMLNode.nodeAttribute(withName: "lines-covered", stringValue: "\(codeCoverage.coveredLines)")
        )
        rootElement.addAttribute(
            XMLNode.nodeAttribute(withName: "lines-valid", stringValue: "\(codeCoverage.executableLines)")
        )
        rootElement.addAttribute(XMLNode.nodeAttribute(withName: "timestamp", stringValue: "\(timeStamp)"))
        rootElement.addAttribute(XMLNode.nodeAttribute(withName: "version", stringValue: "diff_coverage 0.1"))
        rootElement.addAttribute(XMLNode.nodeAttribute(withName: "complexity", stringValue: "0.0"))
        rootElement.addAttribute(XMLNode.nodeAttribute(withName: "branches-valid", stringValue: "1.0"))
        rootElement.addAttribute(XMLNode.nodeAttribute(withName: "branches-covered", stringValue: "1.0"))

        return rootElement
    }
    
    // this ised to be fetched online from http://cobertura.sourceforge.net/xml/coverage-04.dtd
    // that broke, when the URL changed to:
    // https://github.com/cobertura/cobertura/blob/master/cobertura/src/site/htdocs/xml/coverage-04.dtd
    // In case we couldn't download the data, we had a file as fallback. However that file could never be read
    // because as command line tool this is not a bundle and thus there is no file to be found in the bundle
    // IMO all that was overengineered for the followong 60 lines string...
    // ...which will probably never ever change!
    private var dtd04 = """
<!-- Portions (C) International Organization for Standardization 1986:
     Permission to copy in any form is granted for use with
     conforming SGML systems and applications as defined in
     ISO 8879, provided this notice is included in all copies.
-->

  <!ELEMENT coverage (sources?,packages)>
  <!ATTLIST coverage line-rate        CDATA #REQUIRED>
  <!ATTLIST coverage branch-rate      CDATA #REQUIRED>
  <!ATTLIST coverage lines-covered    CDATA #REQUIRED>
  <!ATTLIST coverage lines-valid      CDATA #REQUIRED>
  <!ATTLIST coverage branches-covered CDATA #REQUIRED>
  <!ATTLIST coverage branches-valid   CDATA #REQUIRED>
  <!ATTLIST coverage complexity       CDATA #REQUIRED>
  <!ATTLIST coverage version          CDATA #REQUIRED>
  <!ATTLIST coverage timestamp        CDATA #REQUIRED>

  <!ELEMENT sources (source*)>

  <!ELEMENT source (#PCDATA)>

  <!ELEMENT packages (package*)>

  <!ELEMENT package (classes)>
  <!ATTLIST package name        CDATA #REQUIRED>
  <!ATTLIST package line-rate   CDATA #REQUIRED>
  <!ATTLIST package branch-rate CDATA #REQUIRED>
  <!ATTLIST package complexity  CDATA #REQUIRED>

  <!ELEMENT classes (class*)>

  <!ELEMENT class (methods,lines)>
  <!ATTLIST class name        CDATA #REQUIRED>
  <!ATTLIST class filename    CDATA #REQUIRED>
  <!ATTLIST class line-rate   CDATA #REQUIRED>
  <!ATTLIST class branch-rate CDATA #REQUIRED>
  <!ATTLIST class complexity  CDATA #REQUIRED>

  <!ELEMENT methods (method*)>

  <!ELEMENT method (lines)>
  <!ATTLIST method name        CDATA #REQUIRED>
  <!ATTLIST method signature   CDATA #REQUIRED>
  <!ATTLIST method line-rate   CDATA #REQUIRED>
  <!ATTLIST method branch-rate CDATA #REQUIRED>
  <!ATTLIST method complexity  CDATA #REQUIRED>

  <!ELEMENT lines (line*)>

  <!ELEMENT line (conditions*)>
  <!ATTLIST line number CDATA #REQUIRED>
  <!ATTLIST line hits   CDATA #REQUIRED>
  <!ATTLIST line branch CDATA "false">
  <!ATTLIST line condition-coverage CDATA "100%">

  <!ELEMENT conditions (condition*)>

  <!ELEMENT condition EMPTY>
  <!ATTLIST condition number CDATA #REQUIRED>
  <!ATTLIST condition type CDATA #REQUIRED>
  <!ATTLIST condition coverage CDATA #REQUIRED>
"""
}

private struct LineInfo {
    let lineNumber: String
    let coverage: UInt64
}

private struct FileInfo {
    let path: String
    var lines: [LineInfo]
}

private extension XMLNode {
    static func nodeAttribute(withName name: String, stringValue value: String) -> XMLNode {
        guard let attribute = XMLNode.attribute(withName: name, stringValue: value) as? XMLNode else {
            return XMLNode()
        }

        return attribute
    }
}
