//
//  OutputFormat.swift
//  xcresult2text
//
//  Created by Alex da Franca on 03.06.21.
//

import Foundation

public enum OutputFormat: String {
    case txt, cli, html, xml, junit, cobertura, md, github, warnings, errors
    case warningsAndErrors = "warnings-and-errors"

    public init(string: String?) {
        self = if let input = string?.lowercased(),
                  let fmt = OutputFormat(rawValue: input) {
            fmt
        } else {
            .cli
        }
    }
}

protocol XmlSerializable {
    var xmlString: String { get }
}
